const express = require('express');
const router = express.Router();
const imageController = require('../controllers/imageController');

// Upload an image
router.post('/upload', imageController.uploadImage);

// Get a single image by ID
router.get('/:id', imageController.getImageById);

// Get all images
router.get('/', imageController.getAllImages);

// Delete an image by ID
router.delete('/:id', imageController.deleteImage);

module.exports = router;
