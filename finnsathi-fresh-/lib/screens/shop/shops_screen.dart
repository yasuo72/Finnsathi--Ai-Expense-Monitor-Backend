import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/shop_models.dart';
import '../../services/shop_api_service.dart';
import '../../services/shop_service.dart';
import '../../services/api_service_manager.dart';
import '../../widgets/expandable_fab.dart';
import 'shop_menu_screen.dart';
import 'favorite_shops_screen.dart';
import 'shop_filters_screen.dart';
import 'shop_notifications_screen.dart';
import 'order_history_screen.dart';

// Hardcoded data for backend prep
final String defaultShopImageUrl =
    'https://cdn-icons-png.flaticon.com/512/562/562678.png';
final String defaultProfileImageUrl =
    'https://randomuser.me/api/portraits/men/32.jpg';

final List<Shop> shops = [
  Shop(
    id: '1',
    name: 'Size Zero',
    imageUrl: 'https://cdn-icons-png.flaticon.com/512/562/562678.png',
    description: 'Healthy food for fitness enthusiasts',
    rating: 4.7,
    tags: ['Healthy', 'Fitness', 'Low Calorie'],
    location: 'Koramangala, Bangalore',
    isVerified: true,
    deliveryTimeMinutes: 25,
    deliveryFee: 20.0,
    isFavorite: false,
    menu: [
      MenuItem(
        id: '1-1',
        name: 'Veg Cheese Sandwich',
        price: 80,
        description: 'Fresh vegetables with cheese in multigrain bread',
        imageUrl:
            'https://images.unsplash.com/photo-1528735602780-2552fd46c7af',
        isVegetarian: true,
        isRecommended: true,
        calories: 320,
        ingredients: [
          'Multigrain bread',
          'Cheese',
          'Tomato',
          'Cucumber',
          'Lettuce',
        ],
        rating: 4.5,
      ),
      MenuItem(
        id: '1-2',
        name: 'Grilled Paneer Sandwich',
        price: 90,
        description: 'Grilled cottage cheese with spices and vegetables',
        imageUrl:
            'https://images.unsplash.com/photo-1539252554935-80c7dd4d82f8',
        isVegetarian: true,
        isPopular: true,
        calories: 380,
        ingredients: [
          'Multigrain bread',
          'Paneer',
          'Bell peppers',
          'Onion',
          'Spices',
        ],
        rating: 4.7,
      ),
      MenuItem(
        id: '1-3',
        name: 'Corn & Cheese Sandwich',
        price: 85,
        description: 'Sweet corn kernels with melted cheese',
        imageUrl: 'https://images.unsplash.com/photo-1559054663-e8d23213f55c',
        isVegetarian: true,
        calories: 350,
        ingredients: ['Multigrain bread', 'Corn', 'Cheese', 'Butter', 'Herbs'],
        rating: 4.3,
      ),
      MenuItem(
        id: '1-4',
        name: 'Spicy Masala Burger',
        price: 95,
        description: 'Spicy vegetable patty with Indian spices',
        imageUrl:
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd',
        isVegetarian: true,
        calories: 420,
        ingredients: [
          'Whole wheat bun',
          'Vegetable patty',
          'Onion',
          'Tomato',
          'Lettuce',
        ],
        rating: 4.6,
      ),
      MenuItem(
        id: '1-5',
        name: 'Power Exercise Burger',
        price: 110,
        description: 'Protein-rich burger for post-workout',
        imageUrl:
            'https://images.unsplash.com/photo-1565299507177-b0ac66763828',
        isVegetarian: true,
        isRecommended: true,
        calories: 450,
        ingredients: [
          'Protein bun',
          'Soy patty',
          'Egg white',
          'Avocado',
          'Spinach',
        ],
        rating: 4.8,
      ),
      MenuItem(
        id: '1-6',
        name: 'Choco Shake',
        price: 70,
        description: 'Protein chocolate shake with low sugar',
        imageUrl:
            'https://images.unsplash.com/photo-1572490122747-3968b75cc699',
        isVegetarian: true,
        calories: 220,
        ingredients: ['Milk', 'Protein powder', 'Cocoa', 'Ice'],
        rating: 4.4,
      ),
      MenuItem(
        id: '1-7',
        name: 'Strawberry Shake',
        price: 75,
        description: 'Fresh strawberries blended with yogurt',
        imageUrl:
            'https://images.unsplash.com/photo-1586917049334-dc89b7e45118',
        isVegetarian: true,
        calories: 200,
        ingredients: ['Strawberries', 'Yogurt', 'Honey', 'Ice'],
        rating: 4.5,
      ),
    ],
  ),
  Shop(
    id: '2',
    name: 'Green Leaf',
    imageUrl: 'https://cdn-icons-png.flaticon.com/512/2515/2515183.png',
    description: 'Organic and fresh salads and bowls',
    rating: 4.5,
    tags: ['Organic', 'Vegan', 'Gluten-free'],
    location: 'Indiranagar, Bangalore',
    isVerified: true,
    deliveryTimeMinutes: 30,
    deliveryFee: 25.0,
    isFavorite: true,
    menu: [
      MenuItem(
        id: '2-1',
        name: 'Fresh Salad',
        price: 60,
        description: 'Mix of seasonal vegetables with olive oil dressing',
        imageUrl:
            'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
        isVegetarian: true,
        isRecommended: true,
        calories: 150,
        ingredients: [
          'Lettuce',
          'Cucumber',
          'Tomato',
          'Bell peppers',
          'Olive oil',
        ],
        rating: 4.3,
      ),
      MenuItem(
        id: '2-2',
        name: 'Fruit Bowl',
        price: 70,
        description: 'Assorted fresh fruits with honey drizzle',
        imageUrl:
            'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea',
        isVegetarian: true,
        isPopular: true,
        calories: 180,
        ingredients: ['Apple', 'Banana', 'Orange', 'Grapes', 'Honey'],
        rating: 4.6,
      ),
    ],
  ),
  Shop(
    id: '3',
    name: 'Spice Junction',
    imageUrl: 'https://cdn-icons-png.flaticon.com/512/2515/2515203.png',
    description: 'Authentic Indian cuisine with a modern twist',
    rating: 4.8,
    tags: ['Indian', 'Spicy', 'Traditional'],
    location: 'HSR Layout, Bangalore',
    isVerified: true,
    deliveryTimeMinutes: 35,
    deliveryFee: 30.0,
    isFavorite: false,
    menu: [
      MenuItem(
        id: '3-1',
        name: 'Butter Chicken',
        price: 180,
        description: 'Tender chicken in rich tomato and butter gravy',
        imageUrl:
            'https://images.unsplash.com/photo-1588166524941-3bf61a9c41db',
        isVegetarian: false,
        isPopular: true,
        calories: 450,
        ingredients: ['Chicken', 'Tomato', 'Butter', 'Cream', 'Spices'],
        rating: 4.9,
      ),
      MenuItem(
        id: '3-2',
        name: 'Paneer Tikka Masala',
        price: 160,
        description: 'Grilled cottage cheese in spicy tomato gravy',
        imageUrl:
            'https://images.unsplash.com/photo-1565557623262-b51c2513a641',
        isVegetarian: true,
        isRecommended: true,
        calories: 380,
        ingredients: [
          'Paneer',
          'Bell peppers',
          'Onion',
          'Tomato gravy',
          'Spices',
        ],
        rating: 4.7,
      ),
    ],
  ),
  Shop(
    id: '4',
    name: 'Caffeine Fix',
    imageUrl: 'https://cdn-icons-png.flaticon.com/512/2935/2935307.png',
    description: 'Premium coffee and quick bites',
    rating: 4.6,
    tags: ['Coffee', 'Bakery', 'Breakfast'],
    location: 'MG Road, Bangalore',
    isVerified: true,
    deliveryTimeMinutes: 20,
    deliveryFee: 15.0,
    isFavorite: false,
    menu: [
      MenuItem(
        id: '4-1',
        name: 'Cappuccino',
        price: 120,
        description: 'Espresso with steamed milk and foam',
        imageUrl:
            'https://images.unsplash.com/photo-1534778101976-62847782c213',
        isVegetarian: true,
        isPopular: true,
        calories: 120,
        ingredients: ['Espresso', 'Milk', 'Foam'],
        rating: 4.8,
      ),
      MenuItem(
        id: '4-2',
        name: 'Chocolate Croissant',
        price: 90,
        description: 'Buttery croissant with chocolate filling',
        imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a',
        isVegetarian: true,
        isRecommended: true,
        calories: 320,
        ingredients: ['Flour', 'Butter', 'Chocolate', 'Sugar'],
        rating: 4.5,
      ),
    ],
  ),
];

class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Shop> _filteredShops = [];
  List<Shop> _allShops = [];
  int _selectedCategoryIndex = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  final List<String> _categories = [
    'All',
    'Healthy',
    'Indian',
    'Coffee',
    'Vegan',
  ];

  @override
  void initState() {
    super.initState();
    _loadShops();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuint),
    );

    _animationController.forward();
  }

  Future<void> _loadShops() async {
    try {
      final shopService = ShopService();

      // If we already have shops cached in the shared service, use them immediately
      if (shopService.shops.isNotEmpty) {
        setState(() {
          _allShops = shopService.shops;
          _filteredShops = shopService.shops;
          _isLoading = false;
          _errorMessage = '';
        });

        // Refresh in background for newer data without blocking UI
        _refreshShopsInBackground();
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final shopsData = await ShopApiService.getAllShops(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _allShops = shopsData;
        _filteredShops = shopsData;
        _isLoading = false;
      });

      // Initialize shared shop state so favorites and filters are consistent
      await shopService.initialize(shopsData);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load shops: $e';
        _isLoading = false;
        // Fallback to sample data
        _allShops = shops;
        _filteredShops = shops;
      });
      print('Error loading shops: $e');

      // Ensure service still has something to work with
      await ShopService().initialize(shops);
    }
  }

  // Refresh shops from backend without blocking the current view
  Future<void> _refreshShopsInBackground() async {
    try {
      final shopsData = await ShopApiService.getAllShops(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      // Update shared service cache
      await ShopService().initialize(shopsData);

      if (!mounted) return;

      // Update local view state if we're still on this screen
      setState(() {
        _allShops = shopsData;
        _filteredShops = shopsData;
      });
    } catch (e) {
      // Keep existing data on error to avoid jarring resets
      debugPrint('Error refreshing shops in background: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showSortOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSortOption(context, 'Rating: High to Low', Icons.star, () {
                setState(() {
                  _filteredShops.sort((a, b) => b.rating.compareTo(a.rating));
                });
                Navigator.pop(context);
              }),
              _buildSortOption(
                context,
                'Delivery Time: Low to High',
                Icons.access_time,
                () {
                  setState(() {
                    _filteredShops.sort(
                      (a, b) => a.deliveryTimeMinutes.compareTo(
                        b.deliveryTimeMinutes,
                      ),
                    );
                  });
                  Navigator.pop(context);
                },
              ),
              _buildSortOption(
                context,
                'Delivery Fee: Low to High',
                Icons.delivery_dining,
                () {
                  setState(() {
                    _filteredShops.sort(
                      (a, b) => a.deliveryFee.compareTo(b.deliveryFee),
                    );
                  });
                  Navigator.pop(context);
                },
              ),
              _buildSortOption(
                context,
                'Alphabetical: A to Z',
                Icons.sort_by_alpha,
                () {
                  setState(() {
                    _filteredShops.sort((a, b) => a.name.compareTo(b.name));
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _filterShops() {
    final query = _searchQuery.toLowerCase();
    setState(() {
      if (query.isEmpty && _selectedCategoryIndex == 0) {
        _filteredShops = _allShops;
      } else {
        _filteredShops =
            _allShops.where((shop) {
              bool matchesSearch =
                  query.isEmpty ||
                  shop.name.toLowerCase().contains(query) ||
                  shop.description.toLowerCase().contains(query);

              bool matchesCategory =
                  _selectedCategoryIndex == 0 ||
                  (_selectedCategoryIndex > 0 &&
                      shop.tags.any(
                        (tag) =>
                            tag.toLowerCase() ==
                            _categories[_selectedCategoryIndex].toLowerCase(),
                      ));

              return matchesSearch && matchesCategory;
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final apiManager = Provider.of<ApiServiceManager>(context);
    final unreadNotifications = apiManager.unreadNotificationsCount;

    return WillPopScope(
      onWillPop: () async {
        // Instead of letting the system handle the back button,
        // we'll manually handle it by switching to the home tab
        if (Navigator.canPop(context)) {
          // If there's a route to pop, let the system handle it
          return true;
        } else {
          // If we're at the root of the shop section, return to home tab
          // without closing the app
          Navigator.of(context, rootNavigator: true).pushReplacementNamed('/');
          return false; // Prevent the app from closing
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Food Shops',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.receipt_long,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                );
              },
            ),
            IconButton(
              icon: Stack(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: isDark ? Colors.white : Colors.black87,
                    size: 28,
                  ),
                  if (unreadNotifications > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          unreadNotifications > 99
                              ? '99+'
                              : unreadNotifications.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShopNotificationPage(),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: ExpandableFab(
          distance: 112,
          children: [
            ActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FavoriteShopsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.favorite),
              color: Colors.redAccent,
            ),
            ActionButton(
              onPressed: () {
                // Navigate to filters screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ShopFiltersScreen(
                          currentFilters: {},
                          onApplyFilters: (filters) {
                            // Apply filters logic
                          },
                        ),
                  ),
                );
              },
              icon: const Icon(Icons.filter_list),
              color: Theme.of(context).colorScheme.secondary,
            ),
            ActionButton(
              onPressed: () {
                // Show sort options
                _showSortOptions(context);
              },
              icon: const Icon(Icons.sort),
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color:
                            isDark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _filterShops();
                        });
                      },
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for food...',
                        hintStyle: TextStyle(
                          color:
                              isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.black54,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color:
                              isDark
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.black54,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Categories
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      height: 60,
                      margin: const EdgeInsets.only(top: 16),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedCategoryIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategoryIndex = index;
                                _filterShops();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? primaryColor
                                        : isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? primaryColor
                                          : isDark
                                          ? Colors.white.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow:
                                    isSelected
                                        ? [
                                          BoxShadow(
                                            color: primaryColor.withOpacity(
                                              0.5,
                                            ),
                                            blurRadius: 12,
                                            spreadRadius: -2,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                        : null,
                              ),
                              child: Center(
                                child: Text(
                                  _categories[index],
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : isDark
                                            ? Colors.white.withOpacity(0.8)
                                            : Colors.black87,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Featured Shops
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Featured Shops',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'See All',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Shop Cards
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final shop = _filteredShops[index];
                    // Calculate animation delay based on index
                    final delay = index * 0.1;
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          0.4 + delay,
                          1.0,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              0.4 + delay,
                              1.0,
                              curve: Curves.easeOutQuint,
                            ),
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ShopMenuScreen(shop: shop),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? const Color(0xFF2A2A2A)
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Shop Image
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      child: AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: Image.network(
                                          shop.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  size: 40,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    // Verified badge
                                    if (shop.isVerified)
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(
                                                Icons.verified,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Verified',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    // Favorite button
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: GestureDetector(
                                        onTap: () async {
                                          await ShopService().toggleFavorite(
                                            shop,
                                          );
                                          setState(() {});
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                isDark
                                                    ? Colors.grey.shade800
                                                    : Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    isDark
                                                        ? Colors.black
                                                            .withOpacity(0.2)
                                                        : Colors.black
                                                            .withOpacity(0.05),
                                                blurRadius: 10,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: Builder(
                                            builder: (context) {
                                              final isFav = ShopService()
                                                  .isFavorite(shop);
                                              return Icon(
                                                isFav
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color:
                                                    isFav
                                                        ? Colors.red
                                                        : Colors.grey,
                                                size: 18,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Shop Info
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              shop.name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    isDark
                                                        ? Colors.white
                                                        : Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                shop.rating.toString(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      isDark
                                                          ? Colors.white70
                                                          : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        shop.description,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              isDark
                                                  ? Colors.white60
                                                  : Colors.black54,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color:
                                                isDark
                                                    ? Colors.white38
                                                    : Colors.black45,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              shop.location,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    isDark
                                                        ? Colors.white38
                                                        : Colors.black45,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.timer_outlined,
                                            size: 14,
                                            color:
                                                isDark
                                                    ? Colors.white38
                                                    : Colors.black45,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${shop.deliveryTimeMinutes} min',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  isDark
                                                      ? Colors.white38
                                                      : Colors.black45,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Tags
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children:
                                            shop.tags.map((tag) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isDark
                                                          ? Colors.white
                                                              .withOpacity(0.1)
                                                          : primaryColor
                                                              .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  tag,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        isDark
                                                            ? Colors.white70
                                                            : primaryColor,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: _filteredShops.length),
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }
}
