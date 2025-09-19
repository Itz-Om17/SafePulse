const express = require('express');
const db = require('../config/db');
const router = express.Router();

// Register a new associate
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
    if (!name || !email || !phone || !password || !registeredBy) {
      return res.status(400).json({
        success: false,
        message: 'Name, email, phone, password, and registeredBy are required fields'
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
       VALUES (?, ?, ?, ?, 'Associate', ?, NOW(), 1)`,
      [name, phone, email, password, registeredBy]
    );

    const userId = userResult.insertId;

    // Insert into associates table
    const [associateResult] = await connection.execute(
      `INSERT INTO associates 
       (user_id, district, taluka, village, assigned_area, additional_info, created_at) 
       VALUES (?, ?, ?, ?, ?, ?, NOW())`,
      [userId, district || null, taluka || null, village || null, assignedArea || null, additionalInfo || null]
    );

    await connection.commit();

    res.status(201).json({
      success: true,
      message: 'Associate registered successfully',
      data: {
        userId: userId,
        associateId: associateResult.insertId,
        name: name,
        email: email,
        role: 'Associate'
      }
    });

  } catch (error) {
    await connection.rollback();
    
    console.error('Associate registration error:', error);
    
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

// Get all associates
router.get('/', async (req, res) => {
  try {
    const [associates] = await db.execute(
      `SELECT a.*, u.name, u.email, u.phone, u.registered_by, u.registered_at 
       FROM associates a 
       INNER JOIN users u ON a.user_id = u.id 
       WHERE u.role = 'Associate' AND u.is_active = 1`
    );

    res.json({
      success: true,
      data: associates
    });
  } catch (error) {
    console.error('Get associates error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get associate by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [associates] = await db.execute(
      `SELECT a.*, u.name, u.email, u.phone, u.registered_by, u.registered_at 
       FROM associates a 
       INNER JOIN users u ON a.user_id = u.id 
       WHERE a.id = ? AND u.role = 'Associate' AND u.is_active = 1`,
      [id]
    );

    if (associates.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Associate not found'
      });
    }

    res.json({
      success: true,
      data: associates[0]
    });
  } catch (error) {
    console.error('Get associate error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Update associate
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

    // First check if associate exists
    const [associates] = await connection.execute(
      'SELECT user_id FROM associates WHERE id = ?',
      [id]
    );

    if (associates.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Associate not found'
      });
    }

    const userId = associates[0].user_id;

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

    // Update associates table
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
        `UPDATE associates SET ${updateFields.join(', ')} WHERE id = ?`,
        updateValues
      );
    }

    await connection.commit();

    res.json({
      success: true,
      message: 'Associate updated successfully'
    });

  } catch (error) {
    await connection.rollback();
    
    console.error('Update associate error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  } finally {
    connection.release();
  }
});

// Delete associate (soft delete)
router.delete('/:id', async (req, res) => {
  const connection = await db.getConnection();
  
  try {
    await connection.beginTransaction();
    
    const { id } = req.params;

    // First check if associate exists and get user_id
    const [associates] = await connection.execute(
      'SELECT user_id FROM associates WHERE id = ?',
      [id]
    );

    if (associates.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Associate not found'
      });
    }

    const userId = associates[0].user_id;

    // Soft delete from users table (set is_active = 0)
    await connection.execute(
      'UPDATE users SET is_active = 0 WHERE id = ?',
      [userId]
    );

    await connection.commit();

    res.json({
      success: true,
      message: 'Associate deleted successfully'
    });

  } catch (error) {
    await connection.rollback();
    
    console.error('Delete associate error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  } finally {
    connection.release();
  }
});

module.exports = router;