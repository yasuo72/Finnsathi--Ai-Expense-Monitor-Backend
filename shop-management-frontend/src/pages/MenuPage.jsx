import React, { useEffect, useState } from 'react';
import { Plus, Edit2, Trash2, Upload, Loader } from 'lucide-react';
import api from '../services/api';
import toast from 'react-hot-toast';

export default function MenuPage() {
  const [menuItems, setMenuItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingItem, setEditingItem] = useState(null);
  const [saving, setSaving] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    price: '',
    description: '',
    category: 'Main Course',
    isVegetarian: false,
    prepTimeMinutes: 15,
  });

  useEffect(() => {
    fetchMenuItems();
  }, []);

  const fetchMenuItems = async () => {
    try {
      const response = await api.get('/menu');
      setMenuItems(response.data);
    } catch (error) {
      if (error.response?.status === 404) {
        // No shop created yet for this owner - show empty menu instead of error
        console.warn('No shop found when loading menu; showing empty menu list.');
        setMenuItems([]);
      } else {
        toast.error('Failed to load menu items');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value,
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      if (editingItem) {
        await api.put(`/menu/${editingItem._id}`, formData);
        toast.success('Menu item updated');
      } else {
        await api.post('/menu', formData);
        toast.success('Menu item added');
      }
      setShowForm(false);
      setEditingItem(null);
      setFormData({
        name: '',
        price: '',
        description: '',
        category: 'Main Course',
        isVegetarian: false,
        prepTimeMinutes: 15,
      });
      fetchMenuItems();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to save item');
    } finally {
      setSaving(false);
    }
  };

  const handleEdit = (item) => {
    setEditingItem(item);
    setFormData(item);
    setShowForm(true);
  };

  const handleDelete = async (itemId) => {
    if (!window.confirm('Are you sure?')) return;
    try {
      await api.delete(`/menu/${itemId}`);
      toast.success('Menu item deleted');
      fetchMenuItems();
    } catch (error) {
      toast.error('Failed to delete item');
    }
  };

  const handleImageUpload = async (e, itemId) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const formDataWithFile = new FormData();
    formDataWithFile.append('image', file);

    try {
      await api.post(`/menu/${itemId}/upload-image`, formDataWithFile, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      toast.success('Image uploaded');
      fetchMenuItems();
    } catch (error) {
      toast.error('Failed to upload image');
    }
  };

  if (loading) {
    return <div className="text-center py-12">Loading...</div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Menu Items</h1>
        <button
          onClick={() => {
            setEditingItem(null);
            setFormData({
              name: '',
              price: '',
              description: '',
              category: 'Main Course',
              isVegetarian: false,
              prepTimeMinutes: 15,
            });
            setShowForm(!showForm);
          }}
          className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
        >
          <Plus size={20} />
          <span>Add Item</span>
        </button>
      </div>

      {showForm && (
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            {editingItem ? 'Edit Item' : 'Add New Item'}
          </h2>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Name</label>
                <input
                  type="text"
                  name="name"
                  value={formData.name}
                  onChange={handleChange}
                  placeholder="Item name"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Price (₹)</label>
                <input
                  type="number"
                  name="price"
                  value={formData.price}
                  onChange={handleChange}
                  placeholder="0"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Category</label>
                <select
                  name="category"
                  value={formData.category}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option>Main Course</option>
                  <option>Appetizers</option>
                  <option>Desserts</option>
                  <option>Beverages</option>
                  <option>Sides</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Prep Time (min)</label>
                <input
                  type="number"
                  name="prepTimeMinutes"
                  value={formData.prepTimeMinutes}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Description</label>
              <textarea
                name="description"
                value={formData.description}
                onChange={handleChange}
                placeholder="Item description"
                rows="3"
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div className="flex items-center">
              <input
                type="checkbox"
                name="isVegetarian"
                checked={formData.isVegetarian}
                onChange={handleChange}
                className="w-4 h-4 text-blue-600 rounded"
              />
              <label className="ml-2 text-sm font-medium text-gray-700">Vegetarian</label>
            </div>

            <div className="flex space-x-3">
              <button
                type="submit"
                disabled={saving}
                className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
              >
                {saving && <Loader size={20} className="animate-spin" />}
                <span>{saving ? 'Saving...' : 'Save'}</span>
              </button>
              <button
                type="button"
                onClick={() => setShowForm(false)}
                className="px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {menuItems.map((item) => (
          <div key={item._id} className="bg-white rounded-lg shadow overflow-hidden">
            {item.imageUrl && (
              <img src={item.imageUrl} alt={item.name} className="w-full h-40 object-cover" />
            )}
            <div className="p-4">
              <h3 className="font-semibold text-gray-900">{item.name}</h3>
              <p className="text-sm text-gray-600 mt-1">{item.description}</p>
              <div className="flex items-center justify-between mt-4">
                <span className="text-lg font-bold text-blue-600">₹{item.price}</span>
                <span className="text-xs bg-gray-100 px-2 py-1 rounded">{item.category}</span>
              </div>
              {item.isVegetarian && (
                <div className="mt-2 text-xs text-green-600 font-medium">🌱 Vegetarian</div>
              )}
              <div className="flex space-x-2 mt-4">
                <label className="flex-1 flex items-center justify-center space-x-1 px-3 py-2 bg-blue-50 text-blue-600 rounded cursor-pointer hover:bg-blue-100">
                  <Upload size={16} />
                  <span className="text-xs">Image</span>
                  <input
                    type="file"
                    accept="image/*"
                    onChange={(e) => handleImageUpload(e, item._id)}
                    className="hidden"
                  />
                </label>
                <button
                  onClick={() => handleEdit(item)}
                  className="flex-1 flex items-center justify-center space-x-1 px-3 py-2 bg-yellow-50 text-yellow-600 rounded hover:bg-yellow-100"
                >
                  <Edit2 size={16} />
                </button>
                <button
                  onClick={() => handleDelete(item._id)}
                  className="flex-1 flex items-center justify-center space-x-1 px-3 py-2 bg-red-50 text-red-600 rounded hover:bg-red-100"
                >
                  <Trash2 size={16} />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
