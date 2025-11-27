import React, { useEffect, useState } from 'react';
import { TrendingUp, ShoppingCart, DollarSign, Star } from 'lucide-react';
import api from '../services/api';
import toast from 'react-hot-toast';

export default function DashboardPage() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const response = await api.get('/shops/stats');
      setStats(response.data);
    } catch (error) {
      if (error.response?.status === 404) {
        // No shop created yet for this owner - show empty stats instead of error
        console.warn('No shop found for stats, showing empty dashboard.');
        setStats({
          totalOrders: 0,
          totalRevenue: 0,
          averageOrderValue: 0,
          recentOrders: [],
          topItems: [],
        });
      } else {
        console.error('Error loading shop stats:', error.response?.data || error.message || error);
        toast.error('Failed to load statistics');
      }
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="text-center py-12 text-slate-300 text-sm">Loading dashboard...</div>;
  }

  const statCards = [
    {
      title: 'Total Orders',
      value: stats?.totalOrders || 0,
      icon: ShoppingCart,
      color: 'bg-blue-500',
    },
    {
      title: 'Total Revenue',
      value: `₹${stats?.totalRevenue || 0}`,
      icon: DollarSign,
      color: 'bg-green-500',
    },
    {
      title: 'Avg Order Value',
      value: `₹${Math.round(stats?.averageOrderValue || 0)}`,
      icon: TrendingUp,
      color: 'bg-purple-500',
    },
  ];

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 md:gap-6">
        {statCards.map((card, index) => {
          const Icon = card.icon;
          return (
            <div
              key={index}
              className="relative overflow-hidden rounded-2xl border border-slate-800 bg-slate-900/80 p-5 shadow-lg shadow-slate-950/60"
            >
              <div className="absolute inset-px rounded-2xl bg-gradient-to-br from-slate-900/0 via-slate-900/40 to-slate-950/80" />
              <div className="relative flex items-center justify-between">
                <div>
                  <p className="text-xs font-medium uppercase tracking-wide text-slate-400">{card.title}</p>
                  <p className="mt-2 text-2xl font-semibold text-slate-50">{card.value}</p>
                </div>
                <div className={`${card.color} p-3 rounded-xl shadow-md shadow-slate-900/60`}>
                  <Icon size={22} className="text-white" />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 md:gap-6">
        <div className="rounded-2xl border border-slate-800 bg-slate-900/80 p-5 md:p-6 shadow-lg shadow-slate-950/60">
          <h3 className="text-sm font-semibold text-slate-100 mb-4 tracking-wide uppercase">
            Recent Orders
          </h3>
          <div className="space-y-3">
            {stats?.recentOrders?.slice(0, 5).map((order) => (
              <div
                key={order._id}
                className="flex items-center justify-between rounded-xl border border-slate-800/80 bg-slate-900/60 px-3 py-2.5"
              >
                <div>
                  <p className="text-sm font-medium text-slate-100">{order.orderId}</p>
                  <p className="text-xs text-slate-400">
                    {new Date(order.createdAt).toLocaleDateString()}
                  </p>
                </div>
                <p className="text-sm font-semibold text-slate-50">₹{order.finalAmount}</p>
              </div>
            ))}
            {(!stats?.recentOrders || stats.recentOrders.length === 0) && (
              <p className="text-xs text-slate-400">No recent orders yet. New orders will appear here.</p>
            )}
          </div>
        </div>

        <div className="rounded-2xl border border-slate-800 bg-slate-900/80 p-5 md:p-6 shadow-lg shadow-slate-950/60">
          <h3 className="text-sm font-semibold text-slate-100 mb-4 tracking-wide uppercase">
            Top Menu Items
          </h3>
          <div className="space-y-3">
            {stats?.topItems?.slice(0, 5).map((item) => (
              <div
                key={item._id}
                className="flex items-center justify-between rounded-xl border border-slate-800/80 bg-slate-900/60 px-3 py-2.5"
              >
                <div>
                  <p className="text-sm font-medium text-slate-100">{item.name}</p>
                  <p className="text-xs text-slate-400">₹{item.price}</p>
                </div>
                <div className="flex items-center space-x-1">
                  <Star size={16} className="text-yellow-400 fill-yellow-400" />
                  <span className="text-xs font-medium text-slate-100">{item.rating.toFixed(1)}</span>
                </div>
              </div>
            ))}
            {(!stats?.topItems || stats.topItems.length === 0) && (
              <p className="text-xs text-slate-400">No top items yet. Orders will build this ranking.</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
