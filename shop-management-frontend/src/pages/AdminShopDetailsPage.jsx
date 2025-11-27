import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { MapPin, Phone, Mail, Store } from 'lucide-react';
import api from '../services/api';

export default function AdminShopDetailsPage() {
  const { shopId } = useParams();
  const [shop, setShop] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [updatingFlags, setUpdatingFlags] = useState(false);
  const [orders, setOrders] = useState([]);
  const [ordersLoading, setOrdersLoading] = useState(true);
  const [ordersError, setOrdersError] = useState(null);
  const [ownerInfo, setOwnerInfo] = useState(null);
  const [ownerLoading, setOwnerLoading] = useState(true);
  const [ownerError, setOwnerError] = useState(null);

  useEffect(() => {
    fetchShop();
    fetchOrders();
    fetchOwner();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [shopId]);

  const fetchShop = async () => {
    try {
      const response = await api.get(`/shops/${shopId}`);
      setShop(response.data);
    } catch (err) {
      console.error('Failed to load shop details:', err.response?.data || err.message || err);
      setError('Unable to load shop details');
    } finally {
      setLoading(false);
    }
  };

  const fetchOrders = async () => {
    try {
      setOrdersLoading(true);
      const response = await api.get('/orders/admin/all', {
        params: { shopId, limit: 10 },
      });
      setOrders(response.data?.orders || []);
      setOrdersError(null);
    } catch (err) {
      console.error('Failed to load shop orders for admin:', err.response?.data || err.message || err);
      setOrders([]);
      setOrdersError('Unable to load recent orders');
    } finally {
      setOrdersLoading(false);
    }
  };

  const fetchOwner = async () => {
    try {
      setOwnerLoading(true);
      const response = await api.get(`/shops/admin/${shopId}/owner`);
      setOwnerInfo(response.data?.owner || null);
      setOwnerError(null);
    } catch (err) {
      console.error('Failed to load shop owner info for admin:', err.response?.data || err.message || err);
      setOwnerInfo(null);
      setOwnerError('Unable to load owner info');
    } finally {
      setOwnerLoading(false);
    }
  };

  const handleToggleOpen = async () => {
    if (!shop) return;
    try {
      setUpdatingFlags(true);
      const response = await api.patch(`/shops/admin/${shop._id}`, {
        isOpen: !shop.isOpen,
      });
      const updated = response.data?.shop;
      if (updated) {
        setShop(updated);
      }
    } catch (err) {
      console.error('Failed to toggle shop open status via admin:', err.response?.data || err.message || err);
    } finally {
      setUpdatingFlags(false);
    }
  };

  const handleToggleBlocked = async () => {
    if (!shop) return;
    try {
      setUpdatingFlags(true);
      const response = await api.patch(`/shops/admin/${shop._id}`, {
        isBlocked: !shop.isBlocked,
      });
      const updated = response.data?.shop;
      if (updated) {
        setShop(updated);
      }
    } catch (err) {
      console.error('Failed to toggle shop block status via admin:', err.response?.data || err.message || err);
    } finally {
      setUpdatingFlags(false);
    }
  };

  const handleToggleVerified = async () => {
    if (!shop) return;
    try {
      setUpdatingFlags(true);
      const response = await api.patch(`/shops/admin/${shop._id}`, {
        isVerified: !shop.isVerified,
      });
      const updated = response.data?.shop;
      if (updated) {
        setShop(updated);
      }
    } catch (err) {
      console.error('Failed to toggle shop verification via admin:', err.response?.data || err.message || err);
    } finally {
      setUpdatingFlags(false);
    }
  };

  if (loading) {
    return <div className="text-sm text-slate-300 py-10 text-center">Loading shop details...</div>;
  }

  if (error || !shop) {
    return <div className="text-sm text-red-300 py-10 text-center">{error || 'Shop not found'}</div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
        <div className="flex items-center gap-3">
          <div className="h-10 w-10 rounded-xl bg-gradient-to-tr from-amber-400 to-red-500 flex items-center justify-center text-slate-950 shadow-lg shadow-amber-500/40">
            <Store size={20} />
          </div>
          <div>
            <h1 className="text-xl md:text-2xl font-semibold text-slate-50">{shop.name}</h1>
            <p className="text-[11px] text-slate-400 mt-0.5">Detailed view of this restaurant within the network.</p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 md:gap-6">
        <div className="lg:col-span-2 rounded-2xl border border-slate-800 bg-slate-900/80 p-5 md:p-6 shadow-lg shadow-slate-950/60 space-y-4">
          {shop.imageUrl && (
            <img
              src={shop.imageUrl}
              alt={shop.name}
              className="w-full max-h-64 object-cover rounded-xl border border-slate-700"
            />
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs md:text-sm">
            <div className="space-y-2">
              <div>
                <p className="text-slate-400 text-[11px] uppercase tracking-wide">Location</p>
                <p className="text-slate-100 flex items-center gap-1 mt-1">
                  <MapPin size={14} className="text-slate-400" />
                  <span>{shop.location}</span>
                </p>
              </div>
              <div>
                <p className="text-slate-400 text-[11px] uppercase tracking-wide">Contact</p>
                <p className="text-slate-100 flex items-center gap-2 mt-1">
                  <span className="inline-flex items-center gap-1 text-xs">
                    <Phone size={13} className="text-slate-400" />
                    {shop.phone}
                  </span>
                  <span className="inline-flex items-center gap-1 text-xs">
                    <Mail size={13} className="text-slate-400" />
                    {shop.email}
                  </span>
                </p>
              </div>
            </div>

            <div className="space-y-2">
              <div>
                <p className="text-slate-400 text-[11px] uppercase tracking-wide">Status</p>
                <p className="mt-1 flex items-center gap-2">
                  <span className="inline-flex items-center gap-1 rounded-full border border-emerald-400/70 bg-emerald-500/10 px-2 py-0.5 text-[11px] font-medium text-emerald-200">
                    <span className={`h-1.5 w-1.5 rounded-full ${shop.isOpen ? 'bg-emerald-400' : 'bg-slate-500'}`} />
                    {shop.isOpen ? 'Open' : 'Closed'}
                  </span>
                  <button
                    type="button"
                    onClick={handleToggleOpen}
                    disabled={updatingFlags}
                    className="text-[11px] text-amber-300 hover:text-amber-200 disabled:opacity-60"
                  >
                    {shop.isOpen ? 'Close shop' : 'Open shop'}
                  </button>
                </p>
              </div>
              <div>
                <p className="text-slate-400 text-[11px] uppercase tracking-wide">Rating</p>
                <p className="text-slate-100 mt-1 text-sm">
                  {typeof shop.rating === 'number' ? shop.rating.toFixed(1) : '0.0'}{' '}
                  <span className="text-[11px] text-slate-500">
                    ({shop.totalReviews || 0} reviews)
                  </span>
                </p>
              </div>
            </div>
          </div>

          {shop.description && (
            <div className="mt-2 text-xs text-slate-300">
              <p className="text-[11px] uppercase tracking-wide text-slate-400 mb-1">Description</p>
              <p>{shop.description}</p>
            </div>
          )}
        </div>

        <div className="rounded-2xl border border-slate-800 bg-slate-900/80 p-5 md:p-6 shadow-lg shadow-slate-950/60 space-y-3 text-xs">
          <p className="text-[11px] uppercase tracking-wide text-slate-400">Quick Metrics</p>
          <div className="space-y-2">
            <div className="flex items-center justify-between py-1">
              <span className="text-slate-300">Estimated Delivery Time</span>
              <span className="text-slate-100 font-medium">{shop.deliveryTimeMinutes || 30} min</span>
            </div>
            <div className="flex items-center justify-between py-1">
              <span className="text-slate-300">Delivery Fee</span>
              <span className="text-slate-100 font-medium">₹{shop.deliveryFee || 0}</span>
            </div>
            <div className="flex items-center justify-between py-1">
              <span className="text-slate-300">Minimum Order</span>
              <span className="text-slate-100 font-medium">₹{shop.minOrderValue || 0}</span>
            </div>
            <div className="flex items-center justify-between py-1">
              <span className="text-slate-300">Verified</span>
              <div className="flex items-center gap-2">
                <span className="text-slate-100 font-medium">{shop.isVerified ? 'Yes' : 'No'}</span>
                <button
                  type="button"
                  onClick={handleToggleVerified}
                  disabled={updatingFlags}
                  className="text-[11px] text-amber-300 hover:text-amber-200 disabled:opacity-60"
                >
                  {shop.isVerified ? 'Unverify' : 'Verify'}
                </button>
              </div>
            </div>
            <div className="flex items-center justify-between py-1">
              <span className="text-slate-300">Blocked</span>
              <div className="flex items-center gap-2">
                <span className="text-slate-100 font-medium">{shop.isBlocked ? 'Yes' : 'No'}</span>
                <button
                  type="button"
                  onClick={handleToggleBlocked}
                  disabled={updatingFlags}
                  className="text-[11px] text-red-300 hover:text-red-200 disabled:opacity-60"
                >
                  {shop.isBlocked ? 'Unblock' : 'Block'}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="rounded-2xl border border-slate-800 bg-slate-900/80 p-5 md:p-6 shadow-lg shadow-slate-950/60 space-y-3 text-xs">
        <p className="text-[11px] uppercase tracking-wide text-slate-400">Owner Info</p>
        {ownerLoading ? (
          <div className="text-slate-300 text-xs">Loading owner...</div>
        ) : ownerError ? (
          <div className="text-red-300 text-xs">{ownerError}</div>
        ) : !ownerInfo ? (
          <div className="text-slate-400 text-xs">No owner linked to this shop.</div>
        ) : (
          <div className="space-y-1 text-xs">
            <div className="flex items-center justify-between py-0.5">
              <span className="text-slate-300">Name</span>
              <span className="text-slate-100 font-medium">{ownerInfo.name}</span>
            </div>
            <div className="flex items-center justify-between py-0.5">
              <span className="text-slate-300">Email</span>
              <span className="text-slate-100 font-medium">{ownerInfo.email}</span>
            </div>
            <div className="flex items-center justify-between py-0.5">
              <span className="text-slate-300">Phone</span>
              <span className="text-slate-100 font-medium">{ownerInfo.phone}</span>
            </div>
            <div className="flex items-center justify-between py-0.5">
              <span className="text-slate-300">Business</span>
              <span className="text-slate-100 font-medium">{ownerInfo.businessName || '-'}</span>
            </div>
            <div className="flex items-center justify-between py-0.5">
              <span className="text-slate-300">Type</span>
              <span className="text-slate-100 font-medium capitalize">{ownerInfo.businessType}</span>
            </div>
            <div className="flex items-center justify-between py-0.5">
              <span className="text-slate-300">Owner Verified</span>
              <span className="text-slate-100 font-medium">{ownerInfo.isVerified ? 'Yes' : 'No'}</span>
            </div>
            <div className="flex items-center justify-between py-0.5">
              <span className="text-slate-300">Owner Active</span>
              <span className="text-slate-100 font-medium">{ownerInfo.isActive ? 'Yes' : 'No'}</span>
            </div>
          </div>
        )}
      </div>

      <div className="rounded-2xl border border-slate-800 bg-slate-900/80 p-5 md:p-6 shadow-lg shadow-slate-950/60 space-y-3 text-xs">
        <p className="text-[11px] uppercase tracking-wide text-slate-400">Recent Orders</p>
        {ordersLoading ? (
          <div className="text-slate-300 text-xs">Loading orders...</div>
        ) : ordersError ? (
          <div className="text-red-300 text-xs">{ordersError}</div>
        ) : orders.length === 0 ? (
          <div className="text-slate-400 text-xs">No recent orders for this shop.</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-[11px] md:text-xs">
              <thead className="border-b border-slate-800 text-slate-400">
                <tr>
                  <th className="px-2 py-1 text-left font-medium">Order ID</th>
                  <th className="px-2 py-1 text-left font-medium">Customer</th>
                  <th className="px-2 py-1 text-left font-medium">Amount</th>
                  <th className="px-2 py-1 text-left font-medium">Status</th>
                  <th className="px-2 py-1 text-left font-medium">Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {orders.map((order) => (
                  <tr key={order._id} className="hover:bg-slate-900/70">
                    <td className="px-2 py-1 text-slate-100">{order.orderId}</td>
                    <td className="px-2 py-1 text-slate-100">
                      <div>{order.customer?.name || 'Customer'}</div>
                      <div className="text-[10px] text-slate-400">
                        {order.customer?.phone || order.customer?.email || ''}
                      </div>
                    </td>
                    <td className="px-2 py-1 text-slate-100">₹{order.finalAmount}</td>
                    <td className="px-2 py-1 text-slate-200 capitalize">{order.status}</td>
                    <td className="px-2 py-1 text-slate-400">
                      {order.createdAt ? new Date(order.createdAt).toLocaleDateString() : ''}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
