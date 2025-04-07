// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TodoListContract {


    enum Priority {
        Low,    // 0
        Medium, // 1
        High    // 2
    }



    struct Task {
        uint id;
        address owner;
        string description;
        bool isCompleted;
        Priority priority;
        uint createdAt;
        uint updatedAt;
    }


    uint private nextTaskId = 1;

   
    mapping(uint => Task) private tasks;

  
    mapping(address => uint[]) private userTaskIds;


    modifier onlyOwnerOfTask(uint _taskId) {
        require(tasks[_taskId].owner != address(0), "Task does not exist.");
        require(tasks[_taskId].owner == msg.sender, "Caller is not the owner of the task.");
        _;
    }



    event TaskAdded(address indexed user, uint indexed taskId, string description, Priority priority);

    event TaskStatusChanged(address indexed user, uint indexed taskId, bool isCompleted);

    event TaskRemoved(address indexed user, uint indexed taskId);


    event TaskDescriptionEdited(address indexed user, uint indexed taskId, string newDescription);


    event TaskPriorityChanged(address indexed user, uint indexed taskId, Priority newPriority);



    function addTask(string memory _description, Priority _priority) public {
        require(bytes(_description).length > 0, "Task description cannot be empty.");

        uint taskId = nextTaskId++;
        uint timestamp = block.timestamp;

        tasks[taskId] = Task({
            id: taskId,
            owner: msg.sender,
            description: _description,
            isCompleted: false, 
            priority: _priority,
            createdAt: timestamp,
            updatedAt: timestamp 
        });

        userTaskIds[msg.sender].push(taskId);

        emit TaskAdded(msg.sender, taskId, _description, _priority);
    }

   
    function markTaskCompleted(uint _taskId) public onlyOwnerOfTask(_taskId) {
        Task storage taskToUpdate = tasks[_taskId];
        require(!taskToUpdate.isCompleted, "Task is already marked as completed.");

        taskToUpdate.isCompleted = true;
        taskToUpdate.updatedAt = block.timestamp;

        emit TaskStatusChanged(msg.sender, _taskId, true);
    }

 
    function markTaskPending(uint _taskId) public onlyOwnerOfTask(_taskId) {
        Task storage taskToUpdate = tasks[_taskId];
        require(taskToUpdate.isCompleted, "Task is already marked as pending.");

        taskToUpdate.isCompleted = false;
        taskToUpdate.updatedAt = block.timestamp;

        emit TaskStatusChanged(msg.sender, _taskId, false);
    }


    function removeTask(uint _taskId) public onlyOwnerOfTask(_taskId) {
        uint[] storage taskIds = userTaskIds[msg.sender];
        uint indexToRemove = type(uint).max;

        for (uint i = 0; i < taskIds.length; i++) {
            if (taskIds[i] == _taskId) {
                indexToRemove = i;
                break;
            }
        }

        require(indexToRemove != type(uint).max, "Task ID not found in user's list for removal.");

        if (taskIds.length > 1 && indexToRemove != taskIds.length - 1) {
             taskIds[indexToRemove] = taskIds[taskIds.length - 1];
        }
        taskIds.pop();

        delete tasks[_taskId];

        emit TaskRemoved(msg.sender, _taskId);
    }

  
    function editTaskDescription(uint _taskId, string memory _newDescription) public onlyOwnerOfTask(_taskId) {
        require(bytes(_newDescription).length > 0, "New description cannot be empty.");

        Task storage taskToUpdate = tasks[_taskId];
        taskToUpdate.description = _newDescription;
        taskToUpdate.updatedAt = block.timestamp;

        emit TaskDescriptionEdited(msg.sender, _taskId, _newDescription);
    }

    function changeTaskPriority(uint _taskId, Priority _newPriority) public onlyOwnerOfTask(_taskId) {
        Task storage taskToUpdate = tasks[_taskId];

        taskToUpdate.priority = _newPriority;
        taskToUpdate.updatedAt = block.timestamp;
        emit TaskPriorityChanged(msg.sender, _taskId, _newPriority);
        
    }


    function getTask(uint _taskId) public view returns (Task memory) {
        return tasks[_taskId];
    }

    function getMyTasks() public view returns (Task[] memory) {
        uint[] storage taskIds = userTaskIds[msg.sender];
        uint taskCount = taskIds.length;
        Task[] memory myTasks = new Task[](taskCount);

        for (uint i = 0; i < taskCount; i++) {
            myTasks[i] = tasks[taskIds[i]];
        }

        return myTasks;
    }


    function getMyTaskIds() public view returns (uint[] memory) {
         uint[] storage storedIds = userTaskIds[msg.sender];
         uint[] memory memoryIds = new uint[](storedIds.length);
         for(uint i = 0; i < storedIds.length; i++) {
             memoryIds[i] = storedIds[i];
         }
         return memoryIds;
    }


    function getMyTaskCount() public view returns (uint) {
        return userTaskIds[msg.sender].length;
    }
}
