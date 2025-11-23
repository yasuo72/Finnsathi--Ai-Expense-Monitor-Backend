# FinSathi Shop Management Frontend

Modern React dashboard for shop owners to manage their shops, menus, and orders.

## Features

- **Shop Management**: Create and manage shop details
- **Menu Management**: Add, edit, delete menu items with images
- **Order Management**: View and manage customer orders
- **Dashboard**: Real-time statistics and analytics
- **Profile Management**: Update shop owner profile
- **Responsive Design**: Works on desktop and mobile devices

## Tech Stack

- React 18
- React Router v6
- Zustand (State Management)
- Tailwind CSS
- Lucide Icons
- Recharts
- Axios

## Installation

1. Clone the repository
2. Install dependencies:
```bash
npm install
```

3. Create `.env` file:
```bash
cp .env.example .env
```

4. Update `.env` with your API URL:
```
REACT_APP_API_URL=http://localhost:5001/api
```

## Running Locally

```bash
npm start
```

The app will open at `http://localhost:3000`

## Building for Production

```bash
npm run build
```

## Deployment

### Vercel
1. Push code to GitHub
2. Connect repository to Vercel
3. Set environment variables in Vercel dashboard
4. Deploy

### Other Platforms
The build output is in the `build/` directory. Deploy it to any static hosting service.

## Environment Variables

- `REACT_APP_API_URL`: Backend API base URL

## Project Structure

```
src/
├── pages/           # Page components
├── components/      # Reusable components
├── store/          # Zustand stores
├── services/       # API services
└── index.js        # Entry point
```
