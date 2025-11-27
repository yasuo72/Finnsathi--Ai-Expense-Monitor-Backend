import React, { useEffect, useState } from 'react';
import { Upload, Loader } from 'lucide-react';
import api from '../services/api';
import toast from 'react-hot-toast';

export default function ShopPage() {
  const [shop, setShop] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [formData, setFormData] = useState({});

  useEffect(() => {
    fetchShop();
  }, []);

  const fetchShop = async () => {
    try {
      const response = await api.get('/shops/my-shop');
      setShop(response.data);
      setFormData(response.data);
    } catch (error) {
      if (error.response?.status === 404) {
        setShop(null);
      } else {
        console.error('Error loading shop:', error.response?.data || error.message || error);
        toast.error('Failed to load shop');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      if (shop) {
        await api.put('/shops', formData);
        toast.success('Shop updated successfully');
      } else {
        await api.post('/shops', formData);
        toast.success('Shop created successfully');
      }
      fetchShop();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to save shop');
    } finally {
      setSaving(false);
    }
  };

  const handleImageUpload = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const formDataWithFile = new FormData();
    formDataWithFile.append('image', file);

    try {
      const response = await api.post('/shops/upload-image', formDataWithFile, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      setFormData(prev => ({ ...prev, imageUrl: response.data.imageUrl }));
      toast.success('Image uploaded successfully');
    } catch (error) {
      console.error('Upload error:', error.response?.data || error.message || error);
      toast.error(error.response?.data?.message || 'Failed to upload image');
    }
  };

  if (loading) {
    return <div className="text-center py-12 text-slate-300 text-sm">Loading shop...</div>;
  }

  return (
    <div className="max-w-4xl space-y-4">
      <div className="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 md:p-8 shadow-lg shadow-slate-950/60">
        <h1 className="text-2xl font-semibold text-slate-50 mb-2">
          {shop ? 'Edit Shop' : 'Create Your Shop'}
        </h1>
        <p className="text-xs text-slate-400 mb-6">
          Configure your restaurant details, delivery settings and branding.
        </p>

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Shop Image */}
          <div>
            <label
              htmlFor="shop-image"
              className="block text-xs font-medium tracking-wide text-slate-300 mb-2"
            >
              Shop Image
            </label>
            <div className="flex items-center space-x-4">
              {formData.imageUrl && (
                <img src={formData.imageUrl} alt="Shop" className="w-32 h-32 rounded-xl object-cover border border-slate-700" />
              )}
              <label className="flex items-center space-x-2 px-4 py-2 rounded-xl border border-slate-700 bg-slate-900/60 text-xs font-medium text-cyan-200 cursor-pointer hover:border-cyan-400 hover:text-cyan-100 hover:bg-slate-900/80 transition-colors">
                <Upload size={18} />
                <span>Upload Image</span>
                <input
                  id="shop-image"
                  name="image"
                  type="file"
                  accept="image/*"
                  onChange={handleImageUpload}
                  className="hidden"
                />
              </label>
            </div>
          </div>

          {/* Shop Details */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label
                htmlFor="shop-name"
                className="block text-xs font-medium tracking-wide text-slate-300 mb-2"
              >
                Shop Name
              </label>
              <input
                id="shop-name"
                type="text"
                name="name"
                value={formData.name || ''}
                onChange={handleChange}
                placeholder="Your shop name"
                className="w-full px-4 py-2.5 rounded-xl border border-slate-700 bg-slate-900/60 text-sm text-slate-50 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500 transition"
                required
              />
            </div>

            <div>
              <label
                htmlFor="shop-phone"
                className="block text-xs font-medium tracking-wide text-slate-300 mb-2"
              >
                Phone
              </label>
              <input
                id="shop-phone"
                type="tel"
                name="phone"
                value={formData.phone || ''}
                onChange={handleChange}
                placeholder="+91 98765 43210"
                className="w-full px-4 py-2.5 rounded-xl border border-slate-700 bg-slate-900/60 text-sm text-slate-50 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500 transition"
                required
              />
            </div>

            <div>
              <label
                htmlFor="shop-email"
                className="block text-xs font-medium tracking-wide text-slate-300 mb-2"
              >
                Email
              </label>
              <input
                id="shop-email"
                type="email"
                name="email"
                value={formData.email || ''}
                onChange={handleChange}
                placeholder="shop@email.com"
                className="w-full px-4 py-2.5 rounded-xl border border-slate-700 bg-slate-900/60 text-sm text-slate-50 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500 transition"
                required
              />
            </div>

            <div>
              <label
                htmlFor="shop-location"
                className="block text-xs font-medium tracking-wide text-slate-300 mb-2"
              >
                Location
              </label>
              <input
                id="shop-location"
                type="text"
                name="location"
                value={formData.location || ''}
                onChange={handleChange}
                placeholder="Shop address"
                className="w-full px-4 py-2.5 rounded-xl border border-slate-700 bg-slate-900/60 text-sm text-slate-50 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500 transition"
                required
              />
            </div>

            <div>
              <label
                htmlFor="shop-delivery-time"
                className="block text-xs font-medium tracking-wide text-slate-300 mb-2"
              >
                Delivery Time (minutes)
              </label>
              <input
                id="shop-delivery-time"
                type="number"
                name="deliveryTimeMinutes"
                value={formData.deliveryTimeMinutes || 30}
                onChange={handleChange}
                className="w-full px-4 py-2.5 rounded-xl border border-slate-700 bg-slate-900/60 text-sm text-slate-50 focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500 transition"
              />
            </div>

            <div>
              <label
                htmlFor="shop-delivery-fee"
                className="block text-xs font-medium tracking-wide text-slate-300 mb-2"
              >
                Delivery Fee (₹)
              </label>
              <input
                id="shop-delivery-fee"
                type="number"
                name="deliveryFee"
                value={formData.deliveryFee || 0}
                onChange={handleChange}
                className="w-full px-4 py-2.5 rounded-xl border border-slate-700 bg-slate-900/60 text-sm text-slate-50 focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500 transition"
              />
            </div>
          </div>

          <div>
            <label
              htmlFor="shop-description"
              className="block text-xs font-medium tracking-wide text-slate-300 mb-2"
            >
              Description
            </label>
            <textarea
              id="shop-description"
              name="description"
              value={formData.description || ''}
              onChange={handleChange}
              placeholder="Describe your shop..."
              rows="4"
              className="w-full px-4 py-2.5 rounded-xl border border-slate-700 bg-slate-900/60 text-sm text-slate-50 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500 transition"
            />
          </div>

          <button
            type="submit"
            disabled={saving}
            className="inline-flex items-center space-x-2 px-6 py-2.5 rounded-xl bg-gradient-to-r from-cyan-500 to-blue-600 text-sm font-medium text-white shadow-lg shadow-cyan-500/30 hover:from-cyan-400 hover:to-blue-500 transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
          >
            {saving && <Loader size={18} className="animate-spin" />}
            <span>{saving ? 'Saving...' : 'Save Shop'}</span>
          </button>
        </form>
      </div>
    </div>
  );
}
