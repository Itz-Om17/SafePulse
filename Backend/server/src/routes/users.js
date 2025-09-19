const express = require('express');
const db = require('../config/db');
const router = express.Router();

// Get user by email
router.get('/email/:email', async (req, res) => {
  try {
    const { email } = req.params;

    const [users] = await db.execute(
      'SELECT * FROM users WHERE email = ? AND is_active = 1',
      [email]
    );

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    console.log("success");
    res.json({
      success: true,
      data: users[0]
    });
  } catch (error) {
    console.error('Get user by email error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Add other user routes as needed
module.exports = router;


