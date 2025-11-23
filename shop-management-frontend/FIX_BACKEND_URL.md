# Fix Backend URL - 404 Errors

## Problem

Frontend is connecting to wrong backend:
- ❌ Current: `finnsathi-ai-expense-monitor-backend-production-3515.up.railway.app`
- ✅ Should be: `finnsathi-shop-management-backend-production.up.railway.app`

## Root Cause

Vercel environment variable `REACT_APP_API_URL` is set to old backend URL.

## Solution

### Step 1: Update Vercel Environment Variables

1. **Go to Vercel Dashboard**
   - https://vercel.com/dashboard

2. **Select your project**
   - `finnsathi-shop-management` (or your project name)

3. **Go to Settings → Environment Variables**

4. **Find `REACT_APP_API_URL`**
   - Old value: `https://finnsathi-ai-expense-monitor-backend-production-3515.up.railway.app/api`
   - New value: `https://finnsathi-shop-management-backend-production.up.railway.app/api`

5. **Update the value**
   - Click edit
   - Change URL to shop management backend
   - Save

6. **Redeploy**
   - Go to Deployments
   - Click "Redeploy" on latest deployment
   - Or push to GitHub to trigger auto-deploy

### Step 2: Verify Locally

Update `.env` file:
```
REACT_APP_API_URL=https://finnsathi-shop-management-backend-production.up.railway.app/api
```

Test locally:
```bash
npm start
```

### Step 3: Commit and Push

```bash
git add .env.production
git commit -m "update backend url to shop management backend"
git push
```

---

## Environment Variables to Set in Vercel

```
REACT_APP_API_URL = https://finnsathi-shop-management-backend-production.up.railway.app/api
```

---

## After Fix

Expected behavior:
```
✅ Login works
✅ GET /api/shops/stats → 200
✅ GET /api/shops/my-shop → 200
✅ POST /api/shops/upload-image → 200
✅ GET /api/menu → 200
```

---

## Files

- ✅ `.env.production` - Recreated with correct URL
- ✅ `.env.example` - Already correct
- ✅ `src/services/api.js` - Uses environment variable correctly

---

## Quick Checklist

- [ ] Go to Vercel Dashboard
- [ ] Select project
- [ ] Go to Settings → Environment Variables
- [ ] Update REACT_APP_API_URL to shop management backend
- [ ] Redeploy
- [ ] Wait 2-3 minutes
- [ ] Test in browser
- [ ] Check network tab for correct API calls

---

**Status: Ready to Fix** 🔧
