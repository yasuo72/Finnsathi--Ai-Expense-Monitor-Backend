import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service_manager.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({Key? key}) : super(key: key);

  @override
  _ApiTestScreenState createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  bool _isLoading = false;
  String _resultMessage = '';
  bool _isSuccess = false;
  bool _useMockData = true;
  String _backendUrl = 'http://10.0.2.2:5000/api';
  String _token = '';
  
  // Predefined backend URLs
  final List<Map<String, String>> _predefinedUrls = [
    {'name': 'Android Emulator (10.0.2.2)', 'url': 'http://10.0.2.2:5000/api'},
    {'name': 'Local Network (10.224.26.28)', 'url': 'http://10.224.26.28:5000/api'},
    {'name': 'Localhost', 'url': 'http://localhost:5000/api'},
    {'name': 'Production', 'url': 'https://finnsathi-api.example.com/api'},
    {'name': 'Custom', 'url': ''},
  ];
  
  // Currently selected URL option
  String _selectedUrlOption = 'Android Emulator (10.0.2.2)';

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
    _checkApiStatus();
  }
  
  // Load current API settings
  Future<void> _loadCurrentSettings() async {
    final apiManager = Provider.of<ApiServiceManager>(context, listen: false);
    setState(() {
      _useMockData = apiManager.useMockData;
      _backendUrl = apiManager.apiBaseUrl;
      
      // Find the matching predefined URL or set to Custom
      final matchingUrl = _predefinedUrls.firstWhere(
        (urlOption) => urlOption['url'] == _backendUrl,
        orElse: () => {'name': 'Custom', 'url': _backendUrl},
      );
      _selectedUrlOption = matchingUrl['name']!;
    });
  }
  
  // Save API settings
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });
    
    try {
      // Update API settings
      final apiManager = Provider.of<ApiServiceManager>(context, listen: false);
      await apiManager.updateSettings(
        useMockData: _useMockData,
        apiBaseUrl: _backendUrl,
      );
      
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _resultMessage = 'API settings saved successfully! Using $_backendUrl\nMock Data: ${_useMockData ? 'Enabled' : 'Disabled'}';
      });
      
      // Test the connection with new settings
      _checkApiStatus();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _resultMessage = 'Error saving settings: $e';
      });
    }
  }
  
  // Check API status
  Future<void> _checkApiStatus() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });
    
    try {
      if (_useMockData) {
        await _testMockApiConnection();
      } else {
        await _testApiConnection();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _resultMessage = 'API connection failed: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Connection Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backend Connection Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'API URL: $_backendUrl',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Use Mock Data:'),
                        Switch(
                          value: _useMockData,
                          onChanged: (value) {
                            setState(() {
                              _useMockData = value;
                            });
                          },
                        ),
                      ],
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Backend URL',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedUrlOption,
                      items: _predefinedUrls.map((urlOption) {
                        return DropdownMenuItem<String>(
                          value: urlOption['name'],
                          child: Text(urlOption['name']!),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedUrlOption = newValue;
                            // Find the URL that corresponds to the selected name
                            final selectedUrlMap = _predefinedUrls.firstWhere(
                              (urlOption) => urlOption['name'] == newValue,
                              orElse: () => {'name': '', 'url': ''},
                            );
                            _backendUrl = selectedUrlMap['url'] ?? '';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Custom Backend URL (optional)',
                        hintText: 'Enter custom URL if not in dropdown',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            _backendUrl = value;
                            _selectedUrlOption = 'Custom';
                            
                            // Update the Custom URL in the predefined URLs list
                            final customIndex = _predefinedUrls.indexWhere(
                              (urlOption) => urlOption['name'] == 'Custom'
                            );
                            
                            if (customIndex >= 0) {
                              _predefinedUrls[customIndex] = {
                                'name': 'Custom',
                                'url': value
                              };
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Auth Token (optional)',
                        hintText: 'JWT token',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _token = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('Save API Settings'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_resultMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isSuccess ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Text(
                          _resultMessage,
                          style: TextStyle(
                            color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _testApiConnection,
              child: const Text('Test Connection'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _isLoading ? null : _testFetchTransactions,
              child: const Text('Test Fetch Transactions'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _isLoading ? null : _testFetchBudgets,
              child: const Text('Test Fetch Budgets'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _isLoading ? null : _testFetchSavingsGoals,
              child: const Text('Test Fetch Savings Goals'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Mock API Testing',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testMockApiConnection,
              child: const Text('Test Mock API'),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Future<void> _testApiConnection() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      // Simple GET request to the root API endpoint
      final result = await _makeGetRequest(_backendUrl);
      
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _resultMessage = 'Connection successful! Response: ${result.toString()}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _resultMessage = 'Connection failed: ${e.toString()}';
      });
    }
  }
  
  Future<void> _testMockApiConnection() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock response
      final mockResponse = {
        'success': true,
        'message': 'Mock API is working!',
        'data': {
          'serverTime': DateTime.now().toIso8601String(),
          'status': 'healthy',
          'environment': 'development'
        }
      };
      
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _resultMessage = 'Mock API Response: ${jsonEncode(mockResponse)}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _resultMessage = 'Mock API failed: ${e.toString()}';
      });
    }
  }

  Future<void> _testFetchTransactions() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      if (_useMockData) {
        // Simulate API delay
        await Future.delayed(const Duration(seconds: 1));
        
        // Mock transactions response
        final mockTransactions = [
          {'id': '1', 'title': 'Groceries', 'amount': 1500, 'type': 'expense', 'category': 'Food'},
          {'id': '2', 'title': 'Salary', 'amount': 50000, 'type': 'income', 'category': 'Salary'},
          {'id': '3', 'title': 'Restaurant', 'amount': 2000, 'type': 'expense', 'category': 'Food'},
        ];
        
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _resultMessage = 'Fetched ${mockTransactions.length} mock transactions: \n${jsonEncode(mockTransactions)}';
        });
      } else {
        final apiManager = Provider.of<ApiServiceManager>(context, listen: false);
        await apiManager.initializeData();
        
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _resultMessage = 'Fetched ${apiManager.transactions.length} transactions';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _resultMessage = 'Failed to fetch transactions: ${e.toString()}';
      });
    }
  }

  Future<void> _testFetchBudgets() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      final apiManager = Provider.of<ApiServiceManager>(context, listen: false);
      await apiManager.initializeData();
      
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _resultMessage = 'Fetched ${apiManager.budgets.length} budgets';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _resultMessage = 'Failed to fetch budgets: ${e.toString()}';
      });
    }
  }

  Future<void> _testFetchSavingsGoals() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      final apiManager = Provider.of<ApiServiceManager>(context, listen: false);
      await apiManager.initializeData();
      
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _resultMessage = 'Fetched ${apiManager.savingsGoals.length} savings goals';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _resultMessage = 'Failed to fetch savings goals: ${e.toString()}';
      });
    }
  }

  Future<dynamic> _makeGetRequest(String url) async {
    if (_useMockData) {
      // Simulated response for testing
      return await Future.delayed(const Duration(seconds: 1), () {
        return {'message': 'Mock API is working!'};
      });
    } else {
      try {
        // Real API request
        final headers = <String, String>{
          'Content-Type': 'application/json',
        };
        
        if (_token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $_token';
        }
        
        final response = await http.get(
          Uri.parse(url),
          headers: headers,
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return jsonDecode(response.body);
        } else {
          throw Exception('API Error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        throw Exception('Request failed: $e');
      }
    }
  }
}
