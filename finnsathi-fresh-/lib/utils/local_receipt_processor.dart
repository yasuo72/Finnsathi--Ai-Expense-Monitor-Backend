import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/receipt_models.dart';

/// A utility class that provides local receipt processing capabilities
/// when the remote API is unavailable.
class LocalReceiptProcessor {
  /// Performs basic text extraction from an image file
  /// This is a simplified version and doesn't have OCR capabilities
  /// It returns a placeholder message
  static Future<String> extractText(File imageFile) async {
    // In a real implementation, this would use a local OCR library
    // For now, we'll return a placeholder
    return "*** Local Processing Mode ***\n\nReceipt text extraction would happen here.\nThe remote API is currently unavailable.\n\nThis is a fallback mode.";
  }

  /// Performs basic data extraction from receipt text
  /// This is a simplified version that extracts some common patterns
  static Future<ReceiptData> extractData(String text) async {
    // In a real implementation, this would use regex or other pattern matching
    // For now, we'll return a placeholder receipt
    return compute(_processText, text);
  }

  /// Process text in a separate isolate to avoid blocking the UI
  static ReceiptData _processText(String text) {
    // Simple regex patterns to extract common receipt information
    final merchantRegex = RegExp(
      r'(?:store|merchant|shop|restaurant):\s*([^\n]+)',
      caseSensitive: false,
    );
    final dateRegex = RegExp(r'(?:date|dt):\s*([^\n]+)', caseSensitive: false);
    final totalRegex = RegExp(
      r'(?:total|amount|sum):\s*(?:Rs\.?|₹)?(\d+(?:\.\d{1,2})?)',
      caseSensitive: false,
    );
    final itemRegex = RegExp(
      r'(\d+)\s*x\s*([^\n]+)\s*(?:Rs\.?|₹)?(\d+(?:\.\d{1,2})?)',
      caseSensitive: false,
    );

    // Extract data using regex
    String? merchantName = _extractWithRegex(text, merchantRegex);
    String? date = _extractWithRegex(text, dateRegex);
    String? totalStr = _extractWithRegex(text, totalRegex);
    double? totalAmount = totalStr != null ? double.tryParse(totalStr) : null;

    // Extract items
    List<ReceiptItem> items = [];
    final itemMatches = itemRegex.allMatches(text);
    for (var match in itemMatches) {
      if (match.groupCount >= 3) {
        final quantity = double.tryParse(match.group(1) ?? '1') ?? 1;
        final name = match.group(2)?.trim();
        final price = double.tryParse(match.group(3) ?? '0') ?? 0;

        if (name != null) {
          items.add(
            ReceiptItem(
              name: name,
              quantity: quantity,
              price: price,
              totalPrice: quantity * price,
            ),
          );
        }
      }
    }

    return ReceiptData(
      merchantName: merchantName ?? 'Local Store',
      date: date ?? DateTime.now().toString().substring(0, 10),
      totalAmount: totalAmount ?? 0.0,
      currency: '₹',
      items: items,
      rawText: text,
    );
  }

  /// Helper method to extract text using regex
  static String? _extractWithRegex(String text, RegExp regex) {
    final match = regex.firstMatch(text);
    return match?.group(1)?.trim();
  }
}
