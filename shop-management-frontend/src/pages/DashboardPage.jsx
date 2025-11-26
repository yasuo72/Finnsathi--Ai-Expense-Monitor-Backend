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
    return <div className="text-center py-12">Loading...</div>;
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
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {statCards.map((card, index) => {
          const Icon = card.icon;
          return (
            <div key={index} className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-600 text-sm">{card.title}</p>
                  <p className="text-2xl font-bold text-gray-900 mt-2">{card.value}</p>
                </div>
                <div className={`${card.color} p-3 rounded-lg`}>
                  <Icon size={24} className="text-white" />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Recent Orders</h3>
          <div className="space-y-3">
            {stats?.recentOrders?.slice(0, 5).map((order) => (
              <div key={order._id} className="flex items-center justify-between p-3 bg-gray-50 rounded">
                <div>
                  <p className="font-medium text-gray-900">{order.orderId}</p>
                  <p className="text-sm text-gray-600">{new Date(order.createdAt).toLocaleDateString()}</p>
                </div>
                <p className="font-semibold text-gray-900">₹{order.finalAmount}</p>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Top Menu Items</h3>
          <div className="space-y-3">
            {stats?.topItems?.slice(0, 5).map((item) => (
              <div key={item._id} className="flex items-center justify-between p-3 bg-gray-50 rounded">
                <div>
                  <p className="font-medium text-gray-900">{item.name}</p>
                  <p className="text-sm text-gray-600">₹{item.price}</p>
                </div>
                <div className="flex items-center space-x-1">
                  <Star size={16} className="text-yellow-400 fill-yellow-400" />
                  <span className="text-sm font-medium">{item.rating.toFixed(1)}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
