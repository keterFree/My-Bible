// controllers/highlightController.js
const Highlight = require('../models/Highlight');
const Scripture = require('../models/Scripture');

// Add a new highlight
exports.addHighlight = async (req, res) => {
  const { book, chapter, verseNumbers, color } = req.body;

  try {
    // Create or retrieve the scripture entry
    const scripture = await Scripture.create({
      book,
      chapter,
      verseNumbers,
    });

    const newHighlight = new Highlight({
      user: req.user.id,
      scripture: [scripture._id], // Store scripture's ID in the highlight
      color,
    });

    const highlight = await newHighlight.save();
    res.json(highlight);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
};


// Get all highlights for the logged-in user
exports.getHighlights = async (req, res) => {
  try {
    const highlights = await Highlight.find({ user: req.user.id })
      .populate('scripture') // Populate scripture field with details
      .sort({ dateAdded: -1 });

    res.json(highlights);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
};


// Delete a highlight
exports.deleteHighlight = async (req, res) => {
  try {
    const highlight = await Highlight.findById(req.params.id);

    if (!highlight) {
      return res.status(404).json({ msg: 'Highlight not found' });
    }

    // Ensure the highlight belongs to the logged-in user
    if (highlight.user.toString() !== req.user.id) {
      return res.status(401).json({ msg: 'User not authorized' });
    }

    await highlight.remove();
    res.json({ msg: 'Highlight removed' });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
};


[
  {
    "_id": "65374d24e31ad1b2a5d0d4a8",
    "user": "65374d24e31ad1b2a5d0d3f1",
    "scripture": [
      {
        "_id": "65374ce31ad1b2a5d0d3a5",
        "book": 1,
        "chapter": 3,
        "verseNumbers": [16, 17]
      }
    ],
    "color": "blue",
    "dateAdded": "2024-10-24T12:45:56.123Z"
  }
]


