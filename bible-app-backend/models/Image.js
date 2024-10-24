const mongoose = require('mongoose');

const ImageSchema = new mongoose.Schema({
    filename: {
        type: String,
        required: true // The original filename of the image
    },
    imageUrl: {
        type: String,
        required: true // The Firebase Storage URL for the image
    },
    fileSize: {
        type: Number, // Size of the file in bytes
    },
    uploadDate: {
        type: Date,
        default: Date.now // Automatically set the upload date
    },
    service: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Service', // Reference to the related service
        required: true
    }
}, { timestamps: true });

module.exports = mongoose.model('Image', ImageSchema);
