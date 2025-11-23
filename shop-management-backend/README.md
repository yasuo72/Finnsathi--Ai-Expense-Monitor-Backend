# FinSathi Shop Management Backend

Node.js + Express backend for managing shops, menus, and orders.

## Features

- **Authentication**: JWT-based authentication for shop owners
- **Shop Management**: Create and manage shop details
- **Menu Management**: Add, edit, delete menu items
- **Order Management**: Handle customer orders and tracking
- **Image Upload**: Cloudinary integration for image uploads
- **Statistics**: Real-time shop statistics and analytics

## Tech Stack

- Node.js
- Express.js
- MongoDB
- JWT
- Cloudinary
- Bcryptjs

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

4. Update `.env` with your credentials:
```
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret
CLOUDINARY_NAME=your_cloudinary_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
PORT=5001
```

## Running Locally

```bash
npm run dev
```

Server will start at `http://localhost:5001`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new shop owner
- `POST /api/auth/login` - Login shop owner
- `GET /api/auth/profile` - Get owner profile
- `PUT /api/auth/profile` - Update owner profile

### Shop Management
- `POST /api/shops` - Create shop
- `GET /api/shops/my-shop` - Get shop details
- `PUT /api/shops` - Update shop
- `POST /api/shops/upload-image` - Upload shop image
- `GET /api/shops/stats` - Get shop statistics
- `PUT /api/shops/toggle-status` - Toggle shop open/close

### Menu Management
- `POST /api/menu` - Add menu item
- `GET /api/menu` - Get shop menu
- `PUT /api/menu/:itemId` - Update menu item
- `DELETE /api/menu/:itemId` - Delete menu item
- `POST /api/menu/:itemId/upload-image` - Upload item image
- `PUT /api/menu/:itemId/toggle-availability` - Toggle availability

### Order Management
- `GET /api/orders` - Get shop orders
- `GET /api/orders/:orderId` - Get order details
- `PUT /api/orders/:orderId/status` - Update order status
- `PUT /api/orders/:orderId/cancel` - Cancel order
- `GET /api/orders/stats/overview` - Get order statistics

## Deployment

### Railway
1. Push code to GitHub
2. Connect repository to Railway
3. Set environment variables in Railway dashboard
4. Deploy

### Other Platforms
Use the provided Dockerfile or Procfile for deployment.

## Environment Variables

- `MONGODB_URI`: MongoDB connection string
- `JWT_SECRET`: Secret key for JWT tokens
- `CLOUDINARY_NAME`: Cloudinary cloud name
- `CLOUDINARY_API_KEY`: Cloudinary API key
- `CLOUDINARY_API_SECRET`: Cloudinary API secret
- `PORT`: Server port (default: 5001)
- `NODE_ENV`: Environment (development/production)

## Project Structure

```
├── models/          # MongoDB schemas
├── controllers/     # Route controllers
├── routes/          # API routes
├── middleware/      # Custom middleware
├── services/        # Business logic
└── server.js        # Entry point
```
