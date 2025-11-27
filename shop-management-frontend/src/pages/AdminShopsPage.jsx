import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Store, MapPin, Search, CheckCircle2, XCircle } from 'lucide-react';
import api from '../services/api';

export default function AdminShopsPage() {
  const [shops, setShops] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [updatingId, setUpdatingId] = useState(null);

  useEffect(() => {
    fetchShops();
  }, []);

  const fetchShops = async () => {
    try {
      const response = await api.get('/shops');
      setShops(Array.isArray(response.data) ? response.data : []);
    } catch (error) {
      console.error('Failed to load shops for admin:', error.response?.data || error.message || error);
      setShops([]);
    } finally {
      setLoading(false);
    }
  };

  const updateShopAdmin = async (shopId, payload) => {
    try {
      setUpdatingId(shopId);
      const response = await api.patch(`/shops/admin/${shopId}`, payload);
      const updated = response.data?.shop;
      if (updated) {
        setShops((prev) => prev.map((shop) => (shop._id === shopId ? { ...shop, ...updated } : shop)));
      }
    } catch (error) {
      console.error('Failed to update shop via admin:', error.response?.data || error.message || error);
    } finally {
      setUpdatingId(null);
    }
  };

  const handleToggleOpen = (shop) => {
    updateShopAdmin(shop._id, { isOpen: !shop.isOpen });
  };

  const handleToggleVerified = (shop) => {
    updateShopAdmin(shop._id, { isVerified: !shop.isVerified });
  };

  const handleToggleBlocked = (shop) => {
    updateShopAdmin(shop._id, { isBlocked: !shop.isBlocked });
  };

  const normalizedSearch = searchTerm.trim().toLowerCase();
  const filteredShops = normalizedSearch
    ? shops.filter((shop) => {
        const values = [shop.name, shop.location, shop.email]
          .filter(Boolean)
          .map((v) => v.toString().toLowerCase());
        return values.some((v) => v.includes(normalizedSearch));
      })
    : shops;

  if (loading) {
    return <div className="text-sm text-slate-300 py-10 text-center">Loading shops...</div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
        <div>
          <h1 className="text-xl md:text-2xl font-semibold text-slate-50 flex items-center gap-2">
            <Store size={20} className="text-amber-300" />
            <span>All Shops</span>
          </h1>
          <p className="text-xs text-slate-400 mt-1">View and inspect every restaurant connected to FinSathi.</p>
        </div>
        <div className="flex items-center gap-2">
          <div className="relative w-full sm:w-64">
            <Search
              size={16}
              className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500"
            />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search by name, city, email"
              className="w-full rounded-xl border border-slate-700 bg-slate-900/70 px-9 py-2 text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-amber-400 focus:border-amber-400"
            />
          </div>
        </div>
      </div>

      <div className="rounded-2xl border border-slate-800 bg-slate-950/60 shadow-lg shadow-slate-950/60 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-xs md:text-sm">
            <thead className="bg-slate-900/80 border-b border-slate-800 text-slate-400">
              <tr>
                <th className="px-4 py-3 text-left font-medium">Shop</th>
                <th className="px-4 py-3 text-left font-medium">Location</th>
                <th className="px-4 py-3 text-left font-medium">Rating</th>
                <th className="px-4 py-3 text-left font-medium">Status</th>
                <th className="px-4 py-3 text-left font-medium">Blocked</th>
                <th className="px-4 py-3 text-left font-medium">Verified</th>
                <th className="px-4 py-3 text-left font-medium">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/80">
              {filteredShops.map((shop) => (
                <tr key={shop._id} className="hover:bg-slate-900/70">
                  <td className="px-4 py-3 text-slate-100">
                    <div className="font-medium">{shop.name}</div>
                    <div className="text-[11px] text-slate-400">{shop.email}</div>
                  </td>
                  <td className="px-4 py-3 text-slate-200">
                    <div className="flex items-center gap-1 text-[11px] md:text-xs">
                      <MapPin size={13} className="text-slate-400" />
                      <span className="truncate max-w-[160px] md:max-w-xs">{shop.location}</span>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-slate-100">
                    <span className="text-xs font-semibold">
                      {typeof shop.rating === 'number' ? shop.rating.toFixed(1) : '0.0'}
                    </span>
                    <span className="text-[11px] text-slate-500 ml-1">
                      ({shop.totalReviews || 0} reviews)
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    {shop.isOpen ? (
                      <span className="inline-flex items-center gap-1 rounded-full border border-emerald-400/70 bg-emerald-500/10 px-2 py-0.5 text-[11px] font-medium text-emerald-200">
                        <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
                        Open
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 rounded-full border border-slate-600 bg-slate-800 px-2 py-0.5 text-[11px] font-medium text-slate-300">
                        <span className="h-1.5 w-1.5 rounded-full bg-slate-500" />
                        Closed
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    {shop.isBlocked ? (
                      <span className="inline-flex items-center gap-1 rounded-full border border-red-500/70 bg-red-500/10 px-2 py-0.5 text-[11px] font-medium text-red-300">
                        <span className="h-1.5 w-1.5 rounded-full bg-red-500" />
                        Blocked
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 rounded-full border border-emerald-400/70 bg-emerald-500/10 px-2 py-0.5 text-[11px] font-medium text-emerald-200">
                        <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
                        Active
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    {shop.isVerified ? (
                      <span className="inline-flex items-center gap-1 text-emerald-300 text-[11px]">
                        <CheckCircle2 size={13} />
                        Verified
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 text-slate-400 text-[11px]">
                        <XCircle size={13} />
                        Not verified
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex flex-col gap-1">
                      <button
                        type="button"
                        onClick={() => handleToggleOpen(shop)}
                        disabled={updatingId === shop._id}
                        className="text-[11px] text-slate-200 hover:text-amber-200 disabled:opacity-60 text-left"
                      >
                        {shop.isOpen ? 'Close shop' : 'Open shop'}
                      </button>
                      <button
                        type="button"
                        onClick={() => handleToggleVerified(shop)}
                        disabled={updatingId === shop._id}
                        className="text-[11px] text-slate-200 hover:text-amber-200 disabled:opacity-60 text-left"
                      >
                        {shop.isVerified ? 'Unverify shop' : 'Verify shop'}
                      </button>
                      <button
                        type="button"
                        onClick={() => handleToggleBlocked(shop)}
                        disabled={updatingId === shop._id}
                        className="text-[11px] text-red-300 hover:text-red-200 disabled:opacity-60 text-left"
                      >
                        {shop.isBlocked ? 'Unblock shop' : 'Block shop'}
                      </button>
                      <Link
                        to={`/admin/shops/${shop._id}`}
                        className="inline-flex items-center text-[11px] font-medium text-amber-300 hover:text-amber-200"
                      >
                        View details
                      </Link>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {filteredShops.length === 0 && (
          <div className="py-10 text-center text-xs text-slate-400">
            No shops found matching your filters.
          </div>
        )}
      </div>
    </div>
  );
}
