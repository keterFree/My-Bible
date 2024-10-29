const express = require('express');
const router = express.Router();
const serviceController = require('../controllers/serviceController');

router.post('/', serviceController.createService);
router.post('/detailedService', serviceController.createServiceWithDetails);
router.put('/images/:serviceId', serviceController.updateServiceImages);
router.put('/sermons/:serviceId', serviceController.updateServiceSermons);
router.put('/devotions/:serviceId', serviceController.updateServiceDevotions);
router.get('/:id', serviceController.getServiceById);
router.get('/', serviceController.getAllServices);
router.put('/:id', serviceController.updateService);
router.delete('/:id', serviceController.deleteService);

module.exports = router;
