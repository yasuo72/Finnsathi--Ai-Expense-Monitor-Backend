const MenuItem = require('../models/MenuItem');
const Shop = require('../models/Shop');
const cloudinary = require('cloudinary').v2;
const streamifier = require('streamifier');

// Add menu item
exports.addMenuItem = async (req, res) => {
  try {
    const { name, price, description, category, ingredients, isVegetarian, prepTimeMinutes, customizations } = req.body;

    const shop = await Shop.findOne({ ownerId: req.user.id });
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found' });
    }

    const menuItem = new MenuItem({
      shopId: shop._id,
      name,
      price,
      description,
      category,
      ingredients: ingredients || [],
      isVegetarian: isVegetarian || false,
      prepTimeMinutes: prepTimeMinutes || 15,
      customizations: customizations || [],
    });

    await menuItem.save();
    res.status(201).json({ message: 'Menu item added successfully', menuItem });
  } catch (error) {
    res.status(500).json({ message: 'Error adding menu item', error: error.message });
  }
};

// Get shop menu
exports.getShopMenu = async (req, res) => {
  try {
    const shop = await Shop.findOne({ ownerId: req.user.id });
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found' });
    }

    const menuItems = await MenuItem.find({ shopId: shop._id });
    res.json(menuItems);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching menu', error: error.message });
  }
};

// Update menu item
exports.updateMenuItem = async (req, res) => {
  try {
    const { itemId } = req.params;
    const shop = await Shop.findOne({ ownerId: req.user.id });
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found' });
    }

    const menuItem = await MenuItem.findOne({ _id: itemId, shopId: shop._id });
    if (!menuItem) {
      return res.status(404).json({ message: 'Menu item not found' });
    }

    const updates = req.body;
    Object.assign(menuItem, updates);
    menuItem.updatedAt = new Date();
    await menuItem.save();

    res.json({ message: 'Menu item updated successfully', menuItem });
  } catch (error) {
    res.status(500).json({ message: 'Error updating menu item', error: error.message });
  }
};

// Delete menu item
exports.deleteMenuItem = async (req, res) => {
  try {
    const { itemId } = req.params;
    const shop = await Shop.findOne({ ownerId: req.user.id });
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found' });
    }

    const menuItem = await MenuItem.findOneAndDelete({ _id: itemId, shopId: shop._id });
    if (!menuItem) {
      return res.status(404).json({ message: 'Menu item not found' });
    }

    res.json({ message: 'Menu item deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting menu item', error: error.message });
  }
};

// Upload menu item image
exports.uploadMenuItemImage = async (req, res) => {
  try {
    const { itemId } = req.params;

    if (!req.files || !req.files.image) {
      return res.status(400).json({ message: 'No image provided' });
    }

    const shop = await Shop.findOne({ ownerId: req.user.id });
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found' });
    }

    const menuItem = await MenuItem.findOne({ _id: itemId, shopId: shop._id });
    if (!menuItem) {
      return res.status(404).json({ message: 'Menu item not found' });
    }

    const uploadStream = cloudinary.uploader.upload_stream(
      { folder: 'finnsathi/menu-items' },
      async (error, result) => {
        if (error) {
          return res.status(500).json({ message: 'Error uploading image', error: error.message });
        }

        menuItem.imageUrl = result.secure_url;
        await menuItem.save();
        res.json({ message: 'Image uploaded successfully', imageUrl: result.secure_url });
      }
    );

    streamifier.createReadStream(req.files.image.data).pipe(uploadStream);
  } catch (error) {
    res.status(500).json({ message: 'Error uploading image', error: error.message });
  }
};

// Toggle availability
exports.toggleAvailability = async (req, res) => {
  try {
    const { itemId } = req.params;
    const shop = await Shop.findOne({ ownerId: req.user.id });
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found' });
    }

    const menuItem = await MenuItem.findOne({ _id: itemId, shopId: shop._id });
    if (!menuItem) {
      return res.status(404).json({ message: 'Menu item not found' });
    }

    menuItem.isAvailable = !menuItem.isAvailable;
    await menuItem.save();

    res.json({ message: 'Availability updated', isAvailable: menuItem.isAvailable });
  } catch (error) {
    res.status(500).json({ message: 'Error updating availability', error: error.message });
  }
};

// Get menu by category
exports.getMenuByCategory = async (req, res) => {
  try {
    const { category } = req.query;
    const shop = await Shop.findOne({ ownerId: req.user.id });
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found' });
    }

    let query = { shopId: shop._id };
    if (category) {
      query.category = category;
    }

    const menuItems = await MenuItem.find(query);
    res.json(menuItems);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching menu', error: error.message });
  }
};
