const mongoose = require('mongoose');
const UserSchema = new mongoose.Schema({
    name: { type: String, required: true },
    password: { type: String, required: true },
    phone: { type: String, required: true, index: { unique: true } },
    bookmarks: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Bookmark' }],
    highlights: [{ verseId: String, color: String }],
});
module.exports = mongoose.model('User', UserSchema);