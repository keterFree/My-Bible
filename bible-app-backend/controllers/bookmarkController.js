// controllers/bookmarkController.js

const Bookmark = require('../models/Bookmark');

// Add a new bookmark
exports.addBookmark = async (req, res) => {
  const { book, chapter, verse ,note} = req.body;
  try {
    const newBookmark = new Bookmark({
      user: req.user.id,
      book,
      chapter,
      verse,
      note,
    });

    const bookmark = await newBookmark.save();
    res.json(bookmark);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
};

// Get all bookmarks for the logged-in user
exports.getBookmarks = async (req, res) => {
  try {
    const bookmarks = await Bookmark.find({ user: req.user.id }).sort({ dateAdded: -1 });
    res.json(bookmarks);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
};

// Delete a bookmark
exports.deleteBookmark = async (req, res) => {
  try {
    const bookmark = await Bookmark.findById(req.params.id);

    if (!bookmark) {
      return res.status(404).json({ msg: 'Bookmark not found' });
    }

    // Ensure user owns the bookmark
    if (bookmark.user.toString() !== req.user.id) {
      return res.status(401).json({ msg: 'User not authorized' });
    }

    await bookmark.remove();
    res.json({ msg: 'Bookmark removed' });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
};
