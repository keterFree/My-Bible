// routes/highlights.js

const express = require('express');
const router = express.Router();
const auth = require('../middleware/authMiddleware');
const {
  addHighlight,
  getHighlights,
  deleteHighlight,
} = require('../controllers/highlightController');

// @route   POST api/highlights
// @desc    Add a new highlight
// @access  Private
router.post('/', auth, addHighlight);

// @route   GET api/highlights
// @desc    Get all highlights for the user
// @access  Private
router.get('/', auth, getHighlights);

// @route   DELETE api/highlights/:id
// @desc    Delete a highlight
// @access  Private
router.delete('/:id', auth, deleteHighlight);

module.exports = router;
