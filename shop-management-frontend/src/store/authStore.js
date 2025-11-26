import { create } from 'zustand';
import api from '../services/api';

export const useAuthStore = create((set) => ({
  token: null,
  owner: null,
  loading: false,
  error: null,
  initialized: false,

  loadFromStorage: () => {
    const token = localStorage.getItem('token');
    const owner = localStorage.getItem('owner');
    if (token && owner) {
      set({ token, owner: JSON.parse(owner), initialized: true });
    } else {
      set({ initialized: true });
    }
  },

  register: async (data) => {
    set({ loading: true, error: null });
    try {
      const response = await api.post('/auth/register', data);
      localStorage.setItem('token', response.data.token);
      localStorage.setItem('owner', JSON.stringify(response.data.owner));
      set({ token: response.data.token, owner: response.data.owner, loading: false });
      return response.data;
    } catch (error) {
      set({ error: error.response?.data?.message || 'Registration failed', loading: false });
      throw error;
    }
  },

  login: async (email, password) => {
    set({ loading: true, error: null });
    try {
      const response = await api.post('/auth/login', { email, password });
      localStorage.setItem('token', response.data.token);
      localStorage.setItem('owner', JSON.stringify(response.data.owner));
      set({ token: response.data.token, owner: response.data.owner, loading: false });
      return response.data;
    } catch (error) {
      set({ error: error.response?.data?.message || 'Login failed', loading: false });
      throw error;
    }
  },

  logout: () => {
    localStorage.removeItem('token');
    localStorage.removeItem('owner');
    set({ token: null, owner: null });
  },

  updateProfile: async (data) => {
    set({ loading: true, error: null });
    try {
      const response = await api.put('/auth/profile', data);
      localStorage.setItem('owner', JSON.stringify(response.data.owner));
      set({ owner: response.data.owner, loading: false });
      return response.data;
    } catch (error) {
      set({ error: error.response?.data?.message || 'Update failed', loading: false });
      throw error;
    }
  },
}));
