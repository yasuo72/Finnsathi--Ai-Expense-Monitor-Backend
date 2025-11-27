import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Mail, Lock, Loader } from 'lucide-react';
import toast from 'react-hot-toast';
import { useAdminAuthStore } from '../store/adminAuthStore';

export default function AdminLoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const { login, loading, loadFromStorage, token, initialized } = useAdminAuthStore();
  const navigate = useNavigate();

  useEffect(() => {
    loadFromStorage();
  }, [loadFromStorage]);

  useEffect(() => {
    if (token) {
      navigate('/admin', { replace: true });
    }
  }, [token, navigate]);

  if (!initialized) {
    return null;
  }

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await login(email, password);
      toast.success('Admin login successful');
      navigate('/admin', { replace: true });
    } catch (error) {
      const message = error?.response?.data?.message || error.message || 'Admin login failed';
      toast.error(message);
    }
  };

  return (
    <div className="relative min-h-screen bg-slate-950 text-slate-100 flex items-center justify-center p-4 overflow-hidden">
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top,_rgba(251,191,36,0.24),transparent_55%),radial-gradient(circle_at_bottom,_rgba(239,68,68,0.35),transparent_55%)]" />
      <div className="relative w-full max-w-md">
        <div className="mb-6 text-center">
          <p className="text-[11px] uppercase tracking-[0.25em] text-slate-400">FinSathi</p>
          <h1 className="mt-2 text-3xl font-semibold tracking-tight">
            <span className="bg-gradient-to-r from-amber-300 to-red-400 bg-clip-text text-transparent">
              Admin Console Login
            </span>
          </h1>
          <p className="mt-2 text-xs text-slate-400">
            Access system-wide insights and manage all shops securely.
          </p>
        </div>

        <div className="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 md:p-8 shadow-[0_0_40px_rgba(15,23,42,0.9)] backdrop-blur-xl">
          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label
                htmlFor="admin-login-email"
                className="block text-xs font-medium tracking-wide text-slate-300 mb-2"
              >
                Admin Email
              </label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
                <input
                  id="admin-login-email"
                  name="email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@finsathi.app"
                  className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-700 bg-slate-900/60 text-sm text-slate-50 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-amber-400 focus:border-amber-400 transition"
                  required
                />
              </div>
            </div>

            <div>
              <label
                htmlFor="admin-login-password"
                className="block text-xs font-medium tracking-wide text-slate-300 mb-2"
              >
                Password
              </label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
                <input
                  id="admin-login-password"
                  name="password"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-700 bg-slate-900/60 text-sm text-slate-50 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-amber-400 focus:border-amber-400 transition"
                  required
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full inline-flex items-center justify-center rounded-xl bg-gradient-to-r from-amber-400 to-red-500 px-4 py-2.5 text-sm font-medium text-slate-950 shadow-lg shadow-amber-500/30 hover:from-amber-300 hover:to-red-400 disabled:opacity-60 disabled:cursor-not-allowed transition"
            >
              {loading && <Loader size={18} className="mr-2 animate-spin" />}
              <span>{loading ? 'Authenticating...' : 'Login as Admin'}</span>
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
