const mongoose = require('mongoose');

const HighlightSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  scripture: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Scripture', // Reference to the Scripture model
    },
  ],
  color: { type: String, default: 'yellow' },
  dateAdded: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Highlight', HighlightSchema);
