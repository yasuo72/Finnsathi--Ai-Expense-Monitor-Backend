import React, { useEffect, useState } from 'react';
import { Loader } from 'lucide-react';
import { useAuthStore } from '../store/authStore';
import toast from 'react-hot-toast';

export default function ProfilePage() {
  const { owner, updateProfile } = useAuthStore();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [formData, setFormData] = useState({});

  useEffect(() => {
    if (owner) {
      setFormData(owner);
      setLoading(false);
    }
  }, [owner]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      await updateProfile(formData);
      toast.success('Profile updated successfully');
    } catch (error) {
      toast.error('Failed to update profile');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <div className="text-center py-12 text-slate-300 text-sm">Loading profile...</div>;
  }

  return (
    <div className="max-w-2xl">
      <div className="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 md:p-8 shadow-lg shadow-slate-950/60">
        <h1 className="text-2xl font-semibold text-slate-50 mb-2">Profile Settings</h1>
        <p className="text-xs text-slate-400 mb-6">Update your personal and business details for this shop account.</p>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium tracking-wide text-slate-300 mb-2">Full Name</label>
              <input
                type="text"
                name="name"
                value={formData.name || ''}
                onChange={handleChange}
                className="w-full px-4 py-2.5 rounded-xl border border-slate-700 bg-slate-900/60 text-sm text-slate-50 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500 transition"
              />
            </div>

            <div>
              <label className="block text-xs font-medium tracking-wide text-slate-300 mb-2">Email</label>
              <input
                type="email"
                name="email"
                value={formData.email || ''}
                disabled
                className="w-full px-4 py-2.5 rounded-xl border border-slate-700 bg-slate-900/40 text-sm text-slate-400 cursor-not-allowed"
              />
            </div>

            <div>
              <label className="block text-xs font-medium tracking-wide text-slate-300 mb-2">Phone</label>
              <input
                type="tel"
                name="phone"
                value={formData.phone || ''}
                onChange={handleChange}
                className="w-full px-4 py-2.5 rounded-xl border border-slate-700 bg-slate-900/60 text-sm text-slate-50 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500 transition"
              />
            </div>

            <div>
              <label className="block text-xs font-medium tracking-wide text-slate-300 mb-2">Business Name</label>
              <input
                type="text"
                name="businessName"
                value={formData.businessName || ''}
                onChange={handleChange}
                className="w-full px-4 py-2.5 rounded-xl border border-slate-700 bg-slate-900/60 text-sm text-slate-50 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500 transition"
              />
            </div>

            <div>
              <label className="block text-xs font-medium tracking-wide text-slate-300 mb-2">Business Type</label>
              <select
                name="businessType"
                value={formData.businessType || ''}
                onChange={handleChange}
                className="w-full px-4 py-2.5 rounded-xl border border-slate-700 bg-slate-900/60 text-sm text-slate-50 focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500 transition"
              >
                <option value="restaurant">Restaurant</option>
                <option value="cafe">Cafe</option>
                <option value="bakery">Bakery</option>
                <option value="cloud_kitchen">Cloud Kitchen</option>
                <option value="other">Other</option>
              </select>
            </div>
          </div>

          <button
            type="submit"
            disabled={saving}
            className="inline-flex items-center space-x-2 px-6 py-2.5 rounded-xl bg-gradient-to-r from-cyan-500 to-blue-600 text-sm font-medium text-white hover:from-cyan-400 hover:to-blue-500 disabled:opacity-60 disabled:cursor-not-allowed shadow-lg shadow-cyan-500/30"
          >
            {saving && <Loader size={18} className="animate-spin" />}
            <span>{saving ? 'Saving...' : 'Save Changes'}</span>
          </button>
        </form>
      </div>
    </div>
  );
}
