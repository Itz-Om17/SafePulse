const express = require('express');
const db = require('../config/db');
const router = express.Router();

// Register a new ground worker
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
    if (!name || !email || !phone || !password || !registeredBy || !taluka || !village) {
      return res.status(400).json({
        success: false,
        message: 'Name, email, phone, password, registeredBy, taluka, and village are required fields'
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
       VALUES (?, ?, ?, ?, 'Ground Worker', ?, NOW(), 1)`,
      [name, phone, email, password, registeredBy]
    );

    const userId = userResult.insertId;

    // Insert into ground_workers table
    const [groundWorkerResult] = await connection.execute(
      `INSERT INTO ground_workers 
       (user_id, district, taluka, village, assigned_area, additional_info, created_at) 
       VALUES (?, ?, ?, ?, ?, ?, NOW())`,
      [userId, district || null, taluka, village, assignedArea || null, additionalInfo || null]
    );

    await connection.commit();

    res.status(201).json({
      success: true,
      message: 'Ground Worker registered successfully',
      data: {
        userId: userId,
        groundWorkerId: groundWorkerResult.insertId,
        name: name,
        email: email,
        role: 'Ground Worker'
      }
    });

  } catch (error) {
    await connection.rollback();
    
    console.error('Ground Worker registration error:', error);
    
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

// Bulk register ground workers
router.post('/bulk-register', async (req, res) => {
  const connection = await db.getConnection();
  
  try {
    await connection.beginTransaction();
    
    const { workers, registeredBy, defaultTaluka } = req.body;

    // Validate required fields
    if (!workers || !Array.isArray(workers) || workers.length === 0 || !registeredBy || !defaultTaluka) {
      return res.status(400).json({
        success: false,
        message: 'Workers array, registeredBy, and defaultTaluka are required fields'
      });
    }

    const results = {
      successful: [],
      failed: []
    };

    for (const [index, worker] of workers.entries()) {
      try {
        const {
          name,
          email,
          phone,
          password,
          district,
          taluka = defaultTaluka, // Use default taluka if not provided
          village,
          assignedArea,
          additionalInfo
        } = worker;

        // Validate required fields for each worker
        if (!name || !email || !phone || !password || !village) {
          results.failed.push({
            index,
            worker,
            error: 'Missing required fields: name, email, phone, password, or village'
          });
          continue;
        }

        // Validate email format
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
          results.failed.push({
            index,
            worker,
            error: 'Invalid email format'
          });
          continue;
        }

        // Check if user already exists
        const [existingUsers] = await connection.execute(
          'SELECT id FROM users WHERE email = ?',
          [email]
        );

        if (existingUsers.length > 0) {
          results.failed.push({
            index,
            worker,
            error: 'User with this email already exists'
          });
          continue;
        }

        // Insert into users table
        const [userResult] = await connection.execute(
          `INSERT INTO users 
           (name, phone, email, password, role, registered_by, registered_at, is_active) 
           VALUES (?, ?, ?, ?, 'Ground Worker', ?, NOW(), 1)`,
          [name, phone, email, password, registeredBy]
        );

        const userId = userResult.insertId;

        // Insert into ground_workers table
        const [groundWorkerResult] = await connection.execute(
          `INSERT INTO ground_workers 
           (user_id, district, taluka, village, assigned_area, additional_info, created_at) 
           VALUES (?, ?, ?, ?, ?, ?, NOW())`,
          [userId, district || null, taluka, village, assignedArea || null, additionalInfo || null]
        );

        results.successful.push({
          index,
          userId,
          groundWorkerId: groundWorkerResult.insertId,
          name,
          email
        });

      } catch (error) {
        results.failed.push({
          index,
          worker,
          error: error.code === 'ER_DUP_ENTRY' ? 'User with this email already exists' : 'Internal error'
        });
      }
    }

    // If any worker failed and we have successful registrations, rollback everything
    if (results.failed.length > 0 && results.successful.length > 0) {
      await connection.rollback();
      
      return res.status(400).json({
        success: false,
        message: 'Some workers failed registration. All registrations rolled back.',
        data: results
      });
    }

    // If all workers failed
    if (results.failed.length > 0 && results.successful.length === 0) {
      await connection.rollback();
      
      return res.status(400).json({
        success: false,
        message: 'All workers failed registration',
        data: results
      });
    }

    // If all workers succeeded
    await connection.commit();

    res.status(201).json({
      success: true,
      message: 'All ground workers registered successfully',
      data: results
    });

  } catch (error) {
    await connection.rollback();
    
    console.error('Bulk ground worker registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  } finally {
    connection.release();
  }
});

// Get all ground workers
router.get('/', async (req, res) => {
  try {
    const [groundWorkers] = await db.execute(
      `SELECT gw.*, u.name, u.email, u.phone, u.registered_by, u.registered_at 
       FROM ground_workers gw 
       INNER JOIN users u ON gw.user_id = u.id 
       WHERE u.role = 'Ground Worker' AND u.is_active = 1`
    );

    res.json({
      success: true,
      data: groundWorkers
    });
  } catch (error) {
    console.error('Get ground workers error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get ground worker by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const [groundWorkers] = await db.execute(
      `SELECT gw.*, u.name, u.email, u.phone, u.registered_by, u.registered_at 
       FROM ground_workers gw 
       INNER JOIN users u ON gw.user_id = u.id 
       WHERE gw.id = ? AND u.role = 'Ground Worker' AND u.is_active = 1`,
      [id]
    );

    if (groundWorkers.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Ground Worker not found'
      });
    }

    res.json({
      success: true,
      data: groundWorkers[0]
    });
  } catch (error) {
    console.error('Get ground worker error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get ground workers by district
router.get('/district/:district', async (req, res) => {
  try {
    const { district } = req.params;

    const [groundWorkers] = await db.execute(
      `SELECT gw.*, u.name, u.email, u.phone, u.registered_by, u.registered_at 
       FROM ground_workers gw 
       INNER JOIN users u ON gw.user_id = u.id 
       WHERE gw.district = ? AND u.role = 'Ground Worker' AND u.is_active = 1`,
      [district]
    );

    res.json({
      success: true,
      data: groundWorkers
    });
  } catch (error) {
    console.error('Get ground workers by district error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get ground workers by taluka
router.get('/taluka/:taluka', async (req, res) => {
  try {
    const { taluka } = req.params;

    const [groundWorkers] = await db.execute(
      `SELECT gw.*, u.name, u.email, u.phone, u.registered_by, u.registered_at 
       FROM ground_workers gw 
       INNER JOIN users u ON gw.user_id = u.id 
       WHERE gw.taluka = ? AND u.role = 'Ground Worker' AND u.is_active = 1`,
      [taluka]
    );

    res.json({
      success: true,
      data: groundWorkers
    });
  } catch (error) {
    console.error('Get ground workers by taluka error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get ground workers by village
router.get('/village/:village', async (req, res) => {
  try {
    const { village } = req.params;

    const [groundWorkers] = await db.execute(
      `SELECT gw.*, u.name, u.email, u.phone, u.registered_by, u.registered_at 
       FROM ground_workers gw 
       INNER JOIN users u ON gw.user_id = u.id 
       WHERE gw.village = ? AND u.role = 'Ground Worker' AND u.is_active = 1`,
      [village]
    );

    res.json({
      success: true,
      data: groundWorkers
    });
  } catch (error) {
    console.error('Get ground workers by village error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get ground workers by registeredBy (who registered them)
router.get('/registered-by/:registeredBy', async (req, res) => {
  try {
    const { registeredBy } = req.params;

    const [groundWorkers] = await db.execute(
      `SELECT gw.*, u.name, u.email, u.phone, u.registered_by, u.registered_at 
       FROM ground_workers gw 
       INNER JOIN users u ON gw.user_id = u.id 
       WHERE u.registered_by = ? AND u.role = 'Ground Worker' AND u.is_active = 1`,
      [registeredBy]
    );

    res.json({
      success: true,
      data: groundWorkers
    });
  } catch (error) {
    console.error('Get ground workers by registeredBy error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Update ground worker
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

    // First check if ground worker exists
    const [groundWorkers] = await connection.execute(
      'SELECT user_id FROM ground_workers WHERE id = ?',
      [id]
    );

    if (groundWorkers.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Ground Worker not found'
      });
    }

    const userId = groundWorkers[0].user_id;

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

    // Update ground_workers table
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
        `UPDATE ground_workers SET ${updateFields.join(', ')} WHERE id = ?`,
        updateValues
      );
    }

    await connection.commit();

    res.json({
      success: true,
      message: 'Ground Worker updated successfully'
    });

  } catch (error) {
    await connection.rollback();
    
    console.error('Update ground worker error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  } finally {
    connection.release();
  }
});

// Delete ground worker (soft delete)
router.delete('/:id', async (req, res) => {
  const connection = await db.getConnection();
  
  try {
    await connection.beginTransaction();
    
    const { id } = req.params;

    // First check if ground worker exists and get user_id
    const [groundWorkers] = await connection.execute(
      'SELECT user_id FROM ground_workers WHERE id = ?',
      [id]
    );

    if (groundWorkers.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Ground Worker not found'
      });
    }

    const userId = groundWorkers[0].user_id;

    // Soft delete from users table (set is_active = 0)
    await connection.execute(
      'UPDATE users SET is_active = 0 WHERE id = ?',
      [userId]
    );

    await connection.commit();

    res.json({
      success: true,
      message: 'Ground Worker deleted successfully'
    });

  } catch (error) {
    await connection.rollback();
    
    console.error('Delete ground worker error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  } finally {
    connection.release();
  }
});

// Get ground worker statistics
router.get('/stats/count', async (req, res) => {
  try {
    const [stats] = await db.execute(
      `SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN gw.district IS NOT NULL THEN 1 END) as with_district,
        COUNT(CASE WHEN gw.taluka IS NOT NULL THEN 1 END) as with_taluka,
        COUNT(CASE WHEN gw.village IS NOT NULL THEN 1 END) as with_village,
        COUNT(CASE WHEN gw.assigned_area IS NOT NULL THEN 1 END) as with_assigned_area
       FROM ground_workers gw 
       INNER JOIN users u ON gw.user_id = u.id 
       WHERE u.role = 'Ground Worker' AND u.is_active = 1`
    );

    res.json({
      success: true,
      data: stats[0]
    });
  } catch (error) {
    console.error('Get ground worker statistics error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Search ground workers
router.get('/search/:query', async (req, res) => {
  try {
    const { query } = req.params;
    const searchQuery = `%${query}%`;

    const [groundWorkers] = await db.execute(
      `SELECT gw.*, u.name, u.email, u.phone, u.registered_by, u.registered_at 
       FROM ground_workers gw 
       INNER JOIN users u ON gw.user_id = u.id 
       WHERE (u.name LIKE ? OR u.email LIKE ? OR gw.taluka LIKE ? OR gw.district LIKE ? OR gw.village LIKE ?) 
       AND u.role = 'Ground Worker' AND u.is_active = 1`,
      [searchQuery, searchQuery, searchQuery, searchQuery, searchQuery]
    );

    res.json({
      success: true,
      data: groundWorkers
    });
  } catch (error) {
    console.error('Search ground workers error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get ground workers count by taluka
router.get('/stats/count-by-taluka', async (req, res) => {
  try {
    const [counts] = await db.execute(
      `SELECT taluka, COUNT(*) as count 
       FROM ground_workers gw 
       INNER JOIN users u ON gw.user_id = u.id 
       WHERE u.role = 'Ground Worker' AND u.is_active = 1 
       GROUP BY taluka 
       ORDER BY count DESC`
    );

    res.json({
      success: true,
      data: counts
    });
  } catch (error) {
    console.error('Get ground workers count by taluka error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get ground workers count by village
router.get('/stats/count-by-village', async (req, res) => {
  try {
    const [counts] = await db.execute(
      `SELECT village, COUNT(*) as count 
       FROM ground_workers gw 
       INNER JOIN users u ON gw.user_id = u.id 
       WHERE u.role = 'Ground Worker' AND u.is_active = 1 
       GROUP BY village 
       ORDER BY count DESC`
    );

    res.json({
      success: true,
      data: counts
    });
  } catch (error) {
    console.error('Get ground workers count by village error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get ground worker by userId
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const [groundWorkers] = await db.execute(
      `SELECT gw.*, u.name, u.email, u.phone, u.registered_by, u.registered_at 
       FROM ground_workers gw 
       INNER JOIN users u ON gw.user_id = u.id 
       WHERE gw.user_id = ? AND u.role = 'Ground Worker' AND u.is_active = 1`,
      [userId]
    );

    if (groundWorkers.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Ground Worker not found'
      });
    }
    console.log(groundWorkers);
    res.json({
      success: true,
      data: groundWorkers[0]
    });
  } catch (error) {
    console.error('Get ground worker by userId error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get ground workers by assigned area
router.get('/assigned-area/:assignedArea', async (req, res) => {
  try {
    const { assignedArea } = req.params;

    const [groundWorkers] = await db.execute(
      `SELECT gw.*, u.name, u.email, u.phone, u.registered_by, u.registered_at 
       FROM ground_workers gw 
       INNER JOIN users u ON gw.user_id = u.id 
       WHERE gw.assigned_area LIKE ? AND u.role = 'Ground Worker' AND u.is_active = 1`,
      [`%${assignedArea}%`]
    );

    res.json({
      success: true,
      data: groundWorkers
    });
  } catch (error) {
    console.error('Get ground workers by assigned area error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

module.exports = router;