const mongoose = require('mongoose');

const shopOrderSchema = new mongoose.Schema({
  orderId: {
    type: String,
    unique: true,
    required: true,
  },
  shopId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Shop',
    required: true,
  },
  userId: {
    type: String,
    required: true,
  },
  customer: {
    id: String,
    name: String,
    email: String,
    phone: String,
    avatarUrl: String,
  },
  items: [
    {
      menuItemId: mongoose.Schema.Types.ObjectId,
      name: String,
      price: Number,
      quantity: Number,
      customizations: mongoose.Schema.Types.Mixed,
      specialInstructions: String,
      totalPrice: Number,
    },
  ],
  totalAmount: {
    type: Number,
    required: true,
  },
  deliveryFee: {
    type: Number,
    default: 0,
  },
  discount: {
    type: Number,
    default: 0,
  },
  finalAmount: {
    type: Number,
    required: true,
  },
  deliveryAddress: {
    type: String,
    required: true,
  },
  deliveryCoordinates: {
    latitude: Number,
    longitude: Number,
  },
  status: {
    type: String,
    enum: ['placed', 'confirmed', 'preparing', 'outForDelivery', 'delivered', 'cancelled'],
    default: 'placed',
  },
  paymentMethod: {
    type: String,
    enum: ['card', 'upi', 'wallet', 'cashOnDelivery'],
    required: true,
  },
  paymentStatus: {
    type: String,
    enum: ['pending', 'completed', 'failed'],
    default: 'pending',
  },
  trackingId: String,
  estimatedDeliveryTime: Date,
  actualDeliveryTime: Date,
  rating: {
    type: Number,
    min: 1,
    max: 5,
  },
  review: String,
  reviewImages: [String],
  cancelReason: String,
  cancelledBy: {
    type: String,
    enum: ['user', 'shop', 'admin'],
  },
  notes: String,
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('ShopOrder', shopOrderSchema);
