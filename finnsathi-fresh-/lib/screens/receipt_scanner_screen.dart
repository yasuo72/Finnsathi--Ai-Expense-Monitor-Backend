import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/receipt_models.dart';
import 'package:finsaathi_multi/screens/add_transaction_screen.dart';
import '../models/finance_models.dart';
import '../services/receipt_scanner_service.dart';
import '../utils/local_receipt_processor.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;
  String? _scannedText;
  ReceiptData? _receiptData;
  final ReceiptScannerService _scannerService = ReceiptScannerService();
  bool _apiConnected = false;

  void _addExpense() {
    if (_receiptData == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => AddTransactionScreen(
              type: TransactionType.expense,
              initialTitle: _receiptData!.merchantName ?? 'Receipt',
              initialAmount: _receiptData!.totalAmount,
            ),
      ),
    );
  }

  void _addIncome() {
    if (_receiptData == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => AddTransactionScreen(
              type: TransactionType.income,
              initialTitle: _receiptData!.merchantName ?? 'Receipt',
              initialAmount: _receiptData!.totalAmount,
            ),
      ),
    );
  }

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkApiConnection();
  }

  Future<void> _checkApiConnection() async {
    setState(() => _loading = true);
    try {
      // Use timeout to prevent app from hanging if the service is down
      final isConnected = await _scannerService.healthCheck().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );

      if (mounted) {
        setState(() {
          _apiConnected = isConnected;
          if (!isConnected) {
            _errorMessage =
                'Could not connect to receipt scanner API. The server might be down or your internet connection might be unstable.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _apiConnected = false;
          _errorMessage = 'Error connecting to API: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _loading = true);
    final pickedFile = await _picker.pickImage(source: source);
    if (!mounted) return;

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _loading = false;
        _scannedText = null;
        _receiptData = null;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _scanReceipt() async {
    if (_image == null) return;

    setState(() {
      _loading = true;
      _scannedText = null;
      _receiptData = null;
      _errorMessage = null;
    });

    try {
      String text;
      ReceiptData receiptData;

      if (_apiConnected) {
        // Online mode - use the backend + Tabscanner integration
        try {
          receiptData = await _scannerService.scanReceipt(_image!);
          text = receiptData.rawText ?? '';
        } catch (e) {
          // If API fails, fallback to local processing
          if (mounted) {
            setState(() {
              _apiConnected = false;
              _errorMessage =
                  'API connection failed: $e\nFalling back to local processing mode.';
            });
          }

          // Use local processing as fallback
          text = await LocalReceiptProcessor.extractText(_image!);
          receiptData = await LocalReceiptProcessor.extractData(text);
        }
      } else {
        // Offline mode - use local processing
        text = await LocalReceiptProcessor.extractText(_image!);
        receiptData = await LocalReceiptProcessor.extractData(text);
      }

      if (mounted) {
        setState(() {
          _scannedText = text;
          _receiptData = receiptData;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error processing receipt: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveReceipt() async {
    if (_receiptData == null) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await _scannerService.saveReceipt(_receiptData!);
      // Check if the widget is still mounted before using context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt saved successfully')),
        );
      }
    } catch (e) {
      // Check if the widget is still mounted before updating state
      if (mounted) {
        setState(() {
          _errorMessage = 'Error saving receipt: $e';
        });
      }
    } finally {
      // Check if the widget is still mounted before updating state
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Scanner'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View Receipt History',
            onPressed: () {
              Navigator.pushNamed(context, '/receipt_history');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        // Wrap the entire content in a SingleChildScrollView to prevent overflow
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_image != null)
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(_image!, height: 220, fit: BoxFit.cover),
                  ),
                )
              else
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'No receipt selected',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        _loading ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        _loading ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              const SizedBox(height: 18),
              if (_image != null)
                ElevatedButton(
                  onPressed: _loading ? null : _scanReceipt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _apiConnected ? Colors.orange : Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _apiConnected
                        ? 'Scan Receipt'
                        : 'Scan Receipt (Offline Mode)',
                  ),
                ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _checkApiConnection,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Connection'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

              // Connection status indicator
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _apiConnected ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _apiConnected
                          ? 'API Connected'
                          : 'API Disconnected - Using Local Processing',
                      style: TextStyle(
                        color: _apiConnected ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              if (_scannedText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: SizedBox(
                    height: 150,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Scanned Text:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_scannedText!),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (_receiptData != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Extracted Data:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: SingleChildScrollView(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Merchant: ${_receiptData!.merchantName ?? 'Unknown'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Date: ${_receiptData!.date ?? 'Unknown'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Total: ${_receiptData!.totalAmount ?? 'Unknown'} ${_receiptData!.currency ?? ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_receiptData!.items.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Items:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ...(_receiptData!.items
                                      .map(
                                        (item) => Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8.0,
                                            top: 8.0,
                                          ),
                                          child: Text(
                                            '${item.name}: ${item.quantity ?? 1} x ${item.price ?? 0}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList()),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _loading ? null : _saveReceipt,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Save Receipt',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_receiptData != null) ...[
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _loading ? null : _addExpense,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Add Expense',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _loading ? null : _addIncome,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Add Income',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
