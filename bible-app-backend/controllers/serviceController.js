const Service = require('../models/Service');
const Image = require('../models/Image');

// Create a new service
exports.createService = async (req, res) => {
    try {
        const { title, date, location, themes, imageIds, sermonIds, devotionIds } = req.body;

        const service = new Service({
            title,
            date,
            location,
            themes,
            images: imageIds,  // Array of Image ObjectIds
            sermons: sermonIds,  // Array of Sermon ObjectIds
            devotions: devotionIds  // Array of Devotion ObjectIds
        });

        await service.save();
        res.status(201).json(service);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get a single service by ID
exports.getServiceById = async (req, res) => {
    try {
        const service = await Service.findById(req.params.id)
            .populate('sermons')
            .populate('devotions')
            .populate('images');  // Populate the images

        if (!service) {
            return res.status(404).json({ message: 'Service not found' });
        }

        res.status(200).json(service);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get all services
exports.getAllServices = async (req, res) => {
    try {
        const services = await Service.find({})
            .populate('sermons')
            .populate('devotions')
            .populate('images');
        res.status(200).json(services);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Update a service
exports.updateService = async (req, res) => {
    try {
        const { title, date, location, themes, imageIds, sermonIds, devotionIds } = req.body;

        const updatedService = await Service.findByIdAndUpdate(
            req.params.id,
            {
                title,
                date,
                location,
                themes,
                images: imageIds,  // Array of Image ObjectIds
                sermons: sermonIds,
                devotions: devotionIds
            },
            { new: true }
        );

        if (!updatedService) {
            return res.status(404).json({ message: 'Service not found' });
        }

        res.status(200).json(updatedService);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Delete a service
exports.deleteService = async (req, res) => {
    try {
        await Service.findByIdAndDelete(req.params.id);
        res.status(200).json({ message: 'Service deleted' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
