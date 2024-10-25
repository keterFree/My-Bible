const mongoose = require('mongoose');

const BookmarkSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  scripture: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Scripture', // Reference to the Scripture model
    },
  ],
  dateAdded: { type: Date, default: Date.now },
  note: { type: String },
});

module.exports = mongoose.model('Bookmark', BookmarkSchema);
