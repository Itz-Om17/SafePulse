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

// Get tasks by taluka
router.get('/taluka/:taluka', async (req, res) => {
  try {
    const tasks = await Task.find({ taluka: req.params.taluka })
      .populate('assignedTo', 'name phone');
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
    res.json(task);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

module.exports = router;