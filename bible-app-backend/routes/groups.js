const express = require('express');
const {
    getAllGroups,
    getGroupById,
    createGroup,
    addMembersOrLeaders,
    getMessagesByGroup
} = require('../controllers/groupController');
const verifyToken = require('../middleware/verifyToken'); // Authentication middleware
const ensureLeader = require('../middleware/ensureLeader'); // Ensure the user is a leader

const router = express.Router();

// Routes
router.get('/', verifyToken, getAllGroups);
router.get('/:id', verifyToken, getGroupById);
router.post('/', verifyToken, ensureLeader, createGroup);
router.put('/add/:id', verifyToken, addMembersOrLeaders); 
router.get('/messages/:id', getMessagesByGroup)

module.exports = router;
