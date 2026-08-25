import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../models/finance_models.dart';
import '../services/finance_service.dart';
import '../widgets/gradient_button.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType type;
  final Transaction? transaction; // For editing existing transaction

  const AddTransactionScreen({
    Key? key,
    required this.type,
    this.transaction,
    this.initialTitle,
    this.initialAmount,
  }) : super(key: key);

  final String? initialTitle;
  final double? initialAmount;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _savingsBudgetController = TextEditingController();
  final _customGoalController = TextEditingController();
  
  bool _allocateToSavings = false;
  bool _isCustomGoal = false;
  SavingsGoal? _selectedSavingsGoal;
  
  late DateTime _selectedDate;
  late TransactionCategory _selectedCategory;
  File? _receipt;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.transaction != null) {
      // Editing existing transaction
      _titleController.text = widget.transaction!.title;
      _amountController.text = widget.transaction!.amount.toString();
      _descriptionController.text = widget.transaction!.description ?? '';
      _selectedDate = widget.transaction!.date;
      _selectedCategory = widget.transaction!.category;
      if (widget.transaction!.attachmentPath != null) {
        _receipt = File(widget.transaction!.attachmentPath!);
      }
    } else {
      // New transaction – use provided initial values if any
      if (widget.initialTitle != null) {
        _titleController.text = widget.initialTitle!;
      }
      if (widget.initialAmount != null) {
        _amountController.text = widget.initialAmount!.toStringAsFixed(2);
      }
      _descriptionController.text = '';
      _selectedDate = DateTime.now();
      // Default category based on transaction type
      if (widget.type == TransactionType.income) {
        _selectedCategory = TransactionCategory.salary;
      } else {
        _selectedCategory = TransactionCategory.other_expense;
      }
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _pickReceiptImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      setState(() {
        _receipt = File(image.path);
      });
    }
  }
  
  Future<void> _pickGalleryImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _receipt = File(image.path);
      });
    }
  }
  
  Future<String?> _saveReceiptImage() async {
    if (_receipt == null) return null;
    
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await _receipt!.copy('${directory.path}/$fileName');
    
    return savedImage.path;
  }
  
  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final financeService = Provider.of<FinanceService>(context, listen: false);
      final String? receiptPath = await _saveReceiptImage();
      
      final transaction = Transaction(
        id: widget.transaction?.id,
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        category: _selectedCategory,
        type: widget.type,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        attachmentPath: receiptPath ?? widget.transaction?.attachmentPath,
      );
      
      if (widget.transaction != null) {
        await financeService.updateTransaction(transaction);
      } else {
        await financeService.addTransaction(transaction);
      }
      
      // Handle savings allocation if enabled and it's an expense transaction
      if (widget.type == TransactionType.expense && _allocateToSavings && _selectedSavingsGoal != null && _savingsBudgetController.text.isNotEmpty) {
        final savingsAmount = double.tryParse(_savingsBudgetController.text) ?? 0;
        if (savingsAmount > 0) {
          // If it's a custom goal that doesn't exist yet, create it first
          if (_isCustomGoal && _selectedSavingsGoal!.id.startsWith('temp_custom_')) {
            final newGoal = SavingsGoal(
              id: null, // Let the service generate an ID
              title: _selectedSavingsGoal!.title,
              targetAmount: savingsAmount * 5, // Set a reasonable target (5x the initial amount)
              currentAmount: 0, // Will be updated by addToSavingsGoal
              color: Colors.teal,
              targetDate: DateTime.now().add(const Duration(days: 365)), // Default to 1 year
            );
            
            // Add the new goal to the service
            await financeService.addSavingsGoal(newGoal);
            
            // Get the newly created goal with proper ID
            final createdGoals = financeService.savingsGoals;
            final createdGoal = createdGoals.firstWhere(
              (g) => g.title == newGoal.title,
              orElse: () => newGoal,
            );
            
            // Now add the amount to the newly created goal
            await financeService.addToSavingsGoal(createdGoal.id, savingsAmount);
            
            if (mounted) {
              // SnackBar removed
            }
          } else {
            // Regular existing goal
            await financeService.addToSavingsGoal(_selectedSavingsGoal!.id, savingsAmount);
            
            if (mounted) {
              // SnackBar removed
            }
          }
        }
      }
      
      if (!mounted) return;
      Navigator.of(context).pop(true);
      
      // SnackBar removed
    } catch (e) {
      if (!mounted) return;
      // SnackBar removed
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == TransactionType.income;
    final categories = isIncome 
        ? CategoryMetadata.incomeCategories
        : CategoryMetadata.expenseCategories;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transaction != null
              ? 'Edit ${isIncome ? 'Income' : 'Expense'}'
              : 'Add ${isIncome ? 'Income' : 'Expense'}'
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
            child: const Icon(Icons.arrow_back),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Amount Input with currency prefix
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                      border: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        color: isIncome ? Colors.green.shade300 : Colors.red.shade300,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      if (double.parse(value) <= 0) {
                        return 'Amount must be greater than zero';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title Input
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: isIncome ? 'e.g., Salary, Freelance Work' : 'e.g., Rent, Groceries',
                filled: true,
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Category Selection
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Category',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = category == _selectedCategory;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? category.color.withOpacity(0.2) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? category.color : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? category.color : Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    category.icon,
                                    color: isSelected ? Colors.white : Colors.grey.shade700,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  category.displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? category.color : Colors.grey.shade800,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Date Selection
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description Input
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add additional notes...',
                filled: true,
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 2,
            ),
            
            // Only show savings allocation for expense transactions
            if (widget.type == TransactionType.expense) ...[
              const SizedBox(height: 24),
              
              // Budget Savings Allocation Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.savings_outlined, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Allocate to Savings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _allocateToSavings,
                          onChanged: (value) {
                            setState(() {
                              _allocateToSavings = value;
                              if (!value) {
                                _selectedSavingsGoal = null;
                                _savingsBudgetController.clear();
                              }
                            });
                          },
                          activeColor: Colors.blue.shade700,
                        ),
                      ],
                    ),
                    if (_allocateToSavings) ...[
                      const SizedBox(height: 16),
                      Consumer<FinanceService>(
                        builder: (context, financeService, _) {
                          final savingsGoals = financeService.savingsGoals;
                          
                          if (savingsGoals.isEmpty) {
                            return Column(
                              children: [
                                const Text(
                                  'No savings goals found. Create a savings goal first.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/savings_goals');
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Savings Goal'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            );
                          }
                          
                          // Predefined goals
                          final predefinedGoals = [
                            {'icon': Icons.house, 'title': 'Home', 'color': Colors.blue},
                            {'icon': Icons.directions_car, 'title': 'Vehicle', 'color': Colors.green},
                            {'icon': Icons.school, 'title': 'Education', 'color': Colors.purple},
                            {'icon': Icons.flight_takeoff, 'title': 'Travel', 'color': Colors.orange},
                            {'icon': Icons.shopping_bag, 'title': 'Shopping', 'color': Colors.pink},
                            {'icon': Icons.medical_services, 'title': 'Medical', 'color': Colors.red},
                          ];
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Select Savings Goal:', style: TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 12),
                              
                              // Existing goals section
                              if (savingsGoals.isNotEmpty) ...[
                                const Text('Your Goals:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Container(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: savingsGoals.length,
                                    itemBuilder: (context, index) {
                                      final goal = savingsGoals[index];
                                      final isSelected = _selectedSavingsGoal == goal && !_isCustomGoal;
                                      
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedSavingsGoal = goal;
                                            _isCustomGoal = false;
                                          });
                                        },
                                        child: Container(
                                          width: 100,
                                          margin: const EdgeInsets.only(right: 10),
                                          decoration: BoxDecoration(
                                            color: isSelected ? goal.color.withOpacity(0.2) : Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected ? goal.color : Colors.grey.shade300,
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.savings_outlined, 
                                                color: isSelected ? goal.color : Colors.grey.shade700,
                                                size: 28,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                goal.title,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  color: isSelected ? goal.color : Colors.grey.shade800,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                              
                              const SizedBox(height: 16),
                              const Text('Suggested Goals:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                              const SizedBox(height: 8),
                              
                              // Predefined goals section
                              Container(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: predefinedGoals.length + 1, // +1 for custom option
                                  itemBuilder: (context, index) {
                                    // Custom option is the last item
                                    if (index == predefinedGoals.length) {
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isCustomGoal = true;
                                            _customGoalController.clear();
                                          });
                                          
                                          // Show dialog to create custom goal
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Create Custom Goal'),
                                              content: TextField(
                                                controller: _customGoalController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Goal Name',
                                                  hintText: 'Enter your goal name',
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    if (_customGoalController.text.isNotEmpty) {
                                                      // Create a temporary goal for display purposes
                                                      final customGoal = SavingsGoal(
                                                        id: 'temp_custom_${DateTime.now().millisecondsSinceEpoch}',
                                                        title: _customGoalController.text,
                                                        targetAmount: 0,
                                                        currentAmount: 0,
                                                        color: Colors.teal,
                                                      );
                                                      
                                                      setState(() {
                                                        _selectedSavingsGoal = customGoal;
                                                        _isCustomGoal = true;
                                                      });
                                                      
                                                      Navigator.pop(context);
                                                    }
                                                  },
                                                  child: const Text('Create'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: 100,
                                          margin: const EdgeInsets.only(right: 10),
                                          decoration: BoxDecoration(
                                            color: _isCustomGoal ? Colors.teal.withOpacity(0.2) : Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _isCustomGoal ? Colors.teal : Colors.grey.shade300,
                                              width: _isCustomGoal ? 2 : 1,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_circle_outline, 
                                                color: _isCustomGoal ? Colors.teal : Colors.grey.shade700,
                                                size: 28,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                _isCustomGoal && _selectedSavingsGoal != null 
                                                    ? _selectedSavingsGoal!.title 
                                                    : 'Custom',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: _isCustomGoal ? FontWeight.bold : FontWeight.normal,
                                                  color: _isCustomGoal ? Colors.teal : Colors.grey.shade800,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                    
                                    // Predefined goals
                                    final goal = predefinedGoals[index];
                                    final isSelected = !_isCustomGoal && 
                                        _selectedSavingsGoal != null && 
                                        _selectedSavingsGoal!.title == goal['title'];
                                    
                                    return GestureDetector(
                                      onTap: () {
                                        // Check if this goal already exists in user's goals
                                        final existingGoal = savingsGoals.firstWhere(
                                          (g) => g.title == goal['title'],
                                          orElse: () => SavingsGoal(
                                            id: 'predefined_${goal['title']}',
                                            title: goal['title'] as String,
                                            targetAmount: 0,
                                            currentAmount: 0,
                                            color: goal['color'] as Color,
                                          ),
                                        );
                                        
                                        setState(() {
                                          _selectedSavingsGoal = existingGoal;
                                          _isCustomGoal = false;
                                        });
                                      },
                                      child: Container(
                                        width: 100,
                                        margin: const EdgeInsets.only(right: 10),
                                        decoration: BoxDecoration(
                                          color: isSelected 
                                              ? (goal['color'] as Color).withOpacity(0.2) 
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected 
                                                ? (goal['color'] as Color) 
                                                : Colors.grey.shade300,
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              goal['icon'] as IconData, 
                                              color: isSelected 
                                                  ? (goal['color'] as Color) 
                                                  : Colors.grey.shade700,
                                              size: 28,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              goal['title'] as String,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                color: isSelected 
                                                    ? (goal['color'] as Color) 
                                                    : Colors.grey.shade800,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _savingsBudgetController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Amount to Allocate (₹)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.currency_rupee),
                                ),
                                validator: (value) {
                                  if (_allocateToSavings && _selectedSavingsGoal != null) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter an amount';
                                    }
                                    final amount = double.tryParse(value);
                                    if (amount == null || amount < 0) {
                                      return 'Please enter a valid amount';
                                    }
                                    final totalAmount = double.tryParse(_amountController.text) ?? 0;
                                    if (amount > totalAmount) {
                                      return 'Cannot exceed transaction amount';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Attachment Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipt (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _receipt != null
                          ? Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: FileImage(_receipt!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _receipt = null;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickReceiptImage,
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Take photo'),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Theme.of(context).primaryColor,
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(color: Colors.grey.shade300),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickGalleryImage,
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Gallery'),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Theme.of(context).primaryColor,
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(color: Colors.grey.shade300),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Save Button
            GradientButton(
              onPressed: _isLoading ? null : _saveTransaction,
              gradient: LinearGradient(
                colors: isIncome
                    ? [Colors.green.shade400, Colors.green.shade700]
                    : [Colors.deepOrange.shade400, Colors.deepOrange.shade700],
              ),
              child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.transaction != null ? 'Update' : 'Save',
                    style: const TextStyle(fontSize: 16),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
