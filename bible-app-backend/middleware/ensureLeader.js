const User = require('../models/User');

const ensureLeader = (req, res, next) => {
    // Check if user is defined and has the 'tier' property
    console.log(`Tier: ${req.user.tier}`);
    if (!req.user || req.user.tier !== 'admin') {
        return res.status(403).json({ message: 'Access denied. Only leaders can create groups.' });
    }
    next();
};

module.exports = ensureLeader;
