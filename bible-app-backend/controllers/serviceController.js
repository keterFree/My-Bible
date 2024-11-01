const mongoose = require('mongoose');
const Service = require('../models/Service');
const Sermon = require('../models/Sermon');
const Scripture = require('../models/Scripture');
const Devotion = require('../models/Devotion');

const createScriptures = async (scriptures) => {
    return await Promise.all(
        scriptures.map(async ({ book, chapter, verseNumbers }) => {
            let scripture = await Scripture.findOne({
                book,
                chapter,
                verseNumbers: { $all: verseNumbers },
            });

            if (!scripture) {
                scripture = new Scripture({ book, chapter, verseNumbers });
                await scripture.save();
            }
            return scripture._id;
        })
    );
};

const createSermons = async (sermons) => {
    return await Promise.all(
        sermons.map(async (sermon) => {
            const scriptureIds = await createScriptures(sermon.scriptures);
            // const points = sermon.notes;
            // console.log(`sermon notes: ${points}`)
            const newSermon = new Sermon({ ...sermon, scriptures: scriptureIds });
            await newSermon.save();
            return newSermon._id;
        })
    );
};

const createDevotions = async (devotions) => {
    return await Promise.all(
        devotions.map(async (devotion) => {
            const scriptureIds = await createScriptures(devotion.scriptures);
            const newDevotion = new Devotion({ ...devotion, scriptures: scriptureIds });
            await newDevotion.save();
            return newDevotion._id;
        })
    );
};

exports.createService = async (req, res) => {
    try {
        const { title, date, location, theme } = req.body;

        const service = new Service({ title, date, location, themes: [theme] });
        await service.save();

        res.status(201).json({ serviceId: service._id, title: title });
    } catch (error) {
        console.error(error.message);
        res.status(500).json({ message: `Failed to create service: ${error.message}` });
    }
};


// Create service with sermons and devotions using transactions
exports.createServiceWithDetails = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const { title, date, location, theme, sermons, devotions, images } = req.body;

        // Create sermons and devotions with their respective scriptures
        const sermonIds = await createSermons(sermons);
        const devotionIds = await createDevotions(devotions);

        const service = new Service({
            title,
            date,
            location,
            themes: [theme],
            sermons: sermonIds,
            devotions: devotionIds,
            images,
        });

        await service.save({ session });

        await session.commitTransaction();
        session.endSession();

        res.status(201).json({ serviceId: service._id });
    } catch (error) {
        await session.abortTransaction();
        session.endSession();
        console.error(`Service creation failed: ${error.message}`);
        res.status(500).json({ message: `Failed to create service: ${error.message}` });
    }
};

exports.updateServiceImages = async (req, res) => {
    try {
        const imageIds = req.body;
        const { serviceId } = req.params;

        console.log(`Adding ${req.body}`)
        const updatedService = await Service.findByIdAndUpdate(
            serviceId,
            { images: imageIds },
            { new: true }
        );

        if (!updatedService) {
            return res.status(404).json({ message: 'Service not found' });
        }

        res.status(200).json(updatedService);
    } catch (error) {
        res.status(500).json({ message: `Failed to update images: ${error.message}` });
    }
};

exports.updateServiceSermons = async (req, res) => {
    try {
        const sermon = req.body;
        const { serviceId } = req.params;
        console.log(`recieved sermon ${sermon['title']}`);
        const sermonIds = await createSermons([sermon]);
        console.log(`adding sermonIds ${sermonIds}`);
        const updatedService = await Service.findByIdAndUpdate(
            serviceId,
            { sermons: sermonIds },
            { new: true }
        );

        if (!updatedService) {
            return res.status(404).json({ message: 'Service not found' });
        }

        res.status(200).json(updatedService);
    } catch (error) {
        console.error(`Failed to update sermons: ${error.message}`);
        res.status(500).json({ message: `Failed to update sermons: ${error.message}` });
    }
};

exports.updateServiceDevotions = async (req, res) => {
    try {
        const devotions = req.body;
        const { serviceId } = req.params;

        const devotionIds = await createDevotions(devotions);

        const updatedService = await Service.findByIdAndUpdate(
            serviceId,
            { devotions: devotionIds },
            { new: true }
        );

        if (!updatedService) {
            return res.status(404).json({ message: 'Service not found' });
        }

        res.status(200).json(updatedService);
    } catch (error) {
        console.error(`Failed to update devotions: ${error.message}`);
        res.status(500).json({ message: `Failed to update devotions: ${error.message}` });
    }
};

// Get a single service by ID with populated fields
exports.getServiceById = async (req, res) => {
    try {
        const service = await Service.findById(req.params.id)
            .populate({
                path: 'sermons',
                populate: { path: 'scriptures' },
            })
            .populate({
                path: 'devotions',
                populate: { path: 'scriptures' },
            })
            .populate('images')
            .lean();

        if (!service) {
            return res.status(404).json({ message: 'Service not found' });
        }

        res.status(200).json(service);
    } catch (error) {
        console.error(`Failed to retrieve service: ${error.message}`);
        res.status(500).json({ message: `Failed to retrieve service: ${error.message}` });
    }
};

// Get all services with populated fields
exports.getAllServices = async (req, res) => {
    try {
        const services = await Service.find({});

        res.status(200).json(services);
    } catch (error) {
        console.error(`Failed to fetch services: ${error.message}`);
        res.status(500).json({ message: `Failed to fetch services: ${error.message}` });
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
                images: imageIds,
                sermons: sermonIds,
                devotions: devotionIds,
            },
            { new: true }
        );

        if (!updatedService) {
            return res.status(404).json({ message: 'Service not found' });
        }

        res.status(200).json(updatedService);
    } catch (error) {
        console.error(`Failed to update service: ${error.message}`);
        res.status(500).json({ message: `Failed to update service: ${error.message}` });
    }
};

// Delete a service
exports.deleteService = async (req, res) => {
    try {
        const deletedService = await Service.findByIdAndDelete(req.params.id);

        if (!deletedService) {
            return res.status(404).json({ message: 'Service not found' });
        }

        res.status(200).json({ message: 'Service deleted successfully' });
    } catch (error) {
        console.error(`Failed to delete service: ${error.message}`);
        res.status(500).json({ message: `Failed to delete service: ${error.message}` });
    }
};




// {
//     "title": "Sunday Service",
//         "date": "2024-10-27",
//             "location": "Main Hall",
//                 "theme": "Faith",
//                     "images": ["64f8d3f8b8f3e8d43f4c", "64f8d3f8b8f3e8d43f4d"],
//                         "devotions": [
//                             {
//                                 "title": "Morning Devotion",
//                                 "content": "Reflect on faith.",
//                                 "scriptures": [
//                                     { "book": 1, "chapter": 1, "verseNumbers": [1, 2, 3] },
//                                     { "book": 1, "chapter": 2, "verseNumbers": [4, 5] }
//                                 ]
//                             }
//                         ],
//                             "sermons": [
//                                 {
//                                     "title": "Living by Faith",
//                                     "speaker": "John Doe",
//                                     "notes": "A deeper look into faith.",
//                                     "scriptures": [
//                                         { "book": 2, "chapter": 3, "verseNumbers": [12, 13] },
//                                         { "book": 2, "chapter": 4, "verseNumbers": [14, 15] }
//                                     ]
//                                 }
//                             ]
// }
