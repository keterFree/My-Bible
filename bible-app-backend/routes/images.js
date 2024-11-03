const express = require('express');
const router = express.Router();
const imageController = require('../controllers/imageController');
const verifyToken = require('../middleware/verifyToken'); // Authentication middleware
const ensureLeader = require('../middleware/ensureLeader'); // Ensure the user is a leader

router.post('/upload', verifyToken, ensureLeader, imageController.uploadMiddleware, imageController.uploadImage);
router.get('/:id', imageController.getImageById);
router.get('/', imageController.getAllImages);
router.delete('/:id', verifyToken, ensureLeader, imageController.deleteImage);

module.exports = router;
