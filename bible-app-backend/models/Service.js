const mongoose = require('mongoose');

const ServiceSchema = new mongoose.Schema({
    title: { type: String, required: true },
    date: { type: Date, required: true },
    location: { type: String },
    themes: [String], // Array of key themes
    images: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Image' }],
    sermons: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Sermon' }],
    devotions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Devotion' }]
}, { timestamps: true });

module.exports = mongoose.model('Service', ServiceSchema);
