const Service = require('../models/Service');
const Sermon = require('../models/Sermon');
const Scripture = require('../models/Scripture');
const Devotion = require('../models/Devotion');

// Helper function to create scriptures and return their IDs
const createScriptures = async (scriptures) => {
    const scriptureIds = await Promise.all(
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
    return scriptureIds;
};

// Create a new service
exports.createService = async (req, res) => {
    try {
        const { title, date, location, theme, images, devotions, sermons } = req.body;

        const devotionPromises = devotions.map(async (devotion) => {
            const scriptureIds = await createScriptures(devotion.scriptures);
            const newDevotion = new Devotion({ ...devotion, scriptures: scriptureIds });
            await newDevotion.save();
            return newDevotion._id;
        });

        const sermonPromises = sermons.map(async (sermon) => {
            const scriptureIds = await createScriptures(sermon.scriptures);
            const newSermon = new Sermon({ ...sermon, scriptures: scriptureIds });
            await newSermon.save();
            return newSermon._id;
        });

        const [devotionIds, sermonIds] = await Promise.all([
            Promise.all(devotionPromises),
            Promise.all(sermonPromises),
        ]);

        const service = new Service({
            title,
            date,
            location,
            themes: [theme],
            images,
            devotions: devotionIds,
            sermons: sermonIds,
        });

        await service.save();
        res.status(201).json(service);
    } catch (error) {
        console.error(error.message);
        res.status(500).json({ message: `Failed to create service: ${error.message}` });
    }
};



// Get a single service by ID
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
            .populate('images');

        if (!service) {
            return res.status(404).json({ message: 'Service not found' });
        }

        res.status(200).json(service);
    } catch (error) {
        res.status(500).json({ message: `Failed to retrieve service: ${error.message}` });
    }
};


// Get all services
exports.getAllServices = async (req, res) => {
    try {
        const services = await Service.find({})
            .populate({
                path: 'sermons',
                populate: { path: 'scriptures' },
            })
            .populate({
                path: 'devotions',
                populate: { path: 'scriptures' },
            })
            .populate('images');

        res.status(200).json(services);
    } catch (error) {
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
        res.status(500).json({ message: `Failed to update service: ${error.message}` });
    }
};


exports.deleteService = async (req, res) => {
    try {
        const deletedService = await Service.findByIdAndDelete(req.params.id);

        if (!deletedService) {
            return res.status(404).json({ message: 'Service not found' });
        }

        res.status(200).json({ message: 'Service deleted successfully' });
    } catch (error) {
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
