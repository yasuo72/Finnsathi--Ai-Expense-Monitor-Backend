const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

// @desc    Upload file
// @route   POST /api/upload
// @access  Private
exports.uploadFile = async (req, res) => {
  try {
    if (!req.files || Object.keys(req.files).length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No files were uploaded'
      });
    }

    const file = req.files.file;
    const userId = req.user.id;
    
    // Create user-specific directory if it doesn't exist
    const userDir = path.join(__dirname, '../public/uploads', userId.toString());
    if (!fs.existsSync(userDir)) {
      fs.mkdirSync(userDir, { recursive: true });
    }
    
    // Generate unique filename to prevent collisions
    const fileExtension = path.extname(file.name);
    const randomString = crypto.randomBytes(8).toString('hex');
    const fileName = `${Date.now()}-${randomString}${fileExtension}`;
    const filePath = path.join(userDir, fileName);
    
    // Move file to the uploads directory
    file.mv(filePath, async (err) => {
      if (err) {
        console.error('File upload error:', err);
        return res.status(500).json({
          success: false,
          message: 'Error uploading file',
          error: err.message
        });
      }
      
      // Return the relative path for frontend use
      const relativePath = `/uploads/${userId}/${fileName}`;
      
      res.status(200).json({
        success: true,
        filePath: relativePath,
        message: 'File uploaded successfully'
      });
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during file upload'
    });
  }
};

// @desc    Delete file
// @route   DELETE /api/upload/:fileName
// @access  Private
exports.deleteFile = async (req, res) => {
  try {
    const userId = req.user.id;
    const fileName = req.params.fileName;
    
    // Ensure filename is valid and doesn't contain path traversal attempts
    if (!fileName || fileName.includes('..') || fileName.includes('/')) {
      return res.status(400).json({
        success: false,
        message: 'Invalid file name'
      });
    }
    
    const filePath = path.join(__dirname, '../public/uploads', userId.toString(), fileName);
    
    // Check if file exists
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({
        success: false,
        message: 'File not found'
      });
    }
    
    // Delete file
    fs.unlinkSync(filePath);
    
    res.status(200).json({
      success: true,
      message: 'File deleted successfully'
    });
  } catch (error) {
    console.error('File deletion error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during file deletion'
    });
  }
};
