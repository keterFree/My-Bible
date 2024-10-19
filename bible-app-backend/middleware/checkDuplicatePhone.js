const User = require('../models/User');

const checkDuplicatePhone = async (req, res, next) => {
  const { phone } = req.body;

  if (!phone) {
    console.log('No phone number provided, skipping duplicate check');
    return next(); // If phone is missing, move to the next middleware
  }

  try {
    const userId = req.user ? req.user.id : null;
    const existingUser = await User.findOne({ phone });

    if (existingUser && (!userId || existingUser.id !== userId)) {

      console.log('Phone check failed, duplicates found');
      return res.json({ msg: 'Phone number already in use', status: "400" });
    } else {

      console.log('Phone check passed, no duplicates');
      next(); // No duplicates found, proceed
    }
  } catch (err) {
    console.error('Phone duplication check error:', err.message);
    res.status(500).json({ msg: 'Server error during phone check' });
  }
};

module.exports = checkDuplicatePhone;