const express = require('express');
const {
    setEvent,
    getEvents,
    getEventByDate,
    addProgramItem
} = require('../controllers/eventController');

const verifyToken = require('../middleware/verifyToken'); // Authentication middleware
const ensureLeader = require('../middleware/ensureLeader'); // Ensure the user is a leader

const router = express.Router();

router.post('/', verifyToken, ensureLeader, setEvent);
router.get('/', verifyToken, getEvents);
router.get('/:date', verifyToken, getEventByDate);
router.post('/programItem/:eventId', addProgramItem);

module.exports = router;
