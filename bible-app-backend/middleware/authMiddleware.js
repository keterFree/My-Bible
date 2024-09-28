const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
  // Get token from header
  const token = req.header('Authorization');

  // Check if no token
  if (!token) {
    return res.status(401).json({ msg: 'No token, authorization denied' });
  }

  try {
    // Split the Bearer part from the token (if present)
    const bearer = token.split(' ');
    if (bearer[0] !== 'Bearer' || !bearer[1]) {
      return res.status(401).json({ msg: 'Token is not valid' });
    }

    // Verify and decode the token
    const decoded = jwt.verify(bearer[1], process.env.JWT_SECRET);
    req.user = decoded.user;
    next();
  } catch (err) {
    console.error('Token verification error:', err.message);
    res.status(401).json({ msg: 'Token is not valid' });
  }
};

module.exports = verifyToken;
