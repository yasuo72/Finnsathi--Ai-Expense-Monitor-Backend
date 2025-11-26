import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Eye, CheckCircle, Clock, Truck, Package } from 'lucide-react';
import api from '../services/api';
import toast from 'react-hot-toast';

const statusIcons = {
  placed: Clock,
  confirmed: CheckCircle,
  preparing: Package,
  outForDelivery: Truck,
  delivered: CheckCircle,
  cancelled: Clock,
};

const statusColors = {
  placed: 'bg-blue-100 text-blue-800',
  confirmed: 'bg-yellow-100 text-yellow-800',
  preparing: 'bg-purple-100 text-purple-800',
  outForDelivery: 'bg-orange-100 text-orange-800',
  delivered: 'bg-green-100 text-green-800',
  cancelled: 'bg-red-100 text-red-800',
};

export default function OrdersPage() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    fetchOrders();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filter]);

  const fetchOrders = async () => {
    try {
      const params = filter !== 'all' ? { status: filter } : {};
      const response = await api.get('/orders', { params });
      setOrders(response.data.orders);
    } catch (error) {
      if (error.response?.status === 404) {
        // No shop created yet for this owner - show empty orders instead of error
        console.warn('No shop found when loading orders; showing empty orders list.');
        setOrders([]);
      } else {
        toast.error('Failed to load orders');
      }
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="text-center py-12">Loading...</div>;
  }

  const statuses = ['all', 'placed', 'confirmed', 'preparing', 'outForDelivery', 'delivered', 'cancelled'];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Orders</h1>

      {/* Filter Tabs */}
      <div className="flex space-x-2 overflow-x-auto pb-2">
        {statuses.map((status) => (
          <button
            key={status}
            onClick={() => setFilter(status)}
            className={`px-4 py-2 rounded-lg whitespace-nowrap transition-colors ${
              filter === status
                ? 'bg-blue-600 text-white'
                : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
            }`}
          >
            {status.charAt(0).toUpperCase() + status.slice(1)}
          </button>
        ))}
      </div>

      {/* Orders Table */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Order ID</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Customer</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Amount</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Items</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Status</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Date</th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {orders.map((order) => {
                const StatusIcon = statusIcons[order.status];
                return (
                  <tr key={order._id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm font-medium text-gray-900">{order.orderId}</td>
                    <td className="px-6 py-4 text-sm text-gray-900">
                      <div className="flex items-center space-x-3">
                        {order.customer?.avatarUrl ? (
                          <img
                            src={order.customer.avatarUrl}
                            alt={order.customer.name || 'Customer'}
                            className="h-8 w-8 rounded-full object-cover"
                          />
                        ) : (
                          <div className="h-8 w-8 rounded-full bg-gray-200 flex items-center justify-center text-xs font-semibold text-gray-600">
                            {(order.customer?.name || 'C')
                              .toString()
                              .charAt(0)
                              .toUpperCase()}
                          </div>
                        )}
                        <div>
                          <div className="font-medium">
                            {order.customer?.name || 'Customer'}
                          </div>
                          <div className="text-xs text-gray-500">
                            {order.customer?.phone || order.customer?.email || ''}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm font-semibold text-gray-900">₹{order.finalAmount}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{order.items.length} items</td>
                    <td className="px-6 py-4">
                      <div className={`flex items-center space-x-2 px-3 py-1 rounded-full w-fit ${statusColors[order.status]}`}>
                        <StatusIcon size={16} />
                        <span className="text-xs font-medium capitalize">{order.status}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {new Date(order.createdAt).toLocaleDateString()}
                    </td>
                    <td className="px-6 py-4">
                      <Link
                        to={`/orders/${order._id}`}
                        className="flex items-center space-x-1 text-blue-600 hover:text-blue-800"
                      >
                        <Eye size={16} />
                        <span className="text-sm">View</span>
                      </Link>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
        {orders.length === 0 && (
          <div className="text-center py-12 text-gray-500">
            No orders found
          </div>
        )}
      </div>
    </div>
  );
}
