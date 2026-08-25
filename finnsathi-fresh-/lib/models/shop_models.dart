import 'package:flutter/material.dart';

class Shop {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final double rating;
  final List<String> tags;
  final List<MenuItem> menu;
  final String location;
  final bool isVerified;
  final int deliveryTimeMinutes;
  final double deliveryFee;
  final bool isFavorite;

  Shop({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.description = '',
    this.rating = 0.0,
    this.tags = const [],
    required this.menu,
    this.location = '',
    this.isVerified = false,
    this.deliveryTimeMinutes = 30,
    this.deliveryFee = 0.0,
    this.isFavorite = false,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      tags: List<String>.from(json['tags'] ?? []),
      menu:
          (json['menu'] as List?)
              ?.map((item) => MenuItem.fromJson(item))
              .toList() ??
          [],
      location: json['location'] ?? '',
      isVerified: json['isVerified'] ?? false,
      deliveryTimeMinutes: json['deliveryTimeMinutes'] ?? 30,
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Shop copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? description,
    double? rating,
    List<String>? tags,
    List<MenuItem>? menu,
    String? location,
    bool? isVerified,
    int? deliveryTimeMinutes,
    double? deliveryFee,
    bool? isFavorite,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      menu: menu ?? this.menu,
      location: location ?? this.location,
      isVerified: isVerified ?? this.isVerified,
      deliveryTimeMinutes: deliveryTimeMinutes ?? this.deliveryTimeMinutes,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class MenuItem {
  final String id;
  final String name;
  final int price;
  final String description;
  final String imageUrl;
  final List<String> ingredients;
  final bool isVegetarian;
  final bool isRecommended;
  final bool isPopular;
  final double rating;
  final int calories;
  final int prepTimeMinutes;
  final bool isAvailable;
  final List<Map<String, dynamic>>? customizations;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    this.description = '',
    this.imageUrl = '',
    this.ingredients = const [],
    this.isVegetarian = false,
    this.isRecommended = false,
    this.isPopular = false,
    this.rating = 0.0,
    this.calories = 0,
    this.prepTimeMinutes = 15,
    this.isAvailable = true,
    this.customizations,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      isVegetarian: json['isVegetarian'] ?? false,
      isRecommended: json['isRecommended'] ?? false,
      isPopular: json['isPopular'] ?? false,
      rating: (json['rating'] ?? 0).toDouble(),
      calories: json['calories'] ?? 0,
      prepTimeMinutes: json['prepTimeMinutes'] ?? 15,
      isAvailable: json['isAvailable'] ?? true,
      customizations:
          (json['customizations'] as List?)
              ?.map((e) => (e as Map).cast<String, dynamic>())
              .toList(),
    );
  }
}

class CartItem {
  final MenuItem item;
  int quantity;
  final Map<String, dynamic>? selectedCustomizations;
  final String? specialInstructions;

  CartItem({
    required this.item,
    this.quantity = 1,
    this.selectedCustomizations,
    this.specialInstructions,
  });

  int get totalPrice {
    int basePrice = item.price * quantity;
    int customizationPrice = 0;

    if (selectedCustomizations != null) {
      selectedCustomizations!.forEach((key, value) {
        if (value is Map && value.containsKey('price')) {
          customizationPrice += (value['price'] as int? ?? 0);
        }
      });
    }

    return basePrice + (customizationPrice * quantity);
  }
}

class Order {
  final String id;
  final List<CartItem> items;
  final int totalAmount;
  final String deliveryAddress;
  final DateTime orderTime;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final String? trackingId;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.orderTime,
    this.status = OrderStatus.placed,
    required this.paymentMethod,
    this.trackingId,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItems =
        json['items'] as List<dynamic>? ?? <dynamic>[];

    final items =
        rawItems.map((dynamic itemJson) {
          final Map<String, dynamic> item =
              itemJson is Map<String, dynamic> ? itemJson : <String, dynamic>{};

          final menuItem = MenuItem(
            id: (item['menuItemId'] ?? '').toString(),
            name: item['name']?.toString() ?? '',
            price: (item['price'] is num) ? (item['price'] as num).toInt() : 0,
          );

          return CartItem(
            item: menuItem,
            quantity:
                (item['quantity'] is num)
                    ? (item['quantity'] as num).toInt()
                    : 1,
            selectedCustomizations:
                item['customizations'] is Map
                    ? Map<String, dynamic>.from(item['customizations'] as Map)
                    : null,
            specialInstructions: item['specialInstructions']?.toString(),
          );
        }).toList();

    final String statusStr = (json['status'] ?? 'placed').toString();
    OrderStatus status;
    switch (statusStr) {
      case 'confirmed':
        status = OrderStatus.confirmed;
        break;
      case 'preparing':
        status = OrderStatus.preparing;
        break;
      case 'outForDelivery':
        status = OrderStatus.outForDelivery;
        break;
      case 'delivered':
        status = OrderStatus.delivered;
        break;
      case 'cancelled':
        status = OrderStatus.cancelled;
        break;
      case 'placed':
      default:
        status = OrderStatus.placed;
        break;
    }

    final String paymentStr = (json['paymentMethod'] ?? 'upi').toString();
    PaymentMethod paymentMethod;
    switch (paymentStr) {
      case 'card':
        paymentMethod = PaymentMethod.card;
        break;
      case 'wallet':
        paymentMethod = PaymentMethod.wallet;
        break;
      case 'cashOnDelivery':
        paymentMethod = PaymentMethod.cashOnDelivery;
        break;
      case 'upi':
      default:
        paymentMethod = PaymentMethod.upi;
        break;
    }

    final dynamic createdAtRaw =
        json['createdAt'] ??
        json['orderTime'] ??
        DateTime.now().toIso8601String();
    DateTime orderTime;
    if (createdAtRaw is DateTime) {
      orderTime = createdAtRaw.toLocal();
    } else {
      try {
        orderTime = DateTime.parse(createdAtRaw.toString()).toLocal();
      } catch (_) {
        orderTime = DateTime.now();
      }
    }

    final dynamic totalRaw =
        json['finalAmount'] ?? json['totalAmount'] ?? json['total'] ?? 0;
    final int totalAmount =
        totalRaw is num
            ? totalRaw.toInt()
            : int.tryParse(totalRaw.toString()) ?? 0;

    final String id = (json['orderId'] ?? json['_id'] ?? '').toString();

    return Order(
      id: id,
      items: items,
      totalAmount: totalAmount,
      deliveryAddress: json['deliveryAddress']?.toString() ?? '',
      orderTime: orderTime,
      status: status,
      paymentMethod: paymentMethod,
      trackingId: json['trackingId']?.toString(),
    );
  }
}

enum OrderStatus {
  placed,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
}

enum PaymentMethod { card, upi, wallet, cashOnDelivery }

class Review {
  final String userId;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final DateTime date;
  final List<String>? images;

  Review({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.date,
    this.images,
  });
}
