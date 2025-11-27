import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import { useAdminAuthStore } from '../store/adminAuthStore';
import AdminLayout from './AdminLayout';

export default function AdminProtectedRoute() {
  const { token } = useAdminAuthStore();

  if (!token) {
    return <Navigate to="/admin/login" replace />;
  }

  return (
    <AdminLayout>
      <Outlet />
    </AdminLayout>
  );
}
