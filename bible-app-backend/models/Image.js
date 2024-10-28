const mongoose = require('mongoose');

const ImageSchema = new mongoose.Schema({
    filename: {
        type: String,
        required: true,
    },
    imageData: {
        type: Buffer, // Store image binary data
        required: true,
    },
    contentType: {
        type: String, // Store MIME type (e.g., 'image/png', 'image/jpeg')
        required: true,
    },
    fileSize: {
        type: Number, // Store file size in bytes
    },
    uploadDate: {
        type: Date,
        default: Date.now, // Automatically set the upload date
    }
}, { timestamps: true });

module.exports = mongoose.model('Image', ImageSchema);
