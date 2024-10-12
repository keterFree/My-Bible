// middlewares/auth.js

const ensureLeader = (req, res, next) => {
    if (req.user.tier !== 'leader') {
      return res.status(403).json({ message: 'Access denied. Only leaders can create groups.' });
    }
    next();
  };
  
  module.exports = {
    ensureLeader,
  };
  