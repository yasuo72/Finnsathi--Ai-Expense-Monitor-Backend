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
  const [searchTerm, setSearchTerm] = useState('');

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
    return <div className="text-center py-12 text-slate-300 text-sm">Loading orders...</div>;
  }

  const statuses = ['all', 'placed', 'confirmed', 'preparing', 'outForDelivery', 'delivered', 'cancelled'];

  const normalizedSearch = searchTerm.trim().toLowerCase();
  const visibleOrders = normalizedSearch
    ? orders.filter((order) => {
        const values = [
          order.orderId,
          order.customer?.name,
          order.customer?.phone,
          order.customer?.email,
        ]
          .filter(Boolean)
          .map((v) => v.toString().toLowerCase());
        return values.some((v) => v.includes(normalizedSearch));
      })
    : orders;

  const statusSummary = statuses
    .filter((s) => s !== 'all')
    .map((status) => ({
      status,
      count: orders.filter((order) => order.status === status).length,
    }));

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
        <div>
          <h1 className="text-xl md:text-2xl font-semibold text-slate-50">Orders</h1>
          <p className="text-xs text-slate-400 mt-1">Track and manage all incoming food orders in real time.</p>
        </div>
        <div className="flex flex-col sm:flex-row gap-2 sm:items-center">
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search by order, customer, phone"
            className="w-full sm:w-64 rounded-xl border border-slate-700 bg-slate-900/70 px-3 py-2 text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500"
          />
        </div>
      </div>

      {/* Status pills */}
      <div className="flex flex-wrap items-center gap-2">
        {statuses.map((status) => (
          <button
            key={status}
            onClick={() => setFilter(status)}
            className={`px-3 py-1.5 rounded-full text-xs font-medium capitalize border transition-colors ${
              filter === status
                ? 'border-cyan-400 bg-cyan-500/10 text-cyan-200'
                : 'border-slate-700 bg-slate-900/60 text-slate-300 hover:border-cyan-400/60 hover:text-cyan-200'
            }`}
          >
            {status === 'all' ? 'All' : status.replace(/([A-Z])/g, ' $1')}
          </button>
        ))}
      </div>

      {/* Quick status summary */}
      <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-3">
        {statusSummary.map(({ status, count }) => (
          <div
            key={status}
            className="rounded-2xl border border-slate-800 bg-slate-900/80 px-3 py-2.5 flex flex-col gap-1"
          >
            <span className="text-[10px] uppercase tracking-wide text-slate-400">
              {status.replace(/([A-Z])/g, ' $1')}
            </span>
            <span className="text-sm font-semibold text-slate-50">{count}</span>
          </div>
        ))}
      </div>

      {/* Orders Table */}
      <div className="rounded-2xl border border-slate-800 bg-slate-950/60 shadow-lg shadow-slate-950/60 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-slate-900/80 border-b border-slate-800">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-300">Order ID</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-300">Customer</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-300">Amount</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-300">Items</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-300">Status</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-300">Date</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-300">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/80">
              {visibleOrders.map((order) => {
                const StatusIcon = statusIcons[order.status];
                return (
                  <tr key={order._id} className="hover:bg-slate-900/70">
                    <td className="px-6 py-4 text-xs md:text-sm font-medium text-slate-100">{order.orderId}</td>
                    <td className="px-6 py-4 text-xs md:text-sm text-slate-100">
                      <div className="flex items-center space-x-3">
                        {order.customer?.avatarUrl ? (
                          <img
                            src={order.customer.avatarUrl}
                            alt={order.customer.name || 'Customer'}
                            className="h-8 w-8 rounded-full object-cover"
                          />
                        ) : (
                          <div className="h-8 w-8 rounded-full bg-slate-800 flex items-center justify-center text-xs font-semibold text-slate-200">
                            {(order.customer?.name || 'C')
                              .toString()
                              .charAt(0)
                              .toUpperCase()}
                          </div>
                        )}
                        <div>
                          <div className="font-medium text-slate-100">
                            {order.customer?.name || 'Customer'}
                          </div>
                          <div className="text-[11px] text-slate-400">
                            {order.customer?.phone || order.customer?.email || ''}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-xs md:text-sm font-semibold text-slate-100">₹{order.finalAmount}</td>
                    <td className="px-6 py-4 text-xs md:text-sm text-slate-300">{order.items.length} items</td>
                    <td className="px-6 py-4">
                      <div className={`flex items-center space-x-2 px-3 py-1 rounded-full w-fit ${statusColors[order.status]}`}>
                        <StatusIcon size={16} />
                        <span className="text-xs font-medium capitalize">{order.status}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-xs md:text-sm text-slate-400">
                      {new Date(order.createdAt).toLocaleDateString()}
                    </td>
                    <td className="px-6 py-4">
                      <Link
                        to={`/orders/${order._id}`}
                        className="inline-flex items-center space-x-1 text-cyan-400 hover:text-cyan-300 text-xs md:text-sm"
                      >
                        <Eye size={16} />
                        <span>View</span>
                      </Link>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
        {visibleOrders.length === 0 && (
          <div className="text-center py-10 text-xs text-slate-400">
            No orders match your filters yet.
          </div>
        )}
      </div>
    </div>
  );
}
