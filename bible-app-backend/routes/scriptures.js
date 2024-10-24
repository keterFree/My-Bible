const express = require('express');
const router = express.Router();
const scriptureController = require('../controllers/scriptureController');

// Create a new scripture object
router.post('/', scriptureController.createScripture);

// Get a scripture object by ID
router.get('/:id', scriptureController.getScriptureById);

// Get all scripture objects
router.get('/', scriptureController.getAllScriptures);

// Update a scripture object
router.put('/:id', scriptureController.updateScripture);

// Delete a scripture object
router.delete('/:id', scriptureController.deleteScripture);

module.exports = router;
