const Devotion = require('../models/Devotion');
const Scripture = require('../models/Scripture');

// Create a new devotion
exports.createDevotion = async (req, res) => {
    try {
        const { title, content, scriptureIds, serviceId } = req.body;

        const devotion = new Devotion({
            title,
            content,
            scriptures: scriptureIds,  // Expecting an array of Scripture ObjectIds
            service: serviceId
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
            .populate('service');  // Optionally populate the service details

        if (!devotion) {
            return res.status(404).json({ message: 'Devotion not found' });
        }

        res.status(200).json(devotion);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Update a devotion
exports.updateDevotion = async (req, res) => {
    try {
        const { title, content, scriptureIds, serviceId } = req.body;

        const updatedDevotion = await Devotion.findByIdAndUpdate(
            req.params.id,
            { title, content, scriptures: scriptureIds, service: serviceId },
            { new: true }
        );

        if (!updatedDevotion) {
            return res.status(404).json({ message: 'Devotion not found' });
        }

        res.status(200).json(updatedDevotion);
    } catch (error) {
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
