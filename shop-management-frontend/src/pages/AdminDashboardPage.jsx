import React, { useEffect, useState } from 'react';
import { Store, Users, ShoppingBag, AlertTriangle } from 'lucide-react';
import api from '../services/api';

export default function AdminDashboardPage() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [globalStats, setGlobalStats] = useState(null);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const response = await api.get('/shops/admin/stats');
        setGlobalStats(response.data || null);
      } catch (err) {
        console.error('Failed to load admin global stats:', err.response?.data || err.message || err);
        setError('Failed to load global statistics');
      } finally {
        setLoading(false);
      }
    };

    fetchStats();
  }, []);

  if (loading) {
    return <div className="text-sm text-slate-300 py-10 text-center">Loading global statistics...</div>;
  }

  if (error || !globalStats) {
    return <div className="text-sm text-red-300 py-10 text-center">{error || 'No statistics available'}</div>;
  }

  const statCards = [
    {
      title: 'Total Shops',
      value: globalStats.totalShops ?? 0,
      icon: Store,
      accent: 'from-amber-400 to-red-500',
    },
    {
      title: 'Total Orders',
      value: globalStats.totalOrders ?? 0,
      icon: ShoppingBag,
      accent: 'from-emerald-400 to-cyan-400',
    },
    {
      title: 'Total Revenue',
      value: `₹${(globalStats.totalRevenue ?? 0).toLocaleString()}`,
      icon: Users,
      accent: 'from-sky-400 to-indigo-500',
    },
  ];

  const topShops = Array.isArray(globalStats.topShops) ? globalStats.topShops : [];

  const systemAlerts = [];

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 md:gap-6">
        {statCards.map((stat) => {
          const Icon = stat.icon;
          return (
            <div
              key={stat.title}
              className="relative overflow-hidden rounded-2xl border border-slate-800 bg-slate-900/80 p-5 shadow-lg shadow-slate-950/60"
            >
              <div className="absolute inset-px rounded-2xl bg-gradient-to-br from-slate-900/0 via-slate-900/40 to-slate-950/80" />
              <div className="relative flex items-center justify-between">
                <div>
                  <p className="text-xs font-medium uppercase tracking-wide text-slate-400">{stat.title}</p>
                  <p className="mt-2 text-2xl font-semibold text-slate-50">{stat.value}</p>
                </div>
                <div className={`p-3 rounded-xl bg-gradient-to-tr ${stat.accent} shadow-md shadow-slate-900/60`}>
                  <Icon size={22} className="text-slate-950" />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 md:gap-6">
        <div className="lg:col-span-2 rounded-2xl border border-slate-800 bg-slate-900/80 p-5 md:p-6 shadow-lg shadow-slate-950/60">
          <h3 className="text-sm font-semibold text-slate-100 mb-4 tracking-wide uppercase">Top Performing Shops</h3>
          <div className="overflow-x-auto">
            <table className="w-full text-xs md:text-sm">
              <thead className="border-b border-slate-800 text-slate-400">
                <tr>
                  <th className="px-3 py-2 text-left font-medium">Shop</th>
                  <th className="px-3 py-2 text-left font-medium">Location</th>
                  <th className="px-3 py-2 text-left font-medium">Total Orders</th>
                  <th className="px-3 py-2 text-left font-medium">Total Revenue</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {topShops.map((shop) => (
                  <tr key={shop.shopId || shop.name} className="hover:bg-slate-900/70">
                    <td className="px-3 py-2 text-slate-100 font-medium">{shop.name}</td>
                    <td className="px-3 py-2 text-slate-300">{shop.location}</td>
                    <td className="px-3 py-2 text-slate-100">{shop.totalOrders}</td>
                    <td className="px-3 py-2 text-slate-100">₹{(shop.totalRevenue || 0).toLocaleString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        <div className="rounded-2xl border border-slate-800 bg-slate-900/80 p-5 md:p-6 shadow-lg shadow-slate-950/60 flex flex-col">
          <h3 className="text-sm font-semibold text-slate-100 mb-4 tracking-wide uppercase">System Alerts</h3>
          <div className="space-y-3 flex-1">
            {systemAlerts.map((alert) => (
              <div
                key={alert.code}
                className="flex items-start space-x-3 rounded-xl border border-slate-800/80 bg-slate-900/60 px-3 py-2.5"
              >
                <div className="mt-0.5 text-amber-300">
                  <AlertTriangle size={18} />
                </div>
                <div>
                  <p className="text-xs font-medium text-slate-100">{alert.message}</p>
                  <p className="text-[11px] text-slate-500 mt-1">Code {alert.code}</p>
                </div>
              </div>
            ))}
            {systemAlerts.length === 0 && (
              <p className="text-xs text-slate-400">No active system alerts.</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
