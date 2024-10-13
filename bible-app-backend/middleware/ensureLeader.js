const ensureLeader = (req, res, next) => {
    // Check if user is defined and has the 'tier' property
    if (!req.user || req.user.tier !== 'leader') {
        return res.status(403).json({ message: 'Access denied. Only leaders can create groups.' });
    }
    next();
};

module.exports = ensureLeader;
