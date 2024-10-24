const mongoose = require('mongoose');

const ServiceSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true
    },
    date: {
        type: Date,
        required: true
    },
    location: {
        type: String
    },
    themes: [String], // Array of key themes
    images: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Image'  // Reference to Image schema
    }],
    sermons: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Sermon'  // Reference to Sermon schema
    }],
    devotions: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Devotion'  // Reference to Devotion schema
    }]
}, { timestamps: true });

module.exports = mongoose.model('Service', ServiceSchema);
