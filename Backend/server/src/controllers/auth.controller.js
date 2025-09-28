const User = require('../models/user.model');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const authController = {
  // Register a new user
  async register(req, res) {
    try {
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
        isActive, district, state
      } = req.body;

      // Validate required fields
      if (!name || !phone || !email || !password || !role) {
        return res.status(400).json({
          success: false,
          message: 'Please provide all required fields'
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
      const existingUser = await User.findByEmail(email);
      if (existingUser) {
        return res.status(409).json({
          success: false,
          message: 'User with this email already exists'
        });
      }

      // Validate role-specific requirements
      if (role === 'District Collector') {
        if (!secretKey || secretKey !== 'DC-MASTER-KEY-2025') {
          return res.status(400).json({
            success: false,
            message: 'Invalid District Collector Secret Key'
          });
        }
      }

      if (role === 'Hospital' && !hospitalName) {
        return res.status(400).json({
          success: false,
          message: 'Hospital name is required for Hospital role'
        });
      }

      // Hash password (in production)
      // const hashedPassword = await bcrypt.hash(password, 12);
      // For simplicity, we're storing plain text in this example
      // In production, always hash passwords!

      // Create user
      const userId = await User.create({
        name,
        phone,
        email,
        password, // In production: hashedPassword
        role,
        hospitalName: hospitalName || null,
        secretKey: secretKey || null,
        registeredBy: registeredBy || 'self',
        registeredAt: registeredAt || new Date(),
        isActive: isActive === 'true' || isActive === true || true,
        district: district || null,
        state: state || null,
      });

      res.status(201).json({
        success: true,
        message: 'User registered successfully',
        data: {
          id: userId,
          name,
          email,
          role
        }
      });
    } catch (error) {
  console.error('Registration error:', error);

  // Handle duplicate District Collector per district
  if (error.code === 'ER_DUP_ENTRY' && error.sqlMessage.includes('unique_dc_per_district')) {
    return res.status(409).json({
      success: false,
      message: `A District Collector for  ${req.body.district} district has already been registered.`
    });
  }

  // Handle duplicate email (if you have a unique constraint on email)
  if (error.code === 'ER_DUP_ENTRY' && error.sqlMessage.includes('email')) {
    return res.status(409).json({
      success: false,
      message: 'User with this email already exists.'
    });
  }

  // Generic server error
  res.status(500).json({
    success: false,
    message: 'Internal server error'
  });
}
  },

  // Login user
  async login(req, res) {
    try {
      const { email, password } = req.body;

      if (!email || !password) {
        return res.status(400).json({
          success: false,
          message: 'Please provide email and password'
        });
      }

      // Find user
      const user = await User.findByEmail(email);
      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials'
        });
      }

      // Check password (in production)
      // const isPasswordValid = await bcrypt.compare(password, user.password);
      // For simplicity, we're comparing plain text in this example
      const isPasswordValid = password === user.password;

      if (!isPasswordValid) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials'
        });
      }
const token = jwt.sign(
  {
    id: user.id,
    email: user.email,
    role: user.role,
    state: user.state,      // <-- new
    district: user.district // <-- new
  },
  process.env.JWT_SECRET,
  { expiresIn: '1d' }
);
      console.log('👉 ABOUT TO SEND', {
  id: user.id,
  name: user.name,   // <-- is this undefined ?
  email: user.email,
  role: user.role,
  state: user.state,      // <-- new
  district: user.district, // <-- new
});

      // In production, generate JWT token here
res.json({
  success: true,
  message: 'Login successful',
  data: {
    id: user.id,
    name: user.name,
    email: user.email,
    role: user.role,
    state: user.state,      // <-- new
    district: user.district, // <-- new
    token
  }
});
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }
};

module.exports = authController;