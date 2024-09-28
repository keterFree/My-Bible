const User = require('../models/User');

const checkDuplicatePhone = async (req, res, next) => {
  const { phone } = req.body;

  // Only check for duplicate phone number if phone is provided in the request
  if (!phone) {
    return next(); // No phone field, move to the next middleware
  }

  try {
    const userId = req.user ? req.user.id : null; // Get the user ID from `req.user` if it exists (set by verifyToken)
    
    // Find user with the same phone number, exclude the current user (if updating)
    const existingUser = await User.findOne({ phone });
    if (existingUser && (!userId || existingUser.id !== userId)) {
      return res.status(400).json({ msg: 'Phone number already in use' });
    }

    // If no duplicate found, proceed
    next();
  } catch (err) {
    console.error('Phone duplication check error:', err.message);
    res.status(500).json({ msg: 'Server error during phone check' });
  }
};

module.exports = checkDuplicatePhone;
