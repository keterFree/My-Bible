const express = require('express');
const {
    setEvent,
    getEvents,
    getEventByDate
} = require('../controllers/eventController');

const verifyToken = require('../middleware/verifyToken'); // Authentication middleware
const ensureLeader = require('../middleware/ensureLeader'); // Ensure the user is a leader

const router = express.Router();

// Route to create a new event (protected, requires user to be a leader)
router.post('/', verifyToken, ensureLeader, setEvent);

// Route to get all events (open to all authenticated users)
router.get('/', verifyToken, getEvents);

// Route to get event by date (open to all authenticated users)
router.get('/:date', verifyToken, getEventByDate);

module.exports = router;
