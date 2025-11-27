import { create } from 'zustand';

export const useAdminAuthStore = create((set) => ({
  token: null,
  admin: null,
  loading: false,
  error: null,
  initialized: false,
  loadFromStorage: () => {
    const token = localStorage.getItem('admin_token');
    const admin = localStorage.getItem('admin_user');
    if (token && admin) {
      set({ token, admin: JSON.parse(admin), initialized: true });
    } else {
      set({ initialized: true });
    }
  },
  login: async (email, password) => {
    set({ loading: true, error: null });
    try {
      await new Promise((resolve) => setTimeout(resolve, 800));
      if (email !== 'rohit@gmail.com' || password !== 'rs965198') {
        throw new Error('Invalid admin credentials');
      }
      const adminUser = { id: 'admin-1', name: 'Admin User', email: 'rohit@gmail.com' };
      const token = 'mock-admin-token';
      localStorage.setItem('admin_token', token);
      localStorage.setItem('admin_user', JSON.stringify(adminUser));
      set({ token, admin: adminUser, loading: false });
      return adminUser;
    } catch (error) {
      set({ error: error.message || 'Login failed', loading: false });
      throw error;
    }
  },
  logout: () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    set({ token: null, admin: null });
  },
}));
