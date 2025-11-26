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
    const { shopId, items, deliveryAddress, paymentMethod, notes, deliveryCoordinates } = req.body;

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
      items: orderItems,
      totalAmount,
      deliveryFee,
      discount,
      finalAmount,
      deliveryAddress,
      deliveryCoordinates: deliveryCoordinates || undefined,
      status: 'placed',
      paymentMethod,
      paymentStatus: paymentMethod === 'cashOnDelivery' ? 'pending' : 'completed',
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

    const order = await ShopOrder.findOne({ _id: orderId, userId });
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    order.rating = rating;
    order.review = review || order.review;
    order.updatedAt = new Date();
    await order.save();

    res.json({ message: 'Order rated successfully', order });
  } catch (error) {
    res.status(500).json({ message: 'Error rating order', error: error.message });
  }
};
