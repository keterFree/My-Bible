const mongoose = require('mongoose');

// Import the Scripture model
const Scripture = require('./Scripture');

// Devotion Schema
const DevotionSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true
    },
    content: {
        type: String,
        required: true
    },
    scriptures: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Scripture'  // Reference to the Scripture model
    }],
    service: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Service'  // Reference to the Service model
    }
}, { timestamps: true });

module.exports = mongoose.model('Devotion', DevotionSchema);
