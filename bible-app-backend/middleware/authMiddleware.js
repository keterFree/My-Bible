const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Middleware to verify JWT and check for duplicate phone number
module.exports = async function (req, res, next) {
  // Get token from header
  const token = req.header('Authorization');

  // Check if no token is provided
  if (!token) {
    return res.status(401).json({ msg: 'No token, authorization denied' });
  }

  // Verify token
  try {
    // Split the Bearer part from the token (if present)
    const bearer = token.split(' ');
    if (bearer[0] !== 'Bearer' || !bearer[1]) {
      return res.status(401).json({ msg: 'Token is not valid' });
    }

    const decoded = jwt.verify(bearer[1], process.env.JWT_SECRET); // Use the actual token
    req.user = decoded.user;

    // Check for duplicate phone number if the request contains a phone field
    const { phone } = req.body;
    if (phone) {
      const userId = req.user ? req.user.id : null; // Get the user ID from the token

      // Find a user with the same phone number, excluding the current user (if available)
      const existingUser = await User.findOne({ phone });
      if (existingUser && (!userId || existingUser.id !== userId)) {
        return res.status(400).json({ msg: 'Phone number already in use' });
      }
    }

    // If no issues, proceed to the next middleware or route handler
    next();
  } catch (err) {
    console.error('Token verification or phone duplication check error:', err.message);
    res.status(401).json({ msg: 'Token is not valid or duplicate phone found' });
  }
};
