const express = require('express');
const router = express.Router();
const imageController = require('../controllers/imageController');

router.post('/upload', imageController.uploadMiddleware, imageController.uploadImage);
router.get('/:id', imageController.getImageById);
router.get('/', imageController.getAllImages);
router.delete('/:id', imageController.deleteImage);

module.exports = router;
