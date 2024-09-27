// models/Bookmark.js

const mongoose = require('mongoose');

const BookmarkSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  book: { type: Number, required: true },
  chapter: { type: Number, required: true },
  verse: { type: Number, required: true },
  dateAdded: { type: Date, default: Date.now },
  note: { type: String, required: false },
});

module.exports = mongoose.model('Bookmark', BookmarkSchema);
