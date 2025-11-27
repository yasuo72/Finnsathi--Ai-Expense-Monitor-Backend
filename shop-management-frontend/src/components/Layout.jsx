import React, { useEffect, useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { Menu, X, LogOut, BarChart3, ShoppingBag, UtensilsCrossed, Package, User, Bell, Settings } from 'lucide-react';
import { useAuthStore } from '../store/authStore';
import { useNotificationStore } from '../store/notificationStore';
import api from '../services/api';
import toast from 'react-hot-toast';

export default function Layout({ children }) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const location = useLocation();
  const navigate = useNavigate();
  const { owner, logout } = useAuthStore();
  const [shopIsOpen, setShopIsOpen] = useState(null);
  const [shopStatusLoading, setShopStatusLoading] = useState(false);
  const { unreadCount, fetchNotifications } = useNotificationStore();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  useEffect(() => {
    const fetchShopStatus = async () => {
      try {
        const response = await api.get('/shops/my-shop');
        if (response.data && typeof response.data.isOpen === 'boolean') {
          setShopIsOpen(response.data.isOpen);
        } else {
          setShopIsOpen(true);
        }
      } catch (error) {
        console.error('Failed to load shop status for header:', error.response?.data || error.message || error);
      }
    };

    fetchShopStatus();
  }, []);

  useEffect(() => {
    let previousUnread = 0;
    let firstRun = true;

    const checkNotifications = async () => {
      const newCount = await fetchNotifications(10);
      if (!firstRun && newCount > previousUnread) {
        if (typeof document !== 'undefined' && document.hidden && typeof window !== 'undefined') {
          if ('Notification' in window) {
            if (Notification.permission === 'granted') {
              // eslint-disable-next-line no-new
              new Notification('New order received', {
                body: 'Open FinSathi Shop to view the latest orders.',
              });
            } else if (Notification.permission === 'default') {
              Notification.requestPermission();
            }
          }
        }
      }
      previousUnread = newCount;
      firstRun = false;
    };

    checkNotifications();
    const interval = setInterval(checkNotifications, 30000);
    return () => clearInterval(interval);
  }, [fetchNotifications]);

  const handleToggleShopStatus = async () => {
    try {
      setShopStatusLoading(true);
      const response = await api.put('/shops/toggle-status');
      const isOpen = response.data?.isOpen;
      if (typeof isOpen === 'boolean') {
        setShopIsOpen(isOpen);
        toast.success(isOpen ? 'Shop is now live' : 'Shop is now offline');
      } else {
        toast.error('Unexpected response while updating shop status');
      }
    } catch (error) {
      console.error('Failed to toggle shop status:', error.response?.data || error.message || error);
      toast.error(error.response?.data?.message || 'Failed to update shop status');
    } finally {
      setShopStatusLoading(false);
    }
  };

  const navItems = [
    { path: '/dashboard', icon: BarChart3, label: 'Dashboard' },
    { path: '/shop', icon: ShoppingBag, label: 'Shop' },
    { path: '/menu', icon: UtensilsCrossed, label: 'Menu' },
    { path: '/orders', icon: Package, label: 'Orders' },
    { path: '/profile', icon: User, label: 'Profile' },
  ];
  const currentNavItem = navItems.find((item) => item.path === location.pathname);

  return (
    <div className="relative flex h-screen bg-slate-950 text-slate-100 overflow-hidden">
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top,_rgba(56,189,248,0.22),transparent_55%),radial-gradient(circle_at_bottom,_rgba(129,140,248,0.35),transparent_55%)]" />

      {/* Sidebar */}
      <div
        className={`fixed inset-y-0 left-0 z-50 w-64 bg-slate-900/80 border-r border-slate-800 shadow-[0_0_40px_rgba(15,23,42,0.9)] backdrop-blur-xl transform transition-transform duration-300 ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        } md:relative md:translate-x-0`}
      >
        <div className="p-6 border-b border-slate-800/80 flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold tracking-tight">
              <span className="bg-gradient-to-r from-cyan-400 to-blue-500 bg-clip-text text-transparent">
                FinSathi
              </span>
            </h1>
            <p className="mt-1 text-xs text-slate-400">Shop Management Console</p>
          </div>
          <div className="h-9 w-9 rounded-xl bg-gradient-to-tr from-cyan-500 to-indigo-500 flex items-center justify-center text-xs font-semibold text-white shadow-lg shadow-cyan-500/40">
            FS
          </div>
        </div>

        <nav className="p-4 space-y-2">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`flex items-center space-x-3 px-4 py-3 rounded-xl text-sm font-medium tracking-tight transition-all ${
                  isActive
                    ? 'bg-gradient-to-r from-cyan-500 to-blue-600 text-white shadow-md shadow-cyan-500/40'
                    : 'text-slate-300 hover:bg-slate-800/70 hover:text-white'
                }`}
                onClick={() => setSidebarOpen(false)}
              >
                <Icon size={20} />
                <span>{item.label}</span>
              </Link>
            );
          })}
        </nav>

        <div className="absolute bottom-0 left-0 right-0 p-4 border-t border-slate-800/80">
          <button
            onClick={handleLogout}
            className="flex items-center space-x-3 w-full px-4 py-3 rounded-xl text-sm font-medium text-rose-400 hover:text-rose-300 hover:bg-rose-500/10 transition-colors"
          >
            <LogOut size={20} />
            <span>Logout</span>
          </button>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Header */}
        <header className="border-b border-slate-800/80 bg-slate-900/60 backdrop-blur-xl">
          <div className="flex items-center px-4 py-3 md:px-6 md:py-4">
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="md:hidden inline-flex items-center justify-center rounded-full border border-slate-700 bg-slate-800/80 p-2 text-slate-200 hover:border-cyan-400/70 hover:text-cyan-300 transition-colors"
            >
              {sidebarOpen ? <X size={22} /> : <Menu size={22} />}
            </button>
            <div className="ml-3 flex flex-1 items-center justify-between">
              <div>
                <p className="text-[11px] uppercase tracking-[0.2em] text-slate-400">FinSathi Shop</p>
                <div className="mt-1 flex items-center space-x-2">
                  <h2 className="text-lg md:text-xl font-semibold text-slate-50">
                    {currentNavItem?.label || 'Dashboard'}
                  </h2>
                  <button
                    type="button"
                    onClick={handleToggleShopStatus}
                    disabled={shopStatusLoading || shopIsOpen === null}
                    className={`inline-flex items-center rounded-full px-2 py-[2px] text-[10px] font-medium border transition-colors ${
                      shopIsOpen
                        ? 'border-emerald-400/60 bg-emerald-500/10 text-emerald-300'
                        : 'border-slate-500 bg-slate-800/80 text-slate-300'
                    } ${shopStatusLoading ? 'opacity-60 cursor-wait' : 'cursor-pointer'}`}
                  >
                    <span
                      className={`mr-1 h-1.5 w-1.5 rounded-full ${
                        shopIsOpen ? 'bg-emerald-400' : 'bg-slate-400'
                      }`}
                    />
                    {shopIsOpen ? 'Live' : 'Paused'}
                  </button>
                </div>
              </div>
              <div className="flex items-center space-x-3 md:space-x-4">
                <div className="hidden md:flex flex-col items-end text-xs">
                  <span className="font-medium text-slate-100">{owner?.name || 'Shop Owner'}</span>
                  <span className="text-slate-400">{owner?.email}</span>
                </div>
                <button
                  type="button"
                  onClick={() => navigate('/notifications')}
                  className="relative inline-flex h-9 w-9 items-center justify-center rounded-full border border-slate-700 bg-slate-800/80 text-slate-200 hover:border-cyan-400/70 hover:text-cyan-300 hover:shadow-[0_0_0_1px_rgba(34,211,238,0.8)] transition-all"
                  aria-label="Notifications"
                >
                  <Bell size={18} />
                  {unreadCount > 0 && (
                    <span className="absolute -top-0.5 -right-0.5 inline-flex min-w-[16px] h-4 items-center justify-center rounded-full bg-cyan-500 text-[10px] font-semibold text-slate-950 px-1">
                      {unreadCount > 9 ? '9+' : unreadCount}
                    </span>
                  )}
                </button>
                <button
                  type="button"
                  onClick={() => navigate('/profile')}
                  className="hidden md:inline-flex h-9 w-9 items-center justify-center rounded-full border border-slate-700 bg-slate-800/80 text-slate-200 hover:border-blue-400/70 hover:text-blue-300 transition-all"
                  aria-label="Settings"
                >
                  <Settings size={18} />
                </button>
              </div>
            </div>
          </div>
        </header>

        {/* Page Content */}
        <main className="flex-1 overflow-auto">
          <div className="px-4 py-4 md:px-6 md:py-6">
            {children}
          </div>
        </main>
      </div>

      {/* Mobile Overlay */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black/60 z-40 md:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}
    </div>
  );
}
