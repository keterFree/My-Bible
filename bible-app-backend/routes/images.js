const express = require('express');
const router = express.Router();
const imageController = require('../controllers/imageController');

// Middleware for handling file uploads
const upload = require('multer')().single('file'); // Adjust 'file' to your field name in the form

// Upload an image
router.post('/upload', upload, imageController.uploadImage);

// Get a single image by ID
router.get('/:id', imageController.getImageById);

// Get all images
router.get('/', imageController.getAllImages);

// Delete an image by ID
router.delete('/:id', imageController.deleteImage);

module.exports = router;
