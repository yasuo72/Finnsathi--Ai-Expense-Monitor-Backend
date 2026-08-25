import 'package:flutter/material.dart';
import '../../models/shop_models.dart';

class ShopFiltersScreen extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApplyFilters;
  
  const ShopFiltersScreen({
    super.key, 
    required this.currentFilters,
    required this.onApplyFilters,
  });

  @override
  State<ShopFiltersScreen> createState() => _ShopFiltersScreenState();
}

class _ShopFiltersScreenState extends State<ShopFiltersScreen> {
  late Map<String, dynamic> _filters;
  final List<String> _cuisineTypes = [
    'Indian', 'Chinese', 'Italian', 'Mexican', 'Thai', 
    'Japanese', 'American', 'Mediterranean', 'Healthy', 'Desserts'
  ];
  
  @override
  void initState() {
    super.initState();
    // Create a deep copy of the current filters
    _filters = Map<String, dynamic>.from(widget.currentFilters);
    
    // Initialize default values if not present
    _filters['rating'] ??= 0.0;
    _filters['priceRange'] ??= const RangeValues(0, 500);
    _filters['deliveryTime'] ??= 60; // max delivery time in minutes
    _filters['cuisineTypes'] ??= <String>[];
    _filters['dietary'] ??= <String>[];
    _filters['sortBy'] ??= 'rating';
    _filters['verifiedOnly'] ??= false;
  }
  
  void _resetFilters() {
    setState(() {
      _filters = {
        'rating': 0.0,
        'priceRange': const RangeValues(0, 500),
        'deliveryTime': 60,
        'cuisineTypes': <String>[],
        'dietary': <String>[],
        'sortBy': 'rating',
        'verifiedOnly': false,
      };
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Shops'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text(
              'Reset',
              style: TextStyle(
                color: secondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating Filter
            _buildSectionTitle('Minimum Rating'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _filters['rating'],
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label: _filters['rating'].toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _filters['rating'] = value;
                      });
                    },
                    activeColor: secondaryColor,
                    inactiveColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _filters['rating'].toStringAsFixed(1),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Price Range Filter
            _buildSectionTitle('Price Range'),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '₹${_filters['priceRange'].start.round()}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Expanded(
                  child: RangeSlider(
                    values: _filters['priceRange'],
                    min: 0,
                    max: 500,
                    divisions: 10,
                    labels: RangeLabels(
                      '₹${_filters['priceRange'].start.round()}',
                      '₹${_filters['priceRange'].end.round()}',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _filters['priceRange'] = values;
                      });
                    },
                    activeColor: secondaryColor,
                    inactiveColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                Text(
                  '₹${_filters['priceRange'].end.round()}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Delivery Time Filter
            _buildSectionTitle('Max Delivery Time'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _filters['deliveryTime'].toDouble(),
                    min: 15,
                    max: 60,
                    divisions: 9,
                    label: '${_filters['deliveryTime']} min',
                    onChanged: (value) {
                      setState(() {
                        _filters['deliveryTime'] = value.round();
                      });
                    },
                    activeColor: secondaryColor,
                    inactiveColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_filters['deliveryTime']} min',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Cuisine Types Filter
            _buildSectionTitle('Cuisine Types'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _cuisineTypes.map((cuisine) {
                final isSelected = (_filters['cuisineTypes'] as List<String>).contains(cuisine);
                return FilterChip(
                  label: Text(
                    cuisine,
                    style: TextStyle(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.onSecondary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        (_filters['cuisineTypes'] as List<String>).add(cuisine);
                      } else {
                        (_filters['cuisineTypes'] as List<String>).remove(cuisine);
                      }
                    });
                  },
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  selectedColor: secondaryColor,
                  checkmarkColor: Theme.of(context).colorScheme.onSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Dietary Preferences
            _buildSectionTitle('Dietary Preferences'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Vegetarian', 'Vegan', 'Gluten-free', 'Keto', 'Low Calorie'].map((diet) {
                final isSelected = (_filters['dietary'] as List<String>).contains(diet);
                return FilterChip(
                  label: Text(
                    diet,
                    style: TextStyle(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.onSecondary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        (_filters['dietary'] as List<String>).add(diet);
                      } else {
                        (_filters['dietary'] as List<String>).remove(diet);
                      }
                    });
                  },
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  selectedColor: secondaryColor,
                  checkmarkColor: Theme.of(context).colorScheme.onSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Sort By
            _buildSectionTitle('Sort By'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSortOption('rating', 'Rating'),
                _buildSortOption('deliveryTime', 'Delivery Time'),
                _buildSortOption('priceAsc', 'Price: Low to High'),
                _buildSortOption('priceDesc', 'Price: High to Low'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Verified Only Toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Verified Shops Only',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Switch(
                  value: _filters['verifiedOnly'],
                  onChanged: (value) {
                    setState(() {
                      _filters['verifiedOnly'] = value;
                    });
                  },
                  activeColor: secondaryColor,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApplyFilters(_filters);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
  
  Widget _buildSortOption(String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final isSelected = _filters['sortBy'] == value;
    
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected 
              ? Theme.of(context).colorScheme.onSecondary
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filters['sortBy'] = value;
          });
        }
      },
      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      selectedColor: secondaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
