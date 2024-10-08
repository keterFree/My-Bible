// controllers/userController.js

const User = require('../models/User'); // Import User model

// Controller to fetch all users
const getAllUsers = async (req, res) => {
    try {
        const users = await User.find().populate('groups', 'name').exec();
        res.status(200).json(users);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching users', error });
    }
};

// Controller to fetch a single user by ID
const getUserById = async (req, res) => {
    try {
        const userId = req.params.id;
        const user = await User.findById(userId).populate('groups', 'name').exec();
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.status(200).json(user);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching user', error });
    }
};

module.exports = {
    getAllUsers,
    getUserById,
};
