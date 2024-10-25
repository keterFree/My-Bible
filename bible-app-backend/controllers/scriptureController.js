const Scripture = require('../models/Scripture');

// Create a new scripture
exports.createScripture = async (req, res) => {
    try {
        const { book, chapter, verseNumbers } = req.body;

        // Sort the verseNumbers array in descending order
        const sortedVerseNumbers = verseNumbers.sort((a, b) => b - a);

        const scripture = new Scripture({
            book,
            chapter,
            verseNumbers: sortedVerseNumbers // Use the sorted array
        });

        await scripture.save();
        res.status(201).json(scripture);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get a single scripture by ID
exports.getScriptureById = async (req, res) => {
    try {
        const scripture = await Scripture.findById(req.params.id);

        if (!scripture) {
            return res.status(404).json({ message: 'Scripture not found' });
        }

        res.status(200).json(scripture);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get all scriptures
exports.getAllScriptures = async (req, res) => {
    try {
        const scriptures = await Scripture.find({});
        res.status(200).json(scriptures);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Update a scripture
exports.updateScripture = async (req, res) => {
    try {
        const { book, chapter, verseNumbers } = req.body;

        const updatedScripture = await Scripture.findByIdAndUpdate(
            req.params.id,
            { book, chapter, verseNumbers },
            { new: true }
        );

        if (!updatedScripture) {
            return res.status(404).json({ message: 'Scripture not found' });
        }

        res.status(200).json(updatedScripture);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Delete a scripture
exports.deleteScripture = async (req, res) => {
    try {
        await Scripture.findByIdAndDelete(req.params.id);
        res.status(200).json({ message: 'Scripture deleted' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
