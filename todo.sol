// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TodoList {
    enum Priority {
        Low,
        Medium,
        High
    }

    struct Task {
        uint256 id;
        string description;
        bool completed;
        Priority priority;
        address owner;
        uint256 dueDate;
    }

    mapping(uint256 => Task) private tasks;
    mapping(address => uint256[]) private userTaskIds;
    mapping(uint256 => uint256) private taskIndexInUserArray;
    uint256 private nextTaskId = 0;

    event TaskAdded(address indexed user, uint256 indexed taskId, string description, Priority priority, uint256 dueDate);
    event TaskCompleted(address indexed user, uint256 indexed taskId);
    event TaskDescriptionEdited(address indexed user, uint256 indexed taskId, string newDescription);
    event TaskPriorityEdited(address indexed user, uint256 indexed taskId, Priority newPriority);
    event TaskDueDateEdited(address indexed user, uint256 indexed taskId, uint256 newDueDate);
    event TaskRemoved(address indexed user, uint256 indexed taskId);

    modifier onlyTaskOwner(uint256 _taskId) {
        require(tasks[_taskId].owner == msg.sender, "TodoList: Caller is not the owner of this task");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].owner != address(0), "TodoList: Task does not exist");
        _;
    }

    function addTask(string calldata _description, Priority _priority, uint256 _dueDate) external {
        require(bytes(_description).length > 0, "TodoList: Description cannot be empty");

        uint256 taskId = nextTaskId;
        address owner = msg.sender;

        tasks[taskId] = Task({
            id: taskId,
            description: _description,
            completed: false,
            priority: _priority,
            owner: owner,
            dueDate: _dueDate
        });

        userTaskIds[owner].push(taskId);
        taskIndexInUserArray[taskId] = userTaskIds[owner].length - 1;

        unchecked { nextTaskId++; }

        emit TaskAdded(owner, taskId, _description, _priority, _dueDate);
    }

   function addTask(string calldata _description, Priority _priority) external {
    // Copy logic from the original addTask function
    require(bytes(_description).length > 0, "TodoList: Description cannot be empty");

    uint256 taskId = nextTaskId;
    address owner = msg.sender;

    tasks[taskId] = Task({
        id: taskId,
        description: _description,
        completed: false,
        priority: _priority,
        owner: owner,
        dueDate: 0
    });

    userTaskIds[owner].push(taskId);
    taskIndexInUserArray[taskId] = userTaskIds[owner].length - 1;
    nextTaskId++;

    emit TaskAdded(owner, taskId, _description, _priority, 0);


    }

    function markTaskCompleted(uint256 _taskId) external taskExists(_taskId) onlyTaskOwner(_taskId) {
        Task storage task = tasks[_taskId];
        require(!task.completed, "TodoList: Task is already marked as completed");

        task.completed = true;
        emit TaskCompleted(msg.sender, _taskId);
    }

    function editTaskDescription(uint256 _taskId, string calldata _newDescription)
        external
        taskExists(_taskId)
        onlyTaskOwner(_taskId)
    {
        require(bytes(_newDescription).length > 0, "TodoList: New description cannot be empty");
        tasks[_taskId].description = _newDescription;
        emit TaskDescriptionEdited(msg.sender, _taskId, _newDescription);
    }

    function editTaskPriority(uint256 _taskId, Priority _newPriority)
        external
        taskExists(_taskId)
        onlyTaskOwner(_taskId)
    {
        tasks[_taskId].priority = _newPriority;
        emit TaskPriorityEdited(msg.sender, _taskId, _newPriority);
    }

    function editTaskDueDate(uint256 _taskId, uint256 _newDueDate)
        external
        taskExists(_taskId)
        onlyTaskOwner(_taskId)
    {
        tasks[_taskId].dueDate = _newDueDate;
        emit TaskDueDateEdited(msg.sender, _taskId, _newDueDate);
    }

    function removeTask(uint256 _taskId) external taskExists(_taskId) onlyTaskOwner(_taskId) {
        address owner = msg.sender;
        uint256 indexToRemove = taskIndexInUserArray[_taskId];
        uint256[] storage taskIds = userTaskIds[owner];
        uint256 lastTaskId = taskIds[taskIds.length - 1];

        if (indexToRemove < taskIds.length - 1) {
            taskIds[indexToRemove] = lastTaskId;
            taskIndexInUserArray[lastTaskId] = indexToRemove;
        }

        taskIds.pop();
        delete tasks[_taskId];
        delete taskIndexInUserArray[_taskId];

        emit TaskRemoved(owner, _taskId);
    }

    function getMyTasks() external view returns (Task[] memory) {
        address owner = msg.sender;
        uint256[] memory ids = userTaskIds[owner];
        uint256 taskCount = ids.length;
        Task[] memory userSpecificTasks = new Task[](taskCount);

        for (uint256 i = 0; i < taskCount; i++) {
            userSpecificTasks[i] = tasks[ids[i]];
        }

        return userSpecificTasks;
    }

    function getTaskById(uint256 _taskId) external view taskExists(_taskId) onlyTaskOwner(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    function getMyTaskCount() external view returns (uint256) {
        return userTaskIds[msg.sender].length;
    }

    function getMyCompletedTasks() external view returns (Task[] memory) {
        address owner = msg.sender;
        uint256[] memory ids = userTaskIds[owner];
        uint256 count = 0;

        for (uint256 i = 0; i < ids.length; i++) {
            if (tasks[ids[i]].completed) count++;
        }

        Task[] memory completed = new Task[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < ids.length; i++) {
            if (tasks[ids[i]].completed) {
                completed[index] = tasks[ids[i]];
                index++;
            }
        }

        return completed;
    }

    function getMyPendingTasks() external view returns (Task[] memory) {
        address owner = msg.sender;
        uint256[] memory ids = userTaskIds[owner];
        uint256 count = 0;

        for (uint256 i = 0; i < ids.length; i++) {
            if (!tasks[ids[i]].completed) count++;
        }

        Task[] memory pending = new Task[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < ids.length; i++) {
            if (!tasks[ids[i]].completed) {
                pending[index] = tasks[ids[i]];
                index++;
            }
        }

        return pending;
    }
}
