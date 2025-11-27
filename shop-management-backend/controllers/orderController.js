const ShopOrder = require('../models/ShopOrder');
const Shop = require('../models/Shop');
const MenuItem = require('../models/MenuItem');

// Get shop orders
exports.getShopOrders = async (req, res) => {
  try {
    const { status, sortBy, page = 1, limit = 20 } = req.query;
    const shop = await Shop.findOne({ ownerId: req.user.id });
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found' });
    }

    let query = { shopId: shop._id };
    if (status) {
      query.status = status;
    }

    let orders = await ShopOrder.find(query)
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .sort({ createdAt: -1 });

    const total = await ShopOrder.countDocuments(query);

    res.json({
      orders,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching orders', error: error.message });
  }
};

// Get order details
exports.getOrderDetails = async (req, res) => {
  try {
    const { orderId } = req.params;
    const shop = await Shop.findOne({ ownerId: req.user.id });
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found' });
    }

    const order = await ShopOrder.findOne({ _id: orderId, shopId: shop._id });
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    res.json(order);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching order', error: error.message });
  }
};

// Update order status
exports.updateOrderStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status } = req.body;
    const shop = await Shop.findOne({ ownerId: req.user.id });
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found' });
    }

    const validStatuses = ['placed', 'confirmed', 'preparing', 'outForDelivery', 'delivered', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    const order = await ShopOrder.findOne({ _id: orderId, shopId: shop._id });
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    order.status = status;
    if (status === 'delivered') {
      order.actualDeliveryTime = new Date();
    }
    order.updatedAt = new Date();
    await order.save();

    res.json({ message: 'Order status updated', order });
  } catch (error) {
    res.status(500).json({ message: 'Error updating order', error: error.message });
  }
};

// Cancel order
exports.cancelOrder = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { reason } = req.body;
    const shop = await Shop.findOne({ ownerId: req.user.id });
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found' });
    }

    const order = await ShopOrder.findOne({ _id: orderId, shopId: shop._id });
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    if (['delivered', 'cancelled'].includes(order.status)) {
      return res.status(400).json({ message: 'Cannot cancel this order' });
    }

    order.status = 'cancelled';
    order.cancelReason = reason;
    order.cancelledBy = 'shop';
    order.updatedAt = new Date();
    await order.save();

    res.json({ message: 'Order cancelled', order });
  } catch (error) {
    res.status(500).json({ message: 'Error cancelling order', error: error.message });
  }
};

// Get order statistics
exports.getOrderStats = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const shop = await Shop.findOne({ ownerId: req.user.id });
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found' });
    }

    let query = { shopId: shop._id };
    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) query.createdAt.$gte = new Date(startDate);
      if (endDate) query.createdAt.$lte = new Date(endDate);
    }

    const orders = await ShopOrder.find(query);

    const stats = {
      totalOrders: orders.length,
      totalRevenue: orders.reduce((sum, o) => sum + o.finalAmount, 0),
      averageOrderValue: orders.length > 0 ? orders.reduce((sum, o) => sum + o.finalAmount, 0) / orders.length : 0,
      byStatus: {
        placed: orders.filter(o => o.status === 'placed').length,
        confirmed: orders.filter(o => o.status === 'confirmed').length,
        preparing: orders.filter(o => o.status === 'preparing').length,
        outForDelivery: orders.filter(o => o.status === 'outForDelivery').length,
        delivered: orders.filter(o => o.status === 'delivered').length,
        cancelled: orders.filter(o => o.status === 'cancelled').length,
      },
    };

    res.json(stats);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching stats', error: error.message });
  }
};

// Create order from FinSathi app (customer-facing)
exports.createOrderFromApp = async (req, res) => {
  try {
    const {
      shopId,
      items,
      deliveryAddress,
      paymentMethod,
      notes,
      deliveryCoordinates,
      customer,
    } = req.body;

    if (!shopId || !Array.isArray(items) || items.length === 0 || !deliveryAddress || !paymentMethod) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const shop = await Shop.findById(shopId);
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found' });
    }

    let totalAmount = 0;

    const orderItems = [];
    for (const item of items) {
      const menuItemId = item.menuItemId || item.menuItem || item.id;
      const quantity = item.quantity || 1;
      const price = item.price || 0;

      const itemTotal = typeof item.totalPrice === 'number'
        ? item.totalPrice
        : price * quantity;

      totalAmount += itemTotal;

      orderItems.push({
        menuItemId,
        name: item.name,
        price,
        quantity,
        customizations: item.customizations || null,
        specialInstructions: item.specialInstructions || '',
        totalPrice: itemTotal,
      });
    }

    const deliveryFee = typeof shop.deliveryFee === 'number' ? shop.deliveryFee : 0;
    const discount = 0;
    const finalAmount = totalAmount + deliveryFee - discount;

    const order = await ShopOrder.create({
      orderId: `ORD-${Date.now()}`,
      shopId: shop._id,
      userId: (req.user && req.user.id) || 'anonymous',
      customer: customer || {
        id: (req.user && (req.user.id || req.user._id)) || undefined,
        name: (req.user && req.user.name) || undefined,
        email: (req.user && req.user.email) || undefined,
        phone: (req.user && (req.user.phone || req.user.mobile)) || undefined,
        avatarUrl: (req.user && req.user.avatarUrl) || undefined,
      },
      items: orderItems,
      totalAmount,
      deliveryFee,
      discount,
      finalAmount,
      deliveryAddress,
      deliveryCoordinates: deliveryCoordinates || undefined,
      status: 'placed',
      paymentMethod,
      paymentStatus:
        paymentMethod === 'cashOnDelivery' ? 'pending' : 'completed',
      notes,
    });

    res.status(201).json(order);
  } catch (error) {
    res.status(500).json({ message: 'Error creating order', error: error.message });
  }
};

// Get orders for the logged-in user (customer-facing)
exports.getUserOrders = async (req, res) => {
  try {
    const userId = req.user && req.user.id;
    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const orders = await ShopOrder.find({ userId }).sort({ createdAt: -1 });
    res.json(orders);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching user orders', error: error.message });
  }
};

// Admin: get all orders across all shops
exports.getAllOrdersAdmin = async (req, res) => {
  try {
    const { status, page = 1, limit = 50, shopId } = req.query;

    const query = {};
    if (status && status !== 'all') {
      query.status = status;
    }
    if (shopId) {
      query.shopId = shopId;
    }

    const pageNumber = parseInt(page, 10) || 1;
    const limitNumber = parseInt(limit, 10) || 50;
    const skip = (pageNumber - 1) * limitNumber;

    const orders = await ShopOrder.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNumber)
      .lean();

    const total = await ShopOrder.countDocuments(query);

    // Attach basic shop info
    const shopIds = [...new Set(orders.map((o) => o.shopId).filter(Boolean))];
    const shops = await Shop.find({ _id: { $in: shopIds } }).select('name location');
    const shopsById = {};
    shops.forEach((s) => {
      shopsById[s._id.toString()] = s;
    });

    const enrichedOrders = orders.map((order) => ({
      ...order,
      shop: shopsById[order.shopId?.toString()] || null,
    }));

    res.json({
      orders: enrichedOrders,
      pagination: {
        page: pageNumber,
        limit: limitNumber,
        total,
        pages: Math.ceil(total / limitNumber),
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching admin orders', error: error.message });
  }
};

// Rate an order (customer-facing)
exports.rateOrder = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { rating, review } = req.body;
    const userId = req.user && req.user.id;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({ message: 'Rating must be between 1 and 5' });
    }

    // The FinSathi app uses the business orderId field (e.g. 'ORD-123...')
    // when calling this endpoint, not the MongoDB _id. Attempting to cast
    // 'ORD-...' into an ObjectId throws a CastError and results in HTTP 500.
    // So we look up the order purely by userId + orderId.
    const order = await ShopOrder.findOne({
      userId,
      orderId,
    });
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    order.rating = rating;
    order.review = review || order.review;
    order.updatedAt = new Date();
    await order.save();

    // Recalculate shop rating based on all rated orders for this shop
    if (order.shopId) {
      const ratedOrders = await ShopOrder.find({
        shopId: order.shopId,
        rating: { $exists: true, $ne: null },
      });

      if (ratedOrders.length > 0) {
        const totalRating = ratedOrders.reduce(
          (sum, o) => sum + (o.rating || 0),
          0,
        );
        const averageRating = totalRating / ratedOrders.length;

        const shop = await Shop.findById(order.shopId);
        if (shop) {
          shop.rating = averageRating;
          shop.totalReviews = ratedOrders.length;
          if (shop.stats && typeof shop.stats === 'object') {
            shop.stats.averageRating = averageRating;
          }
          await shop.save();
        }

        return res.json({
          message: 'Order rated successfully',
          order,
          shopRating: averageRating,
          totalReviews: ratedOrders.length,
        });
      }
    }

    res.json({ message: 'Order rated successfully', order });
  } catch (error) {
    res.status(500).json({ message: 'Error rating order', error: error.message });
  }
};
