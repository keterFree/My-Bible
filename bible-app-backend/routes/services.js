const express = require('express');
const router = express.Router();
const serviceController = require('../controllers/serviceController');
const verifyToken = require('../middleware/verifyToken'); // Authentication middleware
const ensureLeader = require('../middleware/ensureLeader'); // Ensure the user is a leader

router.post('/', verifyToken, ensureLeader, serviceController.createService);
router.post('/detailedService', verifyToken, ensureLeader, serviceController.createServiceWithDetails);
router.put('/images/:serviceId',  serviceController.updateServiceImages);
router.put('/sermons/:serviceId', serviceController.updateServiceSermons);
router.put('/devotions/:serviceId', serviceController.updateServiceDevotions);
router.get('/:id', serviceController.getServiceById);
router.get('/', serviceController.getAllServices);
router.put('/:id', verifyToken, ensureLeader, serviceController.updateService);
router.delete('/:id', verifyToken, ensureLeader, serviceController.deleteService);

module.exports = router;
