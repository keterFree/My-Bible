const express = require('express');
const { getAllGroups, getGroupById, createGroup } = require('../controllers/groupController');
const verifyToken = require('../middleware/verifyToken'); // Assuming you have an auth middleware
const ensureLeader = require('../middleware/ensureLeader');
const router = express.Router();

router.get('/', verifyToken, getAllGroups);
router.get('/:id', verifyToken, getGroupById);
router.post('/', verifyToken, ensureLeader, createGroup); // Route to create group

module.exports = router;
