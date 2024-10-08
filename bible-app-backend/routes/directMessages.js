// routes/directMessages.js
const express = require('express');
const router = express.Router();
const { fetchOrCreateDirectMessage } = require('../controllers/directMessageController');

// POST request to fetch or create a direct message
router.post('/', fetchOrCreateDirectMessage);

module.exports = router;
