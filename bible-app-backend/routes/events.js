const express = require('express');
const {
    setEvent,
    getEvents,
    getEventByDate,
    getEventById,
    addProgramItem,
    editProgramItem,
    deleteEvent,
} = require('../controllers/eventController');

const verifyToken = require('../middleware/verifyToken'); // Authentication middleware
const ensureLeader = require('../middleware/ensureLeader'); // Ensure the user is a leader

const router = express.Router();

// Route to create a new event (only leaders allowed)
router.post('/', verifyToken, ensureLeader, setEvent);

// Route to retrieve all events (authenticated users only)
router.get('/', verifyToken, getEvents);

// Route to retrieve an event by date (authenticated users only)
router.get('/:date', verifyToken, getEventByDate);
router.get('/byId/:eventId', verifyToken, getEventById);

// Route to add a program item to an event (leaders only)
router.post('/programItem/:eventId', verifyToken, ensureLeader, addProgramItem);

// Route to edit a program item (leaders only)
router.put('/programItem/:eventId/:itemId', verifyToken, ensureLeader, editProgramItem);

// Route to delete an event by ID (leaders only)
router.delete('/:eventId', verifyToken, ensureLeader, deleteEvent);


module.exports = router;
