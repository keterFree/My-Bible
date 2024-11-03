const multer = require('multer');
const Image = require('../models/Image');
const Service = require('../models/Service');

// Configure Multer for in-memory storage
const storage = multer.memoryStorage();
const upload = multer({ storage });

// Upload Image Endpoint
exports.uploadImage = async (req, res) => {
    try {
        const file = req.file; // Image uploaded as 'file'

        if (!file) {
            return res.status(400).json({ message: 'No file uploaded' });
        }

        // Create a new Image document
        const image = new Image({
            filename: file.originalname,
            imageData: file.buffer, // Store binary data
            contentType: file.mimetype,
            fileSize: file.size,
        });

        const savedImage = await image.save(); // Save the image to MongoDB

        // Return the saved image's _id in the response
        res.status(201).json({ message: 'Image uploaded successfully', _id: savedImage._id, name: savedImage.filename });
    } catch (error) {
        console.log(error);
        res.status(500).json({ message: error.message });
    }
};

// Middleware to handle file uploads
exports.uploadMiddleware = upload.single('file');


exports.getImageById = async (req, res) => {
    try {
        const image = await Image.findById(req.params.id);

        if (!image) {
            return res.status(404).json({ message: 'Image not found' });
        }

        // Set the appropriate Content-Type
        res.set('Content-Type', image.contentType);
        res.send(image.imageData); // Send the binary data
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};


// Get all images
exports.getAllImages = async (req, res) => {
    try {
        const images = await Image.find({});
        res.status(200).json(images);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Delete an image by ID
exports.deleteImage = async (req, res) => {
    try {
        const imageId = req.params.id;
        const image = await Image.findById(imageId);

        if (!image) {
            return res.status(404).json({ message: 'Image not found' });
        }

        // Remove imageId from any Service that contains it
        await Service.updateMany(
            { images: imageId },
            { $pull: { images: imageId } }
        );

        // Delete the image document
        await Image.findByIdAndDelete(imageId);
        res.status(200).json({ message: 'Image deleted successfully and removed from associated services' });
    } catch (error) {
        res.status(500).json({ message: `Failed to delete image: ${error.message}` });
    }
};


