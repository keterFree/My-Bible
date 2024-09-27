// routes/bookmarks.js

const express = require('express');
const router = express.Router();
const auth = require('../middleware/authMiddleware');
const {
  addBookmark,
  getBookmarks,
  deleteBookmark,
} = require('../controllers/bookmarkController');

// @route   POST api/bookmarks
// @desc    Add a new bookmark
// @access  Private
router.post('/', auth, addBookmark);

// @route   GET api/bookmarks
// @desc    Get all bookmarks for the user
// @access  Private
router.get('/', auth, getBookmarks);

// @route   DELETE api/bookmarks/:id
// @desc    Delete a bookmark
// @access  Private
router.delete('/:id', auth, deleteBookmark);

module.exports = router;
