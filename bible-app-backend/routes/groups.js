// routes/groupRoutes.js

const express = require('express');
const router = express.Router();
const { getAllGroups, getGroupById } = require('../controllers/groupController');

// Route to fetch all groups
router.get('/', getAllGroups);

// Route to fetch a group by ID
router.get('/:id', getGroupById);

module.exports = router;
