const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true },
  password: { type: String, required: true },
  phone: { type: String, required: true, index: { unique: true } },
  bookmarks: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Bookmark' }],
  highlights: [{ verseId: String, color: String }],
  tier: { type: String, enum: ['leader', 'member'], default: 'member' },
  groups: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Group' }], // Groups the user is part of
  directMessages: [{ type: mongoose.Schema.Types.ObjectId, ref: 'DirectMessage' }] // One-on-one messages
});

module.exports = mongoose.model('User', UserSchema);
