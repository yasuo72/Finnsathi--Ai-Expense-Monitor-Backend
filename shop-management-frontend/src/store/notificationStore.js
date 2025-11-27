import { create } from 'zustand';
import api from '../services/api';

export const useNotificationStore = create((set, get) => ({
  notifications: [],
  unreadCount: 0,
  loading: false,
  error: null,
  async fetchNotifications(limit = 20) {
    try {
      set({ loading: true, error: null });
      const response = await api.get('/notifications', { params: { limit } });
      const notifications = Array.isArray(response.data?.notifications)
        ? response.data.notifications
        : [];
      const unreadCount = typeof response.data?.unreadCount === 'number'
        ? response.data.unreadCount
        : 0;
      set({ notifications, unreadCount, loading: false });
      return unreadCount;
    } catch (error) {
      console.error('Failed to load notifications:', error.response?.data || error.message || error);
      set({ loading: false, error: error.message || 'Failed to load notifications' });
      return get().unreadCount;
    }
  },
  async markAllRead() {
    try {
      await api.put('/notifications/mark-all-read');
      set((state) => ({
        notifications: state.notifications.map((n) => ({ ...n, isRead: true })),
        unreadCount: 0,
      }));
    } catch (error) {
      console.error('Failed to mark all notifications as read:', error.response?.data || error.message || error);
    }
  },
  async markAsRead(id) {
    try {
      const response = await api.put(`/notifications/${id}/read`);
      const updated = response.data?.notification;
      const unreadCount = typeof response.data?.unreadCount === 'number'
        ? response.data.unreadCount
        : undefined;
      set((state) => {
        const notifications = state.notifications.map((n) =>
          n._id === id ? { ...n, ...updated } : n
        );
        return {
          notifications,
          unreadCount: typeof unreadCount === 'number' ? unreadCount : state.unreadCount,
        };
      });
    } catch (error) {
      console.error('Failed to mark notification as read:', error.response?.data || error.message || error);
    }
  },
}));
