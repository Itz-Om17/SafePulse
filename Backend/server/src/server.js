const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const routes = require('./routes');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));


const dbUrl = process.env.DB_URL; //

mongoose.connect(dbUrl, {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => console.log('MongoDB connected successfully! ✨'))
.catch(err => console.error('MongoDB connection error:', err));

// Routes
app.use('/api', routes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    success: true, 
    message: 'Server is running' 
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ 
    success: false, 
    message: 'Route not found' 
  });
});



// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    success: false, 
    message: 'Something went wrong!' 
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});