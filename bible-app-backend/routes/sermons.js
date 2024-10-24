const express = require('express');
const router = express.Router();
const sermonController = require('../controllers/sermonController');

// Create a new sermon
router.post('/', sermonController.createSermon);

// Get a single sermon by ID
router.get('/:id', sermonController.getSermonById);

// Get all sermons
router.get('/', sermonController.getAllSermons);

// Update a sermon by ID
router.put('/:id', sermonController.updateSermon);

// Delete a sermon by ID
router.delete('/:id', sermonController.deleteSermon);

module.exports = router;
