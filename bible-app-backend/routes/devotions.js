const express = require('express');
const router = express.Router();
const devotionController = require('../controllers/devotionController');

// Create a new devotion
router.post('/', devotionController.createDevotion);

// Get a single devotion by ID
router.get('/:id', devotionController.getDevotionById);

// Get all devotions
router.get('/', devotionController.getAllDevotions);

// Update a devotion by ID
router.put('/:id', devotionController.updateDevotion);

// Delete a devotion by ID
router.delete('/:id', devotionController.deleteDevotion);

module.exports = router;
