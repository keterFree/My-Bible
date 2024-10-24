const express = require('express');
const router = express.Router();
const serviceController = require('../controllers/serviceController');

// Create a new service
router.post('/', serviceController.createService);

// Get a single service by ID
router.get('/:id', serviceController.getServiceById);

// Get all services
router.get('/', serviceController.getAllServices);

// Update a service by ID
router.put('/:id', serviceController.updateService);

// Delete a service by ID
router.delete('/:id', serviceController.deleteService);

module.exports = router;
