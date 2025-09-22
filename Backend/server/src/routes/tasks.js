// routes/tasks.js
const express = require('express');
const router = express.Router();
const Task = require('../models/Task');

// Create a new task
router.post('/', async (req, res) => {
  try {
    const task = new Task(req.body);
    await task.save();
    res.status(201).json(task);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Get tasks for a specific ground worker
router.get('/worker/:workerId', async (req, res) => {
  try {
    const tasks = await Task.find({ assignedTo: req.params.workerId });
    res.json(tasks);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get tasks by taluka (returns all tasks for that taluka)
router.get('/taluka/:taluka', async (req, res) => {
  try {
    const tasks = await Task.find({ taluka: req.params.taluka })
      .sort({ createdAt: -1 }); // Sort by newest first
    res.json(tasks);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get task statistics by taluka
router.get('/stats/:taluka', async (req, res) => {
  try {
    const taluka = req.params.taluka;
    
    // Get all tasks for the taluka
    const allTasks = await Task.find({ taluka });
    
    // Calculate statistics
    const stats = {
      total: allTasks.length,
      pending: allTasks.filter(task => task.status === 'Pending').length,
      inProgress: allTasks.filter(task => task.status === 'In Progress').length,
      completed: allTasks.filter(task => task.status === 'Completed').length,
      highPriority: allTasks.filter(task => task.priority === 'High').length,
      mediumPriority: allTasks.filter(task => task.priority === 'Medium').length,
      lowPriority: allTasks.filter(task => task.priority === 'Low').length,
      overdue: allTasks.filter(task => 
        new Date(task.dueDate) < new Date() && task.status !== 'Completed'
      ).length
    };
    
    res.json(stats);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get recent tasks by taluka (last 10 tasks)
router.get('/recent/:taluka', async (req, res) => {
  try {
    const tasks = await Task.find({ taluka: req.params.taluka })
      .sort({ createdAt: -1 })
      .limit(10);
    res.json(tasks);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Update a task
router.put('/:id', async (req, res) => {
  try {
    const task = await Task.findByIdAndUpdate(
      req.params.id,
      { ...req.body, updatedAt: Date.now() },
      { new: true }
    );
    
    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }
    
    res.json(task);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Delete a task
router.delete('/:id', async (req, res) => {
  try {
    const task = await Task.findByIdAndDelete(req.params.id);
    
    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }
    
    res.json({ message: 'Task deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get a single task by ID
router.get('/:id', async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);
    
    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }
    
    res.json(task);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Update task status only
router.patch('/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    
    if (!['Pending', 'In Progress', 'Completed'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }
    
    const task = await Task.findByIdAndUpdate(
      req.params.id,
      { status, updatedAt: Date.now() },
      { new: true }
    );
    
    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }
    
    res.json(task);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Bulk update tasks
router.put('/bulk/:taluka', async (req, res) => {
  try {
    const { taskIds, updates } = req.body;
    
    if (!taskIds || !Array.isArray(taskIds) || taskIds.length === 0) {
      return res.status(400).json({ message: 'Task IDs array is required' });
    }
    
    const result = await Task.updateMany(
      { 
        _id: { $in: taskIds },
        taluka: req.params.taluka 
      },
      { ...updates, updatedAt: Date.now() }
    );
    
    res.json({ 
      message: 'Tasks updated successfully', 
      modifiedCount: result.modifiedCount 
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Get overdue tasks by taluka
router.get('/overdue/:taluka', async (req, res) => {
  try {
    const tasks = await Task.find({ 
      taluka: req.params.taluka,
      dueDate: { $lt: new Date() },
      status: { $ne: 'Completed' }
    }).sort({ dueDate: 1 });
    
    res.json(tasks);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Search tasks by title or description
router.get('/search/:taluka', async (req, res) => {
  try {
    const { q } = req.query; // search query
    
    if (!q) {
      return res.status(400).json({ message: 'Search query is required' });
    }
    
    const tasks = await Task.find({
      taluka: req.params.taluka,
      $or: [
        { title: { $regex: q, $options: 'i' } },
        { description: { $regex: q, $options: 'i' } },
        { assignedToName: { $regex: q, $options: 'i' } }
      ]
    }).sort({ createdAt: -1 });
    
    res.json(tasks);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get tasks by priority
router.get('/priority/:taluka/:priority', async (req, res) => {
  try {
    const { priority } = req.params;
    
    if (!['Low', 'Medium', 'High'].includes(priority)) {
      return res.status(400).json({ message: 'Invalid priority' });
    }
    
    const tasks = await Task.find({ 
      taluka: req.params.taluka,
      priority: priority 
    }).sort({ createdAt: -1 });
    
    res.json(tasks);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get tasks by status
router.get('/status/:taluka/:status', async (req, res) => {
  try {
    const { status } = req.params;
    
    if (!['Pending', 'In Progress', 'Completed'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }
    
    const tasks = await Task.find({ 
      taluka: req.params.taluka,
      status: status 
    }).sort({ createdAt: -1 });
    
    res.json(tasks);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;