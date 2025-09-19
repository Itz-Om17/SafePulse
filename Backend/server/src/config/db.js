const mysql = require('mysql2');
require('dotenv').config();

// Create MySQL connection pool
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'registration_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Create users table if it doesn't exist
const createUsersTable = `
  CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('District Collector', 'Hospital', 'Villager', 'Associate', 'Taluka Head', 'Ground Worker') NOT NULL,
    hospital_name VARCHAR(255),
    secret_key VARCHAR(255),
    registered_by VARCHAR(255) DEFAULT 'self',
    registered_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
  )
`;

pool.query(createUsersTable, (err) => {
  if (err) {
    console.error('Error creating users table:', err);
  } else {
    console.log('Users table ready');
  }
});

// Promise wrapper for the pool
const promisePool = pool.promise();

module.exports = promisePool;