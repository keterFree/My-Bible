const express = require('express');
const router = express.Router();
const {
    createSermon,
    getSermonById,
    getAllSermons,
    updateSermon,
    deleteSermon
} = require('../controllers/sermonController'); // Ensure this path is correct

// Define routes
router.post('/', createSermon);
router.get('/:id', getSermonById);
router.get('/', getAllSermons);
router.put('/:id', updateSermon);
router.delete('/:id', deleteSermon);

module.exports = router;
