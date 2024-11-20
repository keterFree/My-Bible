const express = require('express');
const {
    setEvent,
    getEvents,
    getEventByDate,
    getEventById,
    addProgramItem,
    editProgramItem,
    editEvent,
    deleteEvent,
} = require('../controllers/eventController');

const verifyToken = require('../middleware/verifyToken'); // Authentication middleware
const ensureLeader = require('../middleware/ensureLeader'); // Ensure the user is a leader

const router = express.Router();

router.post('/', verifyToken, ensureLeader, setEvent);
router.get('/', verifyToken, getEvents);
router.get('/:date', verifyToken, getEventByDate);
router.get('/byId/:eventId', verifyToken, getEventById);
router.post('/programItem/:eventId', verifyToken, ensureLeader, addProgramItem);
router.put('/programItem/:eventId/:itemId', verifyToken, ensureLeader, editProgramItem);
router.put('/edit/:eventId', verifyToken, ensureLeader, editEvent);
router.delete('/:eventId', verifyToken, ensureLeader, deleteEvent);


module.exports = router;
