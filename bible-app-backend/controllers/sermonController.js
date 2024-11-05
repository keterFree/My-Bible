const Sermon = require('../models/Sermon');
const Scripture = require('../models/Scripture');


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

// Create a new sermon
exports.createSermon = async (req, res) => {
    try {
        const { title, speaker, notes, scriptures } = req.body;

        // Array to store scripture IDs
        const scriptureIds = [];

        // Create or retrieve scripture entries
        for (const scripture of scriptures) {
            const { book, chapter, verseNumbers } = scripture;

            // Check if a matching scripture exists
            let existingScripture = await Scripture.findOne({
                book,
                chapter,
                verseNumbers: { $all: verseNumbers },
            });

            // If not, create a new scripture entry
            if (!existingScripture) {
                existingScripture = new Scripture({ book, chapter, verseNumbers });
                await existingScripture.save();
            }

            scriptureIds.push(existingScripture._id); // Collect the scripture ID
        }

        // Create a new sermon using the scripture IDs
        const sermon = new Sermon({
            title,
            speaker,
            notes,
            scriptures: scriptureIds,
        });

        await sermon.save(); // Save the sermon to the database
        res.status(201).json(sermon); // Respond with the created sermon
    } catch (error) {
        console.error(error.message);
        res.status(500).json({ message: 'Server Error' });
    }
};

// Get a single sermon by ID
exports.getSermonById = async (req, res) => {
    try {
        const sermon = await Sermon.findById(req.params.id)
            .populate('scriptures'); // Populate the scripture objects

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
            .populate('scriptures'); // Populate scripture details
        res.status(200).json(sermons);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Update a sermon
exports.updateSermon = async (req, res) => {
    try {
        const { title, speaker, notes, scriptures } = req.body;
        const scriptureIds = await createScriptures(scriptures);
        const uniqueScriptureIds = [...new Set(scriptureIds)];

        const updatedSermon = await Sermon.findByIdAndUpdate(
            req.params.id,
            { title, speaker, notes, scriptures: uniqueScriptureIds },
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
