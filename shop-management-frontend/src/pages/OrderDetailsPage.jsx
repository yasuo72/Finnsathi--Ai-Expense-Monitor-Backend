import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Loader } from 'lucide-react';
import api from '../services/api';
import toast from 'react-hot-toast';

export default function OrderDetailsPage() {
  const { orderId } = useParams();
  const navigate = useNavigate();
  const [order, setOrder] = useState(null);
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState(false);

  useEffect(() => {
    fetchOrder();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [orderId]);

  const fetchOrder = async () => {
    try {
      const response = await api.get(`/orders/${orderId}`);
      setOrder(response.data);
    } catch (error) {
      toast.error('Failed to load order');
      navigate('/orders');
    } finally {
      setLoading(false);
    }
  };

  const updateStatus = async (newStatus) => {
    setUpdating(true);
    try {
      await api.put(`/orders/${orderId}/status`, { status: newStatus });
      toast.success('Order status updated');
      fetchOrder();
    } catch (error) {
      toast.error('Failed to update status');
    } finally {
      setUpdating(false);
    }
  };

  const cancelOrder = async () => {
    if (!window.confirm('Are you sure you want to cancel this order?')) return;
    setUpdating(true);
    try {
      await api.put(`/orders/${orderId}/cancel`, { reason: 'Cancelled by shop' });
      toast.success('Order cancelled');
      fetchOrder();
    } catch (error) {
      toast.error('Failed to cancel order');
    } finally {
      setUpdating(false);
    }
  };

  if (loading) {
    return <div className="text-center py-12">Loading...</div>;
  }

  if (!order) {
    return <div className="text-center py-12">Order not found</div>;
  }

  const nextStatuses = {
    placed: ['confirmed', 'cancelled'],
    confirmed: ['preparing', 'cancelled'],
    preparing: ['outForDelivery', 'cancelled'],
    outForDelivery: ['delivered'],
    delivered: [],
    cancelled: [],
  };

  return (
    <div className="max-w-4xl">
      <button
        onClick={() => navigate('/orders')}
        className="flex items-center space-x-2 text-blue-600 hover:text-blue-800 mb-6"
      >
        <ArrowLeft size={20} />
        <span>Back to Orders</span>
      </button>

      <div className="bg-white rounded-lg shadow p-6 space-y-6">
        {/* Header */}
        <div className="border-b pb-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">{order.orderId}</h1>
              <p className="text-gray-600 mt-1">
                {new Date(order.createdAt).toLocaleString()}
              </p>
            </div>
            <div className="text-right">
              <p className="text-3xl font-bold text-blue-600">₹{order.finalAmount}</p>
              <p className="text-sm text-gray-600 mt-1">
                Status: <span className="font-semibold capitalize">{order.status}</span>
              </p>
            </div>
          </div>
        </div>

        {/* Order Items */}
        <div>
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Order Items</h2>
          <div className="space-y-3">
            {order.items.map((item, index) => (
              <div key={index} className="flex items-center justify-between p-4 bg-gray-50 rounded">
                <div>
                  <p className="font-medium text-gray-900">{item.name}</p>
                  <p className="text-sm text-gray-600">Qty: {item.quantity}</p>
                  {item.specialInstructions && (
                    <p className="text-sm text-gray-600 mt-1">Note: {item.specialInstructions}</p>
                  )}
                </div>
                <p className="font-semibold text-gray-900">₹{item.totalPrice}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Delivery Details */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 border-t pt-6">
          <div>
            <h3 className="font-semibold text-gray-900 mb-3">Delivery Address</h3>
            <p className="text-gray-600">{order.deliveryAddress}</p>
          </div>
          <div>
            <h3 className="font-semibold text-gray-900 mb-3">Payment Details</h3>
            <div className="space-y-2 text-gray-600">
              <p>Method: <span className="font-medium capitalize">{order.paymentMethod}</span></p>
              <p>Status: <span className="font-medium capitalize">{order.paymentStatus}</span></p>
              <p>Subtotal: ₹{order.totalAmount}</p>
              <p>Delivery Fee: ₹{order.deliveryFee}</p>
            </div>
          </div>
        </div>

        {/* Timeline */}
        <div className="border-t pt-6">
          <h3 className="font-semibold text-gray-900 mb-4">Order Timeline</h3>
          <div className="space-y-4">
            <div className="flex items-start space-x-4">
              <div className="w-3 h-3 bg-blue-600 rounded-full mt-2" />
              <div>
                <p className="font-medium text-gray-900">Order Placed</p>
                <p className="text-sm text-gray-600">{new Date(order.createdAt).toLocaleString()}</p>
              </div>
            </div>
            {order.actualDeliveryTime && (
              <div className="flex items-start space-x-4">
                <div className="w-3 h-3 bg-green-600 rounded-full mt-2" />
                <div>
                  <p className="font-medium text-gray-900">Delivered</p>
                  <p className="text-sm text-gray-600">{new Date(order.actualDeliveryTime).toLocaleString()}</p>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Actions */}
        {nextStatuses[order.status]?.length > 0 && (
          <div className="border-t pt-6">
            <h3 className="font-semibold text-gray-900 mb-4">Update Status</h3>
            <div className="flex flex-wrap gap-3">
              {nextStatuses[order.status].map((status) => (
                <button
                  key={status}
                  onClick={() => updateStatus(status)}
                  disabled={updating}
                  className={`px-4 py-2 rounded-lg font-medium transition-colors disabled:opacity-50 ${
                    status === 'cancelled'
                      ? 'bg-red-100 text-red-700 hover:bg-red-200'
                      : 'bg-blue-100 text-blue-700 hover:bg-blue-200'
                  }`}
                >
                  {updating && <Loader size={16} className="inline animate-spin mr-2" />}
                  Mark as {status.charAt(0).toUpperCase() + status.slice(1)}
                </button>
              ))}
            </div>
          </div>
        )}

        {!['delivered', 'cancelled'].includes(order.status) && (
          <button
            onClick={cancelOrder}
            disabled={updating}
            className="px-4 py-2 bg-red-100 text-red-700 rounded-lg font-medium hover:bg-red-200 transition-colors disabled:opacity-50"
          >
            Cancel Order
          </button>
        )}
      </div>
    </div>
  );
}
