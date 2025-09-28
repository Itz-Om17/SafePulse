const db = require('../config/db');

class User {
  // Create a new user
  static async create(userData) {
    const {
      name,
      phone,
      email,
      password,
      role,
      hospitalName,
      secretKey,
      registeredBy,
      registeredAt,
      isActive,
      district,
      state,
    } = userData;

    const sql = `
      INSERT INTO users 
      (name, phone, email, password, role, hospital_name, secret_key, registered_by, registered_at, is_active, district,state) 
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    const [result] = await db.execute(sql, [
      name,
      phone,
      email,
      password, // Note: In production, this should be hashed
      role,
      hospitalName || null,
      secretKey || null,
      registeredBy || 'self',
      registeredAt || new Date(),
      isActive || true,
      district || null,
      state || null, 
    ]);

    return result.insertId;
  }

  // Find user by email
  static async findByEmail(email) {
    const sql = 'SELECT * FROM users WHERE email = ?';
    const [rows] = await db.execute(sql, [email]);
    return rows[0];
  }

  // Find user by ID
  static async findById(id) {
    const sql = 'SELECT * FROM users WHERE id = ?';
    const [rows] = await db.execute(sql, [id]);
    return rows[0];
  }

  // Get all users
  static async findAll() {
    const sql = 'SELECT * FROM users';
    const [rows] = await db.execute(sql);
    return rows;
  }

  // Update user
  static async update(id, userData) {
    const fields = [];
    const values = [];

    for (const [key, value] of Object.entries(userData)) {
      if (value !== undefined) {
        fields.push(`${key} = ?`);
        values.push(value);
      }
    }

    values.push(id);
    const sql = `UPDATE users SET ${fields.join(', ')} WHERE id = ?`;
    const [result] = await db.execute(sql, values);
    return result.affectedRows;
  }

  // Delete user
  static async delete(id) {
    const sql = 'DELETE FROM users WHERE id = ?';
    const [result] = await db.execute(sql, [id]);
    return result.affectedRows;
  }
}

module.exports = User;