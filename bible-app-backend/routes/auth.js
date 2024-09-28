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

const verifyToken = require('../middleware/verifyToken');
const checkDuplicatePhone = require('../middleware/checkDuplicatePhone');

// Register user
router.post('/register',checkDuplicatePhone, register);

// Login user
router.post('/login', login);

// Get user details (protected route)
router.get('/profile', verifyToken, getUserDetails);

// Update user details (protected route)
router.put('/profile',verifyToken,checkDuplicatePhone, updateUserDetails);

// Send password reset code
router.post('/password-reset/send', sendResetCode);

// Verify reset code and reset password
router.post('/password-reset/verify', verifyResetCodeAndResetPassword);

module.exports = router;
