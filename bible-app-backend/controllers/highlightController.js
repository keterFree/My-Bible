// controllers/highlightController.js

const Highlight = require('../models/Highlight');

// Add a new highlight
exports.addHighlight = async (req, res) => {
  const { book, chapter, verse, color } = req.body;
  try {
    const newHighlight = new Highlight({
      user: req.user.id,
      book,
      chapter,
      verse,
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
    const highlights = await Highlight.find({ user: req.user.id }).sort({ dateAdded: -1 });
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

    // Ensure user owns the highlight
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
