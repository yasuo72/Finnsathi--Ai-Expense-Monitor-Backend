import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shop_models.dart';

class ShopService with ChangeNotifier {
  // Singleton pattern
  static final ShopService _instance = ShopService._internal();

  factory ShopService() {
    return _instance;
  }

  ShopService._internal();

  // Shop data
  List<Shop> _shops = [];
  List<Shop> get shops => _shops;

  final Map<String, List<MenuItem>> _shopMenus = {};
  List<MenuItem>? getMenuForShop(String shopId) => _shopMenus[shopId];

  // Favorites
  final List<Shop> _favoriteShops = [];
  List<Shop> get favoriteShops => _favoriteShops;
  static const String _favoriteShopIdsKey = 'shop_favorite_ids';

  // Cart
  final Map<String, List<CartItem>> _cartItems = {};
  List<CartItem> getCartItems(String shopName) => _cartItems[shopName] ?? [];

  // Orders
  final List<Order> _orders = [];
  List<Order> get orders => _orders;

  // Reviews
  final Map<String, List<Review>> _shopReviews = {};
  List<Review> getShopReviews(String shopName) => _shopReviews[shopName] ?? [];

  // Filter settings
  Map<String, dynamic> _filterSettings = {
    'rating': 0.0,
    'priceRange': const RangeValues(0, 500),
    'deliveryTime': 60,
    'cuisineTypes': <String>[],
    'dietary': <String>[],
    'sortBy': 'rating',
    'verifiedOnly': false,
  };
  Map<String, dynamic> get filterSettings => _filterSettings;

  // Search query
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Initialize with data
  Future<void> initialize(List<Shop> initialShops) async {
    _shops = initialShops;
    await _loadFavoritesFromStorage();
    notifyListeners();
  }

  Future<void> _loadFavoritesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_favoriteShopIdsKey) ?? <String>[];

      _favoriteShops
        ..clear()
        ..addAll(
          _shops
              .where((shop) => ids.contains(shop.id))
              .map((shop) => shop.copyWith(isFavorite: true)),
        );

      _shops =
          _shops
              .map((shop) => shop.copyWith(isFavorite: ids.contains(shop.id)))
              .toList();
    } catch (_) {
      // Ignore persistence errors to avoid breaking UI
    }
  }

  // Filter shops based on current filter settings and search query
  List<Shop> getFilteredShops() {
    List<Shop> filteredShops = List.from(_shops);

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filteredShops =
          filteredShops.where((shop) {
            return shop.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                shop.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                shop.tags.any(
                  (tag) =>
                      tag.toLowerCase().contains(_searchQuery.toLowerCase()),
                );
          }).toList();
    }

    // Apply rating filter
    if (_filterSettings['rating'] > 0) {
      filteredShops =
          filteredShops
              .where((shop) => shop.rating >= _filterSettings['rating'])
              .toList();
    }

    // Apply price range filter (based on average menu item price)
    final priceRange = _filterSettings['priceRange'] as RangeValues;
    filteredShops =
        filteredShops.where((shop) {
          final avgPrice =
              shop.menu.isEmpty
                  ? 0
                  : shop.menu
                          .map((item) => item.price)
                          .reduce((a, b) => a + b) /
                      shop.menu.length;
          return avgPrice >= priceRange.start && avgPrice <= priceRange.end;
        }).toList();

    // Apply delivery time filter
    filteredShops =
        filteredShops
            .where(
              (shop) =>
                  shop.deliveryTimeMinutes <= _filterSettings['deliveryTime'],
            )
            .toList();

    // Apply cuisine types filter
    final cuisineTypes = _filterSettings['cuisineTypes'] as List<String>;
    if (cuisineTypes.isNotEmpty) {
      filteredShops =
          filteredShops
              .where(
                (shop) => shop.tags.any((tag) => cuisineTypes.contains(tag)),
              )
              .toList();
    }

    // Apply dietary preferences filter
    final dietaryPreferences = _filterSettings['dietary'] as List<String>;
    if (dietaryPreferences.isNotEmpty) {
      filteredShops =
          filteredShops
              .where(
                (shop) =>
                    shop.tags.any((tag) => dietaryPreferences.contains(tag)),
              )
              .toList();
    }

    // Apply verified only filter
    if (_filterSettings['verifiedOnly']) {
      filteredShops = filteredShops.where((shop) => shop.isVerified).toList();
    }

    // Sort results
    switch (_filterSettings['sortBy']) {
      case 'rating':
        filteredShops.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'deliveryTime':
        filteredShops.sort(
          (a, b) => a.deliveryTimeMinutes.compareTo(b.deliveryTimeMinutes),
        );
        break;
      case 'priceAsc':
        filteredShops.sort((a, b) {
          final avgPriceA =
              a.menu.isEmpty
                  ? 0
                  : a.menu.map((item) => item.price).reduce((x, y) => x + y) /
                      a.menu.length;
          final avgPriceB =
              b.menu.isEmpty
                  ? 0
                  : b.menu.map((item) => item.price).reduce((x, y) => x + y) /
                      b.menu.length;
          return avgPriceA.compareTo(avgPriceB);
        });
        break;
      case 'priceDesc':
        filteredShops.sort((a, b) {
          final avgPriceA =
              a.menu.isEmpty
                  ? 0
                  : a.menu.map((item) => item.price).reduce((x, y) => x + y) /
                      a.menu.length;
          final avgPriceB =
              b.menu.isEmpty
                  ? 0
                  : b.menu.map((item) => item.price).reduce((x, y) => x + y) /
                      b.menu.length;
          return avgPriceB.compareTo(avgPriceA);
        });
        break;
    }

    return filteredShops;
  }

  // Update filter settings
  void updateFilterSettings(Map<String, dynamic> newSettings) {
    _filterSettings = newSettings;
    notifyListeners();
  }

  // Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Toggle favorite status and persist
  Future<bool> toggleFavorite(Shop shop) async {
    final currentlyFavorite = isFavorite(shop);

    if (currentlyFavorite) {
      _favoriteShops.removeWhere((s) => s.id == shop.id);
    } else {
      _favoriteShops.add(shop);
    }

    final shopIndex = _shops.indexWhere((s) => s.id == shop.id);
    if (shopIndex >= 0) {
      _shops[shopIndex] = _shops[shopIndex].copyWith(
        isFavorite: !currentlyFavorite,
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = _favoriteShops.map((s) => s.id).toList();
      await prefs.setStringList(_favoriteShopIdsKey, ids);
    } catch (_) {
      // Ignore persistence errors
    }

    notifyListeners();
    return !currentlyFavorite;
  }

  // Check if a shop is a favorite
  bool isFavorite(Shop shop) {
    return _favoriteShops.any((s) => s.id == shop.id);
  }

  // Add item to cart
  void addToCart(String shopName, CartItem item) {
    if (!_cartItems.containsKey(shopName)) {
      _cartItems[shopName] = [];
    }

    final index = _cartItems[shopName]!.indexWhere(
      (i) => i.item.name == item.item.name,
    );

    if (index >= 0) {
      _cartItems[shopName]![index].quantity += item.quantity;
    } else {
      _cartItems[shopName]!.add(item);
    }

    notifyListeners();
  }

  // Update cart item quantity
  void updateCartItemQuantity(String shopName, int index, int delta) {
    if (_cartItems.containsKey(shopName) &&
        index < _cartItems[shopName]!.length) {
      _cartItems[shopName]![index].quantity += delta;

      if (_cartItems[shopName]![index].quantity <= 0) {
        _cartItems[shopName]!.removeAt(index);
      }

      if (_cartItems[shopName]!.isEmpty) {
        _cartItems.remove(shopName);
      }

      notifyListeners();
    }
  }

  // Clear cart for a shop
  void clearCart(String shopName) {
    _cartItems.remove(shopName);
    notifyListeners();
  }

  // Place order
  Order placeOrder({
    required String shopName,
    required String deliveryAddress,
    required PaymentMethod paymentMethod,
  }) {
    if (!_cartItems.containsKey(shopName) || _cartItems[shopName]!.isEmpty) {
      throw Exception('Cart is empty');
    }

    final items = List<CartItem>.from(_cartItems[shopName]!);
    final totalAmount = items.fold(0, (sum, item) => sum + item.totalPrice);

    final order = Order(
      id: 'ORD${DateTime.now().millisecondsSinceEpoch}',
      items: items,
      totalAmount: totalAmount,
      deliveryAddress: deliveryAddress,
      orderTime: DateTime.now(),
      status: OrderStatus.placed,
      paymentMethod: paymentMethod,
    );

    _orders.add(order);
    _cartItems.remove(shopName);

    notifyListeners();
    return order;
  }

  // Add review
  void addReview(String shopName, Review review) {
    if (!_shopReviews.containsKey(shopName)) {
      _shopReviews[shopName] = [];
    }

    _shopReviews[shopName]!.add(review);

    // Update shop rating
    final shopIndex = _shops.indexWhere((s) => s.name == shopName);
    if (shopIndex >= 0) {
      final reviews = _shopReviews[shopName]!;
      final avgRating =
          reviews.isEmpty
              ? 0.0
              : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                  reviews.length;

      _shops[shopIndex] = _shops[shopIndex].copyWith(
        rating: double.parse(avgRating.toStringAsFixed(1)),
      );
    }

    notifyListeners();
  }

  void cacheMenu(String shopId, List<MenuItem> menu) {
    _shopMenus[shopId] = menu;
  }

  // Get shop by name
  Shop? getShopByName(String name) {
    final index = _shops.indexWhere((s) => s.name == name);
    return index >= 0 ? _shops[index] : null;
  }
}
