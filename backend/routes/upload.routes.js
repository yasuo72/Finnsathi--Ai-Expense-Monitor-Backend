const express = require('express');
const router = express.Router();
const { uploadFile, deleteFile } = require('../controllers/upload.controller');
const { protect } = require('../middleware/auth');

// All routes are protected
router.use(protect);

// Upload routes
router.post('/', uploadFile);
router.delete('/:fileName', deleteFile);

module.exports = router;
