create database fieldbuddy;
use fieldbuddy;
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255),
    phone VARCHAR(20),
    state VARCHAR(100),
    city VARCHAR(100),
    recommendedCrop VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
ALTER TABLE users ADD COLUMN password VARCHAR(100);
INSERT INTO users (username, email, phone, state, city, recommendedCrop)
VALUES ('john_doe', 'john.doe@example.com', '9876543210', 'Maharashtra', 'Pune', 'Wheat');
UPDATE users
SET password = 'mypassword123'
WHERE username = 'john_doe';



SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE users;
TRUNCATE TABLE associates;
TRUNCATE TABLE taluka_heads;
TRUNCATE TABLE ground_workers;
SET FOREIGN_KEY_CHECKS = 1;
create database registration_db;
use registration_db;
select * from users;
select * from associates;
select * from taluka_heads;
select * from ground_workers;

CREATE TABLE IF NOT EXISTS associates (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  district VARCHAR(100),
  taluka VARCHAR(100),
  village VARCHAR(100),
  assigned_area TEXT,
  additional_info TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY unique_user (user_id)
);


CREATE TABLE IF NOT EXISTS taluka_heads (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  district VARCHAR(100),
  taluka VARCHAR(100) NOT NULL,
  village VARCHAR(100),
  assigned_area TEXT,
  additional_info TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY unique_user (user_id)
);


CREATE TABLE IF NOT EXISTS ground_workers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  district VARCHAR(100),
  taluka VARCHAR(100) NOT NULL,
  village VARCHAR(100) NOT NULL,
  assigned_area TEXT,
  additional_info TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY unique_user (user_id)
);

-- Add district column to users table if not exists
ALTER TABLE users ADD COLUMN district VARCHAR(100);
ALTER TABLE users ADD COLUMN state VARCHAR(100);
-- Add unique constraint for District Collector per district
ALTER TABLE users ADD CONSTRAINT unique_dc_per_district UNIQUE (role, district);

