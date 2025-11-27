import React, { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Bell } from 'lucide-react';
import { useNotificationStore } from '../store/notificationStore';

export default function NotificationsPage() {
  const navigate = useNavigate();
  const { notifications, unreadCount, loading, error, fetchNotifications, markAllRead, markAsRead } =
    useNotificationStore();

  useEffect(() => {
    fetchNotifications(50);
  }, [fetchNotifications]);

  const handleOpenNotification = async (notification) => {
    if (!notification.isRead) {
      await markAsRead(notification._id);
    }
    if (notification.orderId) {
      navigate(`/orders/${notification.orderId}`);
    }
  };

  return (
    <div className="max-w-4xl space-y-4">
      <div className="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 md:p-8 shadow-lg shadow-slate-950/60">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h1 className="text-2xl font-semibold text-slate-50 flex items-center gap-2">
              <Bell size={20} className="text-cyan-400" />
              <span>Notifications</span>
            </h1>
            <p className="text-xs text-slate-400 mt-1">
              Latest events for your shop and orders.
            </p>
          </div>
          {unreadCount > 0 && (
            <button
              type="button"
              onClick={markAllRead}
              className="text-[11px] font-medium text-cyan-300 hover:text-cyan-200 border border-cyan-500/50 px-3 py-1 rounded-full bg-cyan-500/10"
            >
              Mark all as read
            </button>
          )}
        </div>

        {loading && (
          <div className="text-sm text-slate-300 py-6">Loading notifications...</div>
        )}
        {error && !loading && (
          <div className="text-sm text-red-300 py-6">{error}</div>
        )}
        {!loading && !error && notifications.length === 0 && (
          <div className="text-sm text-slate-400 py-6">No notifications yet.</div>
        )}

        {!loading && !error && notifications.length > 0 && (
          <div className="space-y-2">
            {notifications.map((notification) => (
              <button
                key={notification._id}
                type="button"
                onClick={() => handleOpenNotification(notification)}
                className={`w-full text-left rounded-xl border px-4 py-3 text-sm transition-colors flex items-start justify-between gap-3 ${{
                  true: 'border-slate-700 bg-slate-900/80 hover:border-cyan-500/60 hover:bg-slate-900',
                  false: 'border-slate-800 bg-slate-950/80 hover:border-slate-600 hover:bg-slate-900/80',
                }[String(!notification.isRead)]}`}
              >
                <div>
                  <p className="text-slate-100 font-medium text-xs md:text-sm">{notification.title}</p>
                  <p className="text-[11px] text-slate-400 mt-1">{notification.message}</p>
                  <p className="text-[10px] text-slate-500 mt-1">
                    {notification.createdAt
                      ? new Date(notification.createdAt).toLocaleString()
                      : ''}
                  </p>
                </div>
                {!notification.isRead && (
                  <span className="mt-1 inline-flex h-2 w-2 rounded-full bg-cyan-400" />
                )}
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
