const mongoose = require('mongoose');

// Import the Scripture model
const Scripture = require('./Scripture');

// Sermon Schema
const SermonSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true
    },
    speaker: {
        type: String,
        required: true
    },
    notes: {
        type: [String]
    },
    scriptures: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Scripture'  // Reference to the Scripture model
    }],
}, { timestamps: true });

module.exports = mongoose.model('Sermon', SermonSchema);
