const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  assignedTo: {
    type: mongoose.Schema.Types.Mixed,
    ref: 'GroundWorker',
    required: true
  },
  assignedToName: {
    type: String,
    required: true
  },
  assignedBy: {
    type: String,
    required: true // Could be Taluka Head name or ID
  },
  dueDate: {
    type: Date,
    required: true
  },
  status: {
    type: String,
    enum: ['Pending', 'In Progress', 'Completed'],
    default: 'Pending'
  },
  priority: {
    type: String,
    enum: ['Low', 'Medium', 'High'],
    default: 'Medium'
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  },
  taluka: {
    type: String,
    required: true
  }
});

module.exports = mongoose.model('Task', taskSchema);