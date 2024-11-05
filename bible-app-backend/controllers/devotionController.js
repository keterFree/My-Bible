const Devotion = require('../models/Devotion');
const Scripture = require('../models/Scripture');
const mongoose = require('mongoose');
const createScriptures = async (scriptures) => {
    return await Promise.all(
        scriptures.map(async (scripture) => {
            if (scripture._id) {
                // Check if `_id` is already an `ObjectId`
                if (typeof scripture._id === 'string' && mongoose.Types.ObjectId.isValid(scripture._id)) {
                    return new mongoose.Types.ObjectId(scripture._id);
                }
                return scripture._id;  // Already an ObjectId
            } else {
                // Search for or create the scripture document
                const { book, chapter, verseNumbers } = scripture;
                let foundScripture = await Scripture.findOne({
                    book,
                    chapter,
                    verseNumbers: { $all: verseNumbers },
                });

                if (!foundScripture) {
                    foundScripture = new Scripture({ book, chapter, verseNumbers });
                    await foundScripture.save();
                }

                return foundScripture._id;
            }
        })
    );
};


// Create a new devotion
exports.createDevotion = async (req, res) => {
    try {
        const { title, content, scriptureIds } = req.body;

        const devotion = new Devotion({
            title,
            content,
            scriptures: scriptureIds,  // Expecting an array of Scripture ObjectIds
        });

        await devotion.save();
        res.status(201).json(devotion);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get a single devotion by ID
exports.getDevotionById = async (req, res) => {
    try {
        const devotion = await Devotion.findById(req.params.id)
            .populate('scriptures') // Populate the scripture objects

        if (!devotion) {
            return res.status(404).json({ message: 'Devotion not found' });
        }

        res.status(200).json(devotion);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get all devotions
exports.getAllDevotions = async (req, res) => {
    try {
        const devotions = await Devotion.find({})
            .populate('scriptures') // Populate scripture details
        res.status(200).json(devotions);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.updateDevotion = async (req, res) => {
    try {
        const { title, content, scriptures } = req.body;

        // Create scriptures and get only their `_id`s
        const scriptureIds = await createScriptures(scriptures);
        const uniqueScriptureIds = [...new Set(scriptureIds)];
        console.log(`uniqueScriptureIds: ${uniqueScriptureIds} `)
        // Ensure only valid ObjectId format is used
        const validScriptureIds = uniqueScriptureIds.map(id => {
            if (mongoose.Types.ObjectId.isValid(id)) {
                return new mongoose.Types.ObjectId(id);
            } else {
                throw new Error(`Invalid ObjectId format for id: ${id}`);
            }
        });

        const updatedDevotion = await Devotion.findByIdAndUpdate(
            req.params.id,
            { title, content, scriptures: uniqueScriptureIds },
            { new: true }
        );

        if (!updatedDevotion) {
            return res.status(404).json({ message: 'Devotion not found' });
        }

        res.status(200).json(updatedDevotion);
    } catch (error) {
        console.error('Error updating devotion:', error.message);
        res.status(500).json({ message: error.message });
    }
};


// Delete a devotion
exports.deleteDevotion = async (req, res) => {
    try {
        await Devotion.findByIdAndDelete(req.params.id);
        res.status(200).json({ message: 'Devotion deleted' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
