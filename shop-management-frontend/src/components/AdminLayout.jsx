import React, { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { Menu, X, LogOut, Shield, BarChart2, Store, Package } from 'lucide-react';
import { useAdminAuthStore } from '../store/adminAuthStore';

export default function AdminLayout({ children }) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const location = useLocation();
  const navigate = useNavigate();
  const { admin, logout } = useAdminAuthStore();

  const handleLogout = () => {
    logout();
    navigate('/admin/login');
  };

  const navItems = [
    { path: '/admin', icon: BarChart2, label: 'Overview' },
    { path: '/admin/shops', icon: Store, label: 'Shops' },
    { path: '/admin/orders', icon: Package, label: 'Orders' },
  ];
  const currentNavItem = navItems.find((item) => item.path === location.pathname);

  return (
    <div className="relative flex h-screen bg-slate-950 text-slate-100 overflow-hidden">
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top,_rgba(251,191,36,0.18),transparent_55%),radial-gradient(circle_at_bottom,_rgba(239,68,68,0.32),transparent_55%)]" />
      <div
        className={`fixed inset-y-0 left-0 z-50 w-64 bg-slate-900/80 border-r border-slate-800 shadow-[0_0_40px_rgba(15,23,42,0.9)] backdrop-blur-xl transform transition-transform duration-300 ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        } md:relative md:translate-x-0`}
      >
        <div className="p-6 border-b border-slate-800/80 flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold tracking-tight">
              <span className="bg-gradient-to-r from-amber-300 to-red-400 bg-clip-text text-transparent">
                FinSathi
              </span>
            </h1>
            <p className="mt-1 text-xs text-slate-400">Admin Control Center</p>
          </div>
          <div className="h-9 w-9 rounded-xl bg-gradient-to-tr from-amber-400 to-red-500 flex items-center justify-center text-xs font-semibold text-white shadow-lg shadow-amber-500/40">
            AC
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
                    ? 'bg-gradient-to-r from-amber-400 to-red-500 text-slate-950 shadow-md shadow-amber-500/40'
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

      <div className="flex-1 flex flex-col overflow-hidden">
        <header className="border-b border-slate-800/80 bg-slate-900/60 backdrop-blur-xl">
          <div className="flex items-center px-4 py-3 md:px-6 md:py-4">
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="md:hidden inline-flex items-center justify-center rounded-full border border-slate-700 bg-slate-800/80 p-2 text-slate-200 hover:border-amber-400/70 hover:text-amber-300 transition-colors"
            >
              {sidebarOpen ? <X size={22} /> : <Menu size={22} />}
            </button>
            <div className="ml-3 flex flex-1 items-center justify-between">
              <div>
                <p className="text-[11px] uppercase tracking-[0.2em] text-slate-400">Admin Console</p>
                <div className="mt-1 flex items-center space-x-2">
                  <h2 className="text-lg md:text-xl font-semibold text-slate-50">
                    {currentNavItem?.label || 'Overview'}
                  </h2>
                  <span className="inline-flex items-center rounded-full border border-amber-400/60 bg-amber-500/10 px-2 py-[2px] text-[10px] font-medium text-amber-200">
                    Secure
                  </span>
                </div>
              </div>
              <div className="flex items-center space-x-3 md:space-x-4">
                <div className="hidden md:flex flex-col items-end text-xs">
                  <span className="font-medium text-slate-100">{admin?.name || 'Admin'}</span>
                  <span className="text-slate-400">{admin?.email || 'admin@finsathi.app'}</span>
                </div>
                <div className="hidden md:inline-flex h-9 w-9 items-center justify-center rounded-full border border-slate-700 bg-slate-800/80 text-amber-300">
                  <Shield size={18} />
                </div>
              </div>
            </div>
          </div>
        </header>

        <main className="flex-1 overflow-auto">
          <div className="px-4 py-4 md:px-6 md:py-6">
            {children}
          </div>
        </main>
      </div>

      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black/60 z-40 md:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}
    </div>
  );
}
