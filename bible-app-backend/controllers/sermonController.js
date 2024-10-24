const Sermon = require('../models/Sermon');
const Scripture = require('../models/Scripture');

// Create a new sermon
exports.createSermon = async (req, res) => {
    try {
        const { title, speaker, notes, scriptureIds, serviceId } = req.body;

        const sermon = new Sermon({
            title,
            speaker,
            notes,
            scriptures: scriptureIds,  // Expecting an array of Scripture ObjectIds
            service: serviceId
        });

        await sermon.save();
        res.status(201).json(sermon);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get a single sermon by ID
exports.getSermonById = async (req, res) => {
    try {
        const sermon = await Sermon.findById(req.params.id)
            .populate('scriptures') // Populate the scripture objects
            .populate('service');  // Optionally populate the service details

        if (!sermon) {
            return res.status(404).json({ message: 'Sermon not found' });
        }

        res.status(200).json(sermon);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get all sermons
exports.getAllSermons = async (req, res) => {
    try {
        const sermons = await Sermon.find({})
            .populate('scriptures') // Populate scripture details
            .populate('service'); // Optionally populate service details
        res.status(200).json(sermons);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Update a sermon
exports.updateSermon = async (req, res) => {
    try {
        const { title, speaker, notes, scriptureIds, serviceId } = req.body;

        const updatedSermon = await Sermon.findByIdAndUpdate(
            req.params.id,
            { title, speaker, notes, scriptures: scriptureIds, service: serviceId },
            { new: true }
        );

        if (!updatedSermon) {
            return res.status(404).json({ message: 'Sermon not found' });
        }

        res.status(200).json(updatedSermon);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Delete a sermon
exports.deleteSermon = async (req, res) => {
    try {
        await Sermon.findByIdAndDelete(req.params.id);
        res.status(200).json({ message: 'Sermon deleted' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
