class ReceiptData {
  int? id; // Made non-final to allow updating when saving locally
  final String? merchantName;
  final String? date;
  final double? totalAmount;
  final String? taxAmount;
  final String? currency;
  final List<ReceiptItem> items;
  final String? receiptNumber;
  final String? paymentMethod;
  final String? rawText;
  bool isLocalOnly; // Flag to indicate if the receipt is stored locally only

  ReceiptData({
    this.id,
    this.merchantName,
    this.date,
    this.totalAmount,
    this.taxAmount,
    this.currency,
    this.items = const [],
    this.receiptNumber,
    this.paymentMethod,
    this.rawText,
    this.isLocalOnly = false, // Default to false
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantName': merchantName,
      'date': date,
      'totalAmount': totalAmount,
      'taxAmount': taxAmount,
      'currency': currency,
      'items': items.map((item) => item.toJson()).toList(),
      'receiptNumber': receiptNumber,
      'paymentMethod': paymentMethod,
      'rawText': rawText,
      'isLocalOnly': isLocalOnly,
    };
  }

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      id: json['id'],
      merchantName: json['merchantName'],
      date: json['date'],
      totalAmount: json['totalAmount'] != null
          ? double.parse(json['totalAmount'].toString())
          : null,
      taxAmount: json['taxAmount']?.toString(),
      currency: json['currency'],
      items: json['items'] != null
          ? List<ReceiptItem>.from(
              json['items'].map((item) => ReceiptItem.fromJson(item)))
          : [],
      receiptNumber: json['receiptNumber'],
      paymentMethod: json['paymentMethod'],
      rawText: json['rawText'],
      isLocalOnly: json['isLocalOnly'] ?? false,
    );
  }
}

class ReceiptItem {
  final String? name;
  final double? quantity;
  final double? price;
  final double? totalPrice;

  ReceiptItem({
    this.name,
    this.quantity,
    this.price,
    this.totalPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'totalPrice': totalPrice,
    };
  }

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'],
      quantity: json['quantity'] != null
          ? double.parse(json['quantity'].toString())
          : null,
      price: json['price'] != null
          ? double.parse(json['price'].toString())
          : null,
      totalPrice: json['totalPrice'] != null
          ? double.parse(json['totalPrice'].toString())
          : null,
    );
  }
}
