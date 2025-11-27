import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Eye, Clock, Package } from 'lucide-react';
import api from '../services/api';

const STATUSES = ['all', 'placed', 'confirmed', 'preparing', 'outForDelivery', 'delivered', 'cancelled'];

export default function AdminOrdersPage() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('all');

  useEffect(() => {
    fetchOrders();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [statusFilter]);

  const fetchOrders = async () => {
    try {
      const params = {};
      if (statusFilter && statusFilter !== 'all') {
        params.status = statusFilter;
      }
      const response = await api.get('/orders/admin/all', { params });
      setOrders(response.data?.orders || []);
    } catch (error) {
      console.error('Failed to load admin orders:', error.response?.data || error.message || error);
      setOrders([]);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="text-sm text-slate-300 py-10 text-center">Loading global orders...</div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
        <div>
          <h1 className="text-xl md:text-2xl font-semibold text-slate-50 flex items-center gap-2">
            <Package size={20} className="text-amber-300" />
            <span>Global Orders</span>
          </h1>
          <p className="text-xs text-slate-400 mt-1">All orders across every shop in the network.</p>
        </div>
      </div>

      {/* Status filter */}
      <div className="flex flex-wrap items-center gap-2">
        {STATUSES.map((status) => (
          <button
            key={status}
            onClick={() => setStatusFilter(status)}
            className={`px-3 py-1.5 rounded-full text-[11px] font-medium capitalize border transition-colors ${
              statusFilter === status
                ? 'border-amber-400 bg-amber-500/10 text-amber-200'
                : 'border-slate-700 bg-slate-900/60 text-slate-300 hover:border-amber-400/60 hover:text-amber-200'
            }`}
          >
            {status === 'all' ? 'All' : status.replace(/([A-Z])/g, ' $1')}
          </button>
        ))}
      </div>

      <div className="rounded-2xl border border-slate-800 bg-slate-950/60 shadow-lg shadow-slate-950/60 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-xs md:text-sm">
            <thead className="bg-slate-900/80 border-b border-slate-800 text-slate-400">
              <tr>
                <th className="px-4 py-3 text-left font-medium">Order ID</th>
                <th className="px-4 py-3 text-left font-medium">Shop</th>
                <th className="px-4 py-3 text-left font-medium">Customer</th>
                <th className="px-4 py-3 text-left font-medium">Amount</th>
                <th className="px-4 py-3 text-left font-medium">Status</th>
                <th className="px-4 py-3 text-left font-medium">Date</th>
                <th className="px-4 py-3 text-left font-medium">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/80">
              {orders.map((order) => (
                <tr key={order._id} className="hover:bg-slate-900/70">
                  <td className="px-4 py-3 text-slate-100 font-medium">{order.orderId}</td>
                  <td className="px-4 py-3 text-slate-100">
                    <div className="text-xs font-medium">{order.shop?.name || 'Unknown shop'}</div>
                    <div className="text-[11px] text-slate-400">{order.shop?.location}</div>
                  </td>
                  <td className="px-4 py-3 text-slate-100">
                    <div className="text-xs font-medium">{order.customer?.name || 'Customer'}</div>
                    <div className="text-[11px] text-slate-400">{order.customer?.phone || order.customer?.email}</div>
                  </td>
                  <td className="px-4 py-3 text-slate-100 font-semibold">₹{order.finalAmount}</td>
                  <td className="px-4 py-3 text-slate-200 capitalize">{order.status}</td>
                  <td className="px-4 py-3 text-slate-400">
                    {order.createdAt ? new Date(order.createdAt).toLocaleDateString() : ''}
                  </td>
                  <td className="px-4 py-3">
                    <Link
                      to={`/orders/${order._id}`}
                      className="inline-flex items-center gap-1 text-[11px] text-amber-300 hover:text-amber-200"
                    >
                      <Eye size={14} />
                      <span>View in Shop</span>
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {orders.length === 0 && (
          <div className="py-10 text-center text-xs text-slate-400">No orders found for the selected filter.</div>
        )}
      </div>
    </div>
  );
}
