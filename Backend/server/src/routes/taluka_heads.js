const express = require('express');
const db = require('../config/db');
const router = express.Router();

// Register a new taluka head
router.post('/register', async (req, res) => {
  const connection = await db.getConnection();
  
  try {
    await connection.beginTransaction();
    
    const {
      name,
      email,
      phone,
      password,
      registeredBy,
      district,
      taluka,
      village,
      assignedArea,
      additionalInfo
    } = req.body;

    // Validate required fields
    if (!name || !email || !phone || !password || !registeredBy || !taluka) {
      return res.status(400).json({
        success: false,
        message: 'Name, email, phone, password, registeredBy, and taluka are required fields'
      });
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid email address'
      });
    }

    // Check if user already exists
    const [existingUsers] = await connection.execute(
      'SELECT id FROM users WHERE email = ?',
      [email]
    );

    if (existingUsers.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'User with this email already exists'
      });
    }

    // Insert into users table
    const [userResult] = await connection.execute(
      `INSERT INTO users 
       (name, phone, email, password, role, registered_by, registered_at, is_active) 
       VALUES (?, ?, ?, ?, 'Taluka Head', ?, NOW(), 1)`,
      [name, phone, email, password, registeredBy]
    );

    const userId = userResult.insertId;

    // Insert into taluka_heads table
    const [talukaHeadResult] = await connection.execute(
      `INSERT INTO taluka_heads 
       (user_id, district, taluka, village, assigned_area, additional_info, created_at) 
       VALUES (?, ?, ?, ?, ?, ?, NOW())`,
      [userId, district || null, taluka, village || null, assignedArea || null, additionalInfo || null]
    );

    await connection.commit();

    res.status(201).json({
      success: true,
      message: 'Taluka Head registered successfully',
      data: {
        userId: userId,
        talukaHeadId: talukaHeadResult.insertId,
        name: name,
        email: email,
        role: 'Taluka Head'
      }
    });

  } catch (error) {
    await connection.rollback();
    
    console.error('Taluka Head registration error:', error);
    
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({
        success: false,
        message: 'User with this email already exists'
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  } finally {
    connection.release();
  }
});

// Get all taluka heads
router.get('/', async (req, res) => {
  try {
    const [talukaHeads] = await db.execute(
      `SELECT th.*, u.name, u.email, u.phone, u.registered_by, u.registered_at 
       FROM taluka_heads th 
       INNER JOIN users u ON th.user_id = u.id 
       WHERE u.role = 'Taluka Head' AND u.is_active = 1`
    );

    res.json({
      success: true,
      data: talukaHeads
    });
  } catch (error) {
    console.error('Get taluka heads error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get taluka head by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [talukaHeads] = await db.execute(
      `SELECT th.*, u.name, u.email, u.phone, u.registered_by, u.registered_at 
       FROM taluka_heads th 
       INNER JOIN users u ON th.user_id = u.id 
       WHERE th.id = ? AND u.role = 'Taluka Head' AND u.is_active = 1`,
      [id]
    );

    if (talukaHeads.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Taluka Head not found'
      });
    }

    res.json({
      success: true,
      data: talukaHeads[0]
    });
  } catch (error) {
    console.error('Get taluka head error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get taluka heads by district
router.get('/district/:district', async (req, res) => {
  try {
    const { district } = req.params;

    const [talukaHeads] = await db.execute(
      `SELECT th.*, u.name, u.email, u.phone, u.registered_by, u.registered_at 
       FROM taluka_heads th 
       INNER JOIN users u ON th.user_id = u.id 
       WHERE th.district = ? AND u.role = 'Taluka Head' AND u.is_active = 1`,
      [district]
    );

    res.json({
      success: true,
      data: talukaHeads
    });
  } catch (error) {
    console.error('Get taluka heads by district error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get taluka heads by taluka
router.get('/taluka/:taluka', async (req, res) => {
  try {
    const { taluka } = req.params;

    const [talukaHeads] = await db.execute(
      `SELECT th.*, u.name, u.email, u.phone, u.registered_by, u.registered_at 
       FROM taluka_heads th 
       INNER JOIN users u ON th.user_id = u.id 
       WHERE th.taluka = ? AND u.role = 'Taluka Head' AND u.is_active = 1`,
      [taluka]
    );

    res.json({
      success: true,
      data: talukaHeads
    });
  } catch (error) {
    console.error('Get taluka heads by taluka error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Update taluka head
router.put('/:id', async (req, res) => {
  const connection = await db.getConnection();
  
  try {
    await connection.beginTransaction();
    
    const { id } = req.params;
    const {
      name,
      email,
      phone,
      district,
      taluka,
      village,
      assignedArea,
      additionalInfo
    } = req.body;

    // First check if taluka head exists
    const [talukaHeads] = await connection.execute(
      'SELECT user_id FROM taluka_heads WHERE id = ?',
      [id]
    );

    if (talukaHeads.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Taluka Head not found'
      });
    }

    const userId = talukaHeads[0].user_id;

    // Update users table
    if (name || email || phone) {
      const updateFields = [];
      const updateValues = [];
      
      if (name) {
        updateFields.push('name = ?');
        updateValues.push(name);
      }
      
      if (email) {
        updateFields.push('email = ?');
        updateValues.push(email);
      }
      
      if (phone) {
        updateFields.push('phone = ?');
        updateValues.push(phone);
      }
      
      updateValues.push(userId);
      
      await connection.execute(
        `UPDATE users SET ${updateFields.join(', ')} WHERE id = ?`,
        updateValues
      );
    }

    // Update taluka_heads table
    const updateFields = [];
    const updateValues = [];
    
    if (district !== undefined) {
      updateFields.push('district = ?');
      updateValues.push(district);
    }
    
    if (taluka !== undefined) {
      updateFields.push('taluka = ?');
      updateValues.push(taluka);
    }
    
    if (village !== undefined) {
      updateFields.push('village = ?');
      updateValues.push(village);
    }
    
    if (assignedArea !== undefined) {
      updateFields.push('assigned_area = ?');
      updateValues.push(assignedArea);
    }
    
    if (additionalInfo !== undefined) {
      updateFields.push('additional_info = ?');
      updateValues.push(additionalInfo);
    }
    
    if (updateFields.length > 0) {
      updateValues.push(id);
      await connection.execute(
        `UPDATE taluka_heads SET ${updateFields.join(', ')} WHERE id = ?`,
        updateValues
      );
    }

    await connection.commit();

    res.json({
      success: true,
      message: 'Taluka Head updated successfully'
    });

  } catch (error) {
    await connection.rollback();
    
    console.error('Update taluka head error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  } finally {
    connection.release();
  }
});

// Delete taluka head (soft delete)
router.delete('/:id', async (req, res) => {
  const connection = await db.getConnection();
  
  try {
    await connection.beginTransaction();
    
    const { id } = req.params;

    // First check if taluka head exists and get user_id
    const [talukaHeads] = await connection.execute(
      'SELECT user_id FROM taluka_heads WHERE id = ?',
      [id]
    );

    if (talukaHeads.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Taluka Head not found'
      });
    }

    const userId = talukaHeads[0].user_id;

    // Soft delete from users table (set is_active = 0)
    await connection.execute(
      'UPDATE users SET is_active = 0 WHERE id = ?',
      [userId]
    );

    await connection.commit();

    res.json({
      success: true,
      message: 'Taluka Head deleted successfully'
    });

  } catch (error) {
    await connection.rollback();
    
    console.error('Delete taluka head error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  } finally {
    connection.release();
  }
});

// Get taluka head statistics
router.get('/stats/count', async (req, res) => {
  try {
    const [stats] = await db.execute(
      `SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN th.district IS NOT NULL THEN 1 END) as with_district,
        COUNT(CASE WHEN th.taluka IS NOT NULL THEN 1 END) as with_taluka,
        COUNT(CASE WHEN th.village IS NOT NULL THEN 1 END) as with_village
       FROM taluka_heads th 
       INNER JOIN users u ON th.user_id = u.id 
       WHERE u.role = 'Taluka Head' AND u.is_active = 1`
    );

    res.json({
      success: true,
      data: stats[0]
    });
  } catch (error) {
    console.error('Get taluka head statistics error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Search taluka heads
router.get('/search/:query', async (req, res) => {
  try {
    const { query } = req.params;
    const searchQuery = `%${query}%`;

    const [talukaHeads] = await db.execute(
      `SELECT th.*, u.name, u.email, u.phone, u.registered_by, u.registered_at 
       FROM taluka_heads th 
       INNER JOIN users u ON th.user_id = u.id 
       WHERE (u.name LIKE ? OR u.email LIKE ? OR th.taluka LIKE ? OR th.district LIKE ?) 
       AND u.role = 'Taluka Head' AND u.is_active = 1`,
      [searchQuery, searchQuery, searchQuery, searchQuery]
    );

    res.json({
      success: true,
      data: talukaHeads
    });
  } catch (error) {
    console.error('Search taluka heads error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// In your taluka_heads routes
// Get taluka head by user ID
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const [talukaHeads] = await db.execute(
      `SELECT th.*, u.name, u.email, u.phone 
       FROM taluka_heads th 
       INNER JOIN users u ON th.user_id = u.id 
       WHERE th.user_id = ? AND u.is_active = 1`,
      [userId]
    );

    if (talukaHeads.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Taluka Head not found'
      });
    }

    res.json({
      success: true,
      data: talukaHeads[0]
    });
  } catch (error) {
    console.error('Get taluka head by user ID error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});
module.exports = router;