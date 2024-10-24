const Image = require('../models/Image'); // Ensure this path is correct
const multer = require('multer'); // Assuming you're using multer for file uploads
const { v4: uuidv4 } = require('uuid'); // To generate unique IDs for files
const admin = require('firebase-admin'); // Firebase admin SDK for uploading images

// Configure Multer
const storage = multer.memoryStorage();
const upload = multer({ storage });

// Upload an image
exports.uploadImage = async (req, res) => {
    try {
        const file = req.file; // Assuming the image is uploaded as 'file'

        if (!file) {
            return res.status(400).json({ message: 'No file uploaded' });
        }

        // Generate a unique filename
        const filename = `${uuidv4()}_${file.originalname}`;

        // Upload to Firebase Storage
        const bucket = admin.storage().bucket(); // Ensure your Firebase Storage bucket is correctly configured
        const fileUpload = bucket.file(filename);

        // Upload file to Firebase
        await fileUpload.save(file.buffer, {
            metadata: {
                contentType: file.mimetype,
            },
            resumable: false,
        });

        const imageUrl = `https://storage.googleapis.com/${bucket.name}/${filename}`; // Construct the URL

        // Create a new image document
        const image = new Image({
            filename: file.originalname,
            imageUrl,
            fileSize: file.size,
            service: req.body.serviceId, // Ensure the service ID is sent in the body
        });

        await image.save();
        res.status(201).json(image);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get a single image by ID
exports.getImageById = async (req, res) => {
    try {
        const image = await Image.findById(req.params.id);

        if (!image) {
            return res.status(404).json({ message: 'Image not found' });
        }

        res.status(200).json(image);
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
        const image = await Image.findById(req.params.id);

        if (!image) {
            return res.status(404).json({ message: 'Image not found' });
        }

        // Delete from Firebase Storage
        const bucket = admin.storage().bucket();
        await bucket.file(image.filename).delete();

        // Delete from the database
        await Image.findByIdAndDelete(req.params.id);
        res.status(200).json({ message: 'Image deleted' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
