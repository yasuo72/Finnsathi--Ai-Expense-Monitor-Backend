import 'package:flutter/material.dart';
import '../../models/shop_models.dart';
import '../../services/shop_api_service.dart';
import '../../services/shop_service.dart';
import 'cart_screen.dart';
import 'shop_reviews_screen.dart';

class ShopMenuScreen extends StatefulWidget {
  final Shop shop;
  const ShopMenuScreen({super.key, required this.shop});

  @override
  State<ShopMenuScreen> createState() => _ShopMenuScreenState();
}

class _ShopMenuScreenState extends State<ShopMenuScreen> {
  final List<CartItem> cart = [];

  // Dynamic data loaded from backend
  bool _isLoading = true;
  String _errorMessage = '';
  List<MenuItem> _menuItems = [];
  late String shopAvatar;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    shopAvatar =
        widget.shop.imageUrl.isNotEmpty
            ? widget.shop.imageUrl
            : 'https://randomuser.me/api/portraits/men/32.jpg';
    _isFavorite =
        ShopService().isFavorite(widget.shop) || widget.shop.isFavorite;
    _loadShopDetails();
  }

  Future<void> _loadShopDetails() async {
    final shopService = ShopService();
    final cachedMenu = shopService.getMenuForShop(widget.shop.id);

    if (cachedMenu != null && cachedMenu.isNotEmpty) {
      setState(() {
        _menuItems = cachedMenu;
        _isLoading = false;
        _errorMessage = '';
      });

      _refreshMenuInBackground();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final result = await ShopApiService.getShopDetails(widget.shop.id);
      final Shop loadedShop = result['shop'] as Shop;
      final List<MenuItem> loadedMenu = (result['menu'] as List<MenuItem>);

      shopService.cacheMenu(widget.shop.id, loadedMenu);

      setState(() {
        shopAvatar =
            loadedShop.imageUrl.isNotEmpty ? loadedShop.imageUrl : shopAvatar;
        _menuItems = loadedMenu;
        _isFavorite =
            ShopService().isFavorite(loadedShop) || loadedShop.isFavorite;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load menu: $e';
        _isLoading = false;
        // Fallback to any menu that came with the shop object
        _menuItems = widget.shop.menu;
      });
    }
  }

  Future<void> _refreshMenuInBackground() async {
    try {
      final result = await ShopApiService.getShopDetails(widget.shop.id);
      final Shop loadedShop = result['shop'] as Shop;
      final List<MenuItem> loadedMenu = (result['menu'] as List<MenuItem>);

      ShopService().cacheMenu(widget.shop.id, loadedMenu);

      if (!mounted) return;

      setState(() {
        shopAvatar =
            loadedShop.imageUrl.isNotEmpty ? loadedShop.imageUrl : shopAvatar;
        _menuItems = loadedMenu;
        _isFavorite =
            ShopService().isFavorite(loadedShop) || loadedShop.isFavorite;
      });
    } catch (e) {}
  }

  void addToCart(MenuItem item) {
    final index = cart.indexWhere((c) => c.item.name == item.name);
    setState(() {
      if (index >= 0) {
        cart[index].quantity++;
      } else {
        cart.add(CartItem(item: item));
      }
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Added to cart: ${item.name}')));
  }

  void _showItemDetails(MenuItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: keyboardInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '₹${item.price}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      item.imageUrl.isNotEmpty
                          ? Image.network(
                            item.imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          )
                          : Container(
                            width: double.infinity,
                            height: 200,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.fastfood, size: 40),
                          ),
                ),
                const SizedBox(height: 12),
                if (item.description.isNotEmpty)
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 4),
                    Text('${item.prepTimeMinutes} min'),
                    if (item.calories > 0) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.local_fire_department, size: 16),
                      const SizedBox(width: 4),
                      Text('${item.calories} kcal'),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      addToCart(item);
                      Navigator.pop(context);
                    },
                    child: const Text('Add to cart'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).iconTheme.color ?? Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(shopAvatar),
              radius: 16,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.15),
            ),
            const SizedBox(width: 8),
            Text(
              widget.shop.name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color:
                  _isFavorite
                      ? Colors.red
                      : Theme.of(context).iconTheme.color ?? Colors.white,
            ),
            onPressed: () async {
              final newValue = await ShopService().toggleFavorite(widget.shop);
              setState(() {
                _isFavorite = newValue;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    newValue
                        ? 'Added to favourites'
                        : 'Removed from favourites',
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).iconTheme.color ?? Colors.white,
            ),
            onSelected: (value) {
              switch (value) {
                case 'reviews':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ShopReviewsScreen(
                            shop: widget.shop,
                            reviews: const [],
                          ),
                    ),
                  );
                  break;
              }
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem<String>(
                    value: 'reviews',
                    child: Text('View ratings & reviews'),
                  ),
                ],
          ),
        ],
        centerTitle: true,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;

            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_errorMessage.isNotEmpty && _menuItems.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_errorMessage, textAlign: TextAlign.center),
                ),
              );
            }

            if (_menuItems.isEmpty) {
              return const Center(
                child: Text('No items available in this shop yet'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                return Card(
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: InkWell(
                      onTap: () => _showItemDetails(item),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            item.imageUrl.isNotEmpty
                                ? Image.network(
                                  item.imageUrl,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 64,
                                      height: 64,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.fastfood),
                                    );
                                  },
                                )
                                : Container(
                                  width: 64,
                                  height: 64,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.fastfood),
                                ),
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              item.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.prepTimeMinutes} min',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              if (item.calories > 0) ...[
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.local_fire_department,
                                  size: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${item.calories} kcal',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    trailing: SizedBox(
                      height: 64,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${item.price}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onSecondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: isWide ? 20 : 10,
                                vertical: 4,
                              ),
                              minimumSize: const Size(0, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              elevation: 0,
                            ),
                            onPressed: () => addToCart(item),
                            child: const Text(
                              'Add',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar:
          cart.isNotEmpty
              ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => CartScreen(
                                cart: cart,
                                shopId: widget.shop.id,
                                shop: widget.shop,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'View Cart (${cart.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
              : null,
    );
  }
}
