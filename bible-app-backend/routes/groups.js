const express = require('express');
const { getAllGroups, getGroupById, createGroup } = require('../controllers/groupController');
const { authenticate } = require('../middleware/authMiddleware'); // Assuming you have an auth middleware

const router = express.Router();

router.get('/', authenticate, getAllGroups);
router.get('/:id', authenticate, getGroupById);
router.post('/', authenticate,ensureLeader, createGroup); // Route to create group

module.exports = router;
