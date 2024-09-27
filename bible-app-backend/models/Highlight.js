// models/Highlight.js

const mongoose = require('mongoose');

const HighlightSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  book: { type: Number, required: true },
  chapter: { type: Number, required: true },
  verse: { type: Number, required: true },
  color: { type: String, default: 'yellow' },
  dateAdded: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Highlight', HighlightSchema);
