const Shop = require('../models/Shop');
const MenuItem = require('../models/MenuItem');
const ShopOrder = require('../models/ShopOrder');
const cloudinary = require('cloudinary').v2;
const streamifier = require('streamifier');

// Create shop
exports.createShop = async (req, res) => {
  try {
    const { name, description, location, phone, email, tags, operatingHours, deliveryTimeMinutes, deliveryFee } = req.body;
    const ownerId = req.user.id;

    // Check if owner already has a shop
    const existingShop = await Shop.findOne({ ownerId });
    if (existingShop) {
      return res.status(400).json({ message: 'You already have a shop' });
    }

    const shop = new Shop({
      ownerId,
      name,
      description,
      location,
      phone,
      email,
      tags: tags || [],
      operatingHours: operatingHours || {},
      deliveryTimeMinutes: deliveryTimeMinutes || 30,
      deliveryFee: deliveryFee || 0,
    });

    await shop.save();
    res.status(201).json({ message: 'Shop created successfully', shop });
  } catch (error) {
    res.status(500).json({ message: 'Error creating shop', error: error.message });
  }
};

// Get my shop
exports.getMyShop = async (req, res) => {
  try {
    const shop = await Shop.findOne({ ownerId: req.user.id });
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found' });
    }
    res.json(shop);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching shop', error: error.message });
  }
};

// Get reviews for a shop based on rated orders (public)
exports.getShopReviews = async (req, res) => {
  try {
    const { shopId } = req.params;

    const orders = await ShopOrder.find({
      shopId,
      rating: { $exists: true, $ne: null },
    }).sort({ updatedAt: -1 });

    const reviews = orders.map((order) => ({
      orderId: order.orderId || order._id,
      userId: order.userId,
      rating: order.rating,
      comment: order.review || '',
      date: order.updatedAt || order.createdAt,
      images: order.reviewImages || [],
    }));

    res.json(reviews);
  } catch (error) {
    res
      .status(500)
      .json({ message: 'Error fetching shop reviews', error: error.message });
  }
};

// Update shop
exports.updateShop = async (req, res) => {
  try {
    const shop = await Shop.findOne({ ownerId: req.user.id });
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found' });
    }

    const updates = req.body;
    Object.assign(shop, updates);
    shop.updatedAt = new Date();
    await shop.save();

    res.json({ message: 'Shop updated successfully', shop });
  } catch (error) {
    res.status(500).json({ message: 'Error updating shop', error: error.message });
  }
};

// Upload shop image
exports.uploadShopImage = async (req, res) => {
  try {
    console.log('Upload request received');
    console.log('Files:', req.files);
    console.log('User:', req.user);

    if (!req.files || !req.files.image) {
      console.log('No image file found');
      return res.status(400).json({ message: 'No image provided' });
    }

    const shop = await Shop.findOne({ ownerId: req.user.id });
    if (!shop) {
      console.log('Shop not found for user:', req.user.id);
      return res.status(404).json({ message: 'Shop not found' });
    }

    console.log('Uploading image to Cloudinary...');
    const file = req.files.image;
    const uploadOptions = { folder: 'finnsathi/shops' };

    if (file.tempFilePath) {
      cloudinary.uploader.upload(file.tempFilePath, uploadOptions, async (error, result) => {
        if (error) {
          console.error('Cloudinary upload error:', error);
          return res.status(500).json({ message: 'Error uploading image', error: error.message });
        }

        console.log('Image uploaded successfully:', result.secure_url);
        shop.imageUrl = result.secure_url;
        await shop.save();
        res.json({ success: true, message: 'Image uploaded successfully', imageUrl: result.secure_url });
      });
    } else {
      const uploadStream = cloudinary.uploader.upload_stream(
        uploadOptions,
        async (error, result) => {
          if (error) {
            console.error('Cloudinary upload error:', error);
            return res.status(500).json({ message: 'Error uploading image', error: error.message });
          }

          console.log('Image uploaded successfully:', result.secure_url);
          shop.imageUrl = result.secure_url;
          await shop.save();
          res.json({ success: true, message: 'Image uploaded successfully', imageUrl: result.secure_url });
        }
      );

      streamifier.createReadStream(file.data).pipe(uploadStream);
    }
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ message: 'Error uploading image', error: error.message });
  }
};

// Get shop statistics
exports.getShopStats = async (req, res) => {
  try {
    const shop = await Shop.findOne({ ownerId: req.user.id });
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found' });
    }

    const orders = await ShopOrder.find({ shopId: shop._id });
    const totalOrders = orders.length;
    const totalRevenue = orders.reduce((sum, order) => sum + order.finalAmount, 0);
    const averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

    const recentOrders = orders.slice(-10).reverse();
    const topItems = await MenuItem.find({ shopId: shop._id }).sort({ totalRatings: -1 }).limit(5);

    res.json({
      totalOrders,
      totalRevenue,
      averageOrderValue,
      recentOrders,
      topItems,
    });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching stats', error: error.message });
  }
};

// Toggle shop open/close status
exports.toggleShopStatus = async (req, res) => {
  try {
    const shop = await Shop.findOne({ ownerId: req.user.id });
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found' });
    }

    shop.isOpen = !shop.isOpen;
    await shop.save();

    res.json({ message: 'Shop status updated', isOpen: shop.isOpen });
  } catch (error) {
    res.status(500).json({ message: 'Error updating shop status', error: error.message });
  }
};

// Get all shops (public)
exports.getAllShops = async (req, res) => {
  try {
    const { search, tags, minRating, maxDeliveryTime, sortBy } = req.query;
    let query = {};

    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
        { tags: { $in: [new RegExp(search, 'i')] } }
      ];
    }

    if (tags) {
      const tagArray = tags.split(',');
      query.tags = { $in: tagArray };
    }

    if (minRating) {
      query.rating = { $gte: parseFloat(minRating) };
    }

    if (maxDeliveryTime) {
      query.deliveryTimeMinutes = { $lte: parseInt(maxDeliveryTime) };
    }

    let shops = await Shop.find(query).select('-operatingHours');

    if (sortBy === 'rating') {
      shops.sort((a, b) => b.rating - a.rating);
    } else if (sortBy === 'delivery') {
      shops.sort((a, b) => a.deliveryTimeMinutes - b.deliveryTimeMinutes);
    }

    res.json(shops);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching shops', error: error.message });
  }
};

// Get shop by ID (public)
exports.getShopById = async (req, res) => {
  try {
    const { shopId } = req.params;
    const shop = await Shop.findById(shopId);
    
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found' });
    }

    res.json(shop);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching shop', error: error.message });
  }
};
