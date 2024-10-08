// routes/userRoutes.js

const express = require('express');
const router = express.Router();
const { getAllUsers, getUserById } = require('../controllers/userController');

// Route to fetch all users
router.get('/', getAllUsers);

// Route to fetch a user by ID
router.get('/:id', getUserById);

module.exports = router;
