const Bookmark = require('../models/Bookmark');
const Scripture = require('../models/Scripture');

// Add a new bookmark
exports.addBookmark = async (req, res) => {
  const { book, chapter, verseNumbers, note } = req.body;

  try {
    // Create a new Scripture entry or fetch an existing one
    const scripture = await Scripture.create({
      book,
      chapter,
      verseNumbers,
    });

    const newBookmark = new Bookmark({
      user: req.user.id,
      scripture: [scripture._id], // Store the scripture's ID
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
    const bookmarks = await Bookmark.find({ user: req.user.id })
      .populate('scripture') // Populate scripture field with referenced data
      .sort({ dateAdded: -1 });

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


[
  {
    "_id": "65374bd4e31ad1b2a5d0d3f9",
    "user": "65374bd4e31ad1b2a5d0d2c7",
    "scripture": [
      {
        "_id": "65374bce31ad1b2a5d0d3a2",
        "book": 1,
        "chapter": 3,
        "verseNumbers": [16, 17],
        "__v": 0
      }
    ],
    "note": "Important scripture",
    "dateAdded": "2024-10-24T12:30:27.245Z",
    "__v": 0
  }
]
