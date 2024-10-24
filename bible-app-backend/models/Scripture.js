const mongoose = require('mongoose');

// Scripture Object Schema
const ScriptureSchema = new mongoose.Schema({
    book: {
        type: Number,
        required: true
    },
    chapter: {
        type: Number,
        required: true
    },
    verseNumbers: [{
        type: Number,
        required: true
    }]
});

module.exports = mongoose.model('Scripture', ScriptureSchema);