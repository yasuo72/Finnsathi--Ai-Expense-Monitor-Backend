import 'package:flutter/material.dart';
import '../models/receipt_models.dart';
import '../services/receipt_scanner_service.dart';

class ReceiptHistoryScreen extends StatefulWidget {
  const ReceiptHistoryScreen({super.key});

  @override
  State<ReceiptHistoryScreen> createState() => _ReceiptHistoryScreenState();
}

class _ReceiptHistoryScreenState extends State<ReceiptHistoryScreen> {
  final ReceiptScannerService _scannerService = ReceiptScannerService();
  List<ReceiptData> _receipts = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    if (!mounted) return;
    
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final receipts = await _scannerService.getReceipts();
      
      if (!mounted) return;
      
      setState(() {
        _receipts = receipts;
        // If we have no receipts, show a helpful message
        if (_receipts.isEmpty) {
          _errorMessage = 'No receipts found. Scan a receipt to get started.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Error loading receipts: $e';
      });
    } finally {
      if (!mounted) return;
      
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _deleteReceipt(int? id, bool isLocalOnly) async {
    if (id == null) return;
    
    try {
      if (isLocalOnly) {
        // Delete from local storage
        await _scannerService.deleteLocalReceipt(id);
      } else {
        // Delete from server
        await _scannerService.deleteReceiptFromServer(id);
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt deleted successfully')),
      );
      _loadReceipts();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting receipt: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt History'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReceipts,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReceipts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _receipts.isEmpty
                  ? const Center(child: Text('No receipts found'))
                  : ListView.builder(
                      itemCount: _receipts.length,
                      itemBuilder: (context, index) {
                        final receipt = _receipts[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          // Add a subtle color indicator for local receipts
                          color: receipt.isLocalOnly 
                              ? Colors.deepPurple.withOpacity(0.05)
                              : null,
                          child: ListTile(
                            title: Text(receipt.merchantName != null && receipt.merchantName!.isNotEmpty 
                                ? receipt.merchantName! 
                                : 'Unknown Merchant'),
                            subtitle: Text(
                                'Date: ${receipt.date != null && receipt.date!.isNotEmpty ? receipt.date! : 'Unknown'}\nTotal: ${receipt.totalAmount != null ? '${receipt.currency ?? '₹'}${receipt.totalAmount!.toStringAsFixed(2)}' : 'Unknown'}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteReceipt(receipt.id, receipt.isLocalOnly),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReceiptDetailScreen(
                                    receipt: receipt,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}

class ReceiptDetailScreen extends StatefulWidget {
  final ReceiptData receipt;

  const ReceiptDetailScreen({
    super.key,
    required this.receipt,
  });

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  late ReceiptData _receipt;

  @override
  void initState() {
    super.initState();
    // Use the receipt passed from the previous screen
    _receipt = widget.receipt;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Details'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _receipt.merchantName != null && _receipt.merchantName!.isNotEmpty 
                                        ? _receipt.merchantName! 
                                        : 'Unknown Merchant',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Date: ${_receipt.date != null && _receipt.date!.isNotEmpty ? _receipt.date! : 'Unknown'}'),
                                  Text(
                                      'Total: ${_receipt.totalAmount != null ? '${_receipt.currency ?? '₹'}${_receipt.totalAmount!.toStringAsFixed(2)}' : 'Unknown'}'),
                                  if (_receipt.taxAmount != null)
                                    Text('Tax: ${_receipt.taxAmount}'),
                                  if (_receipt.paymentMethod != null)
                                    Text(
                                        'Payment Method: ${_receipt.paymentMethod}'),
                                  if (_receipt.receiptNumber != null)
                                    Text(
                                        'Receipt Number: ${_receipt.receiptNumber}'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Items',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_receipt.items.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Center(
                                child: Text(
                                  'No items found in this receipt',
                                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Row(
                                      children: const [
                                        Expanded(child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
                                        SizedBox(width: 16),
                                        Text('Qty', style: TextStyle(fontWeight: FontWeight.bold)),
                                        SizedBox(width: 16),
                                        Text('Price', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _receipt.items.length,
                                    itemBuilder: (context, index) {
                                      final item = _receipt.items[index];
                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(color: Colors.grey.shade300),
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.name != null && item.name!.isNotEmpty 
                                                  ? item.name! 
                                                  : 'Unknown Item',
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            SizedBox(
                                              width: 40,
                                              child: Text(
                                                '${item.quantity?.toStringAsFixed(0) ?? '1'}',
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              '${_receipt.currency ?? '₹'}${item.price?.toStringAsFixed(2) ?? '0.00'}',
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      border: Border(
                                        top: BorderSide(color: Colors.grey.shade300),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const Text('Total: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(
                                          '${_receipt.currency ?? '₹'}${_receipt.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_receipt.rawText != null) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Raw Text',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_receipt.rawText!),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}
