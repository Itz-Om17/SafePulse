const express = require('express');
const authRoutes = require('./auth.routes');
const associateRoutes = require('./associates');
const talukaHeadRoutes = require('./taluka_heads');
const groundWorkerRoutes = require('./ground_workers');
const users = require('./users');
const router = express.Router();

// Use auth routes
router.use('/auth', authRoutes);
router.use('/users',users);
router.use('/associates', associateRoutes);
router.use('/taluka-heads', talukaHeadRoutes);
router.use('/ground-workers', groundWorkerRoutes);
module.exports = router;