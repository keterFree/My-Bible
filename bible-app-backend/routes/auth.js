const express = require('express');
const router = express.Router();
const {
    register,
    login,
    getUserDetails,
    updateUserDetails,
    sendResetCode,
    verifyResetCodeAndResetPassword
} = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware'); // Authentication middleware (assumed you have this)

// Register user
router.post('/register', register);

// Login user
router.post('/login', login);

// Get user details (protected route)
router.get('/profile', authMiddleware, getUserDetails);

// Update user details (protected route)
router.put('/profile', authMiddleware, updateUserDetails);

// Send password reset code
router.post('/password-reset/send', sendResetCode);

// Verify reset code and reset password
router.post('/password-reset/verify', verifyResetCodeAndResetPassword);

module.exports = router;
