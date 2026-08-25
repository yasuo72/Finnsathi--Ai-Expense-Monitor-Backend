import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/shop_models.dart';
import '../config/api_config.dart';

class ShopApiService {
  // Use the main API base URL (already includes /api)
  static String get _baseUrl => ApiConfig.baseUrl;

  // Get all shops
  static Future<List<Shop>> getAllShops({
    String? search,
    List<String>? tags,
    double? minRating,
    double? maxPrice,
    String? sortBy,
  }) async {
    try {
      String url = '$_baseUrl/shops?isVerified=true';

      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
      }
      if (tags != null && tags.isNotEmpty) {
        url += '&tags=${tags.join(',')}';
      }
      if (minRating != null && minRating > 0) {
        url += '&minRating=$minRating';
      }
      if (maxPrice != null && maxPrice > 0) {
        url += '&maxPrice=$maxPrice';
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        url += '&sortBy=$sortBy';
      }

      final response = await http
          .get(Uri.parse(url))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((shop) => Shop.fromJson(shop)).toList();
      } else {
        throw Exception('Failed to load shops: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching shops: $e');
      rethrow;
    }
  }

  // Get shop details with menu
  static Future<Map<String, dynamic>> getShopDetails(String shopId) async {
    try {
      // Fetch shop details
      final shopResponse = await http
          .get(Uri.parse('$_baseUrl/shops/$shopId'))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (shopResponse.statusCode != 200) {
        throw Exception('Failed to load shop details');
      }

      // Fetch shop menu from public menu endpoint
      final menuResponse = await http
          .get(Uri.parse('$_baseUrl/menu/shop/$shopId'))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (menuResponse.statusCode != 200) {
        throw Exception('Failed to load shop menu');
      }

      final decodedShop = jsonDecode(shopResponse.body);
      Map<String, dynamic> shopJson;

      // Some backends might wrap the shop in a single-element list
      if (decodedShop is List && decodedShop.isNotEmpty) {
        shopJson = decodedShop.first as Map<String, dynamic>;
      } else if (decodedShop is Map<String, dynamic>) {
        shopJson = decodedShop;
      } else {
        throw Exception('Unexpected shop data format');
      }

      final decodedMenu = jsonDecode(menuResponse.body);
      final List<dynamic> menuData =
          decodedMenu is List ? decodedMenu : <dynamic>[];

      return {
        'shop': Shop.fromJson(shopJson),
        'menu':
            menuData
                .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
                .toList(),
      };
    } catch (e) {
      print('Error fetching shop details: $e');
      rethrow;
    }
  }

  // Get reviews for a shop (based on rated orders)
  static Future<List<Review>> getShopReviews(String shopId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/shops/$shopId/reviews'))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map<Review>((dynamic item) {
            final Map<String, dynamic> json =
                item is Map<String, dynamic> ? item : <String, dynamic>{};

            DateTime date;
            final rawDate = json['date']?.toString();
            if (rawDate != null && rawDate.isNotEmpty) {
              try {
                date = DateTime.parse(rawDate);
              } catch (_) {
                date = DateTime.now();
              }
            } else {
              date = DateTime.now();
            }

            final images =
                (json['images'] as List?)?.map((e) => e.toString()).toList();

            final ratingValue = json['rating'];

            return Review(
              userId: json['userId']?.toString() ?? '',
              userName: json['userName']?.toString() ?? 'Customer',
              userAvatar:
                  json['userAvatar']?.toString() ??
                  'https://randomuser.me/api/portraits/lego/1.jpg',
              rating: ratingValue is num ? ratingValue.toDouble() : 0.0,
              comment: json['comment']?.toString() ?? '',
              date: date,
              images: images,
            );
          }).toList();
        }

        return <Review>[];
      } else {
        throw Exception('Failed to load reviews');
      }
    } catch (e) {
      print('Error fetching shop reviews: $e');
      rethrow;
    }
  }

  // Create order
  static Future<Map<String, dynamic>> createOrder({
    required String shopId,
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required String paymentMethod,
    required String authToken,
    String? notes,
    Map<String, dynamic>? customer,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/orders'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({
              'shopId': shopId,
              'items': items,
              'deliveryAddress': deliveryAddress,
              'paymentMethod': paymentMethod,
              'notes': notes ?? 'Order from FinSathi app',
              if (customer != null) 'customer': customer,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create order: ${response.body}');
      }
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  // Get user orders
  static Future<List<Map<String, dynamic>>> getUserOrders(
    String authToken,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/orders/user'),
            headers: {'Authorization': 'Bearer $authToken'},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      rethrow;
    }
  }

  // Rate order
  static Future<void> rateOrder({
    required String orderId,
    required int rating,
    required String review,
    required String authToken,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/orders/$orderId/rate'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({'rating': rating, 'review': review}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode != 200) {
        throw Exception('Failed to rate order');
      }
    } catch (e) {
      print('Error rating order: $e');
      rethrow;
    }
  }
}
