import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/finance_service.dart';
import '../models/finance_models.dart';

class BudgetSavingsScreen extends StatefulWidget {
  const BudgetSavingsScreen({Key? key}) : super(key: key);

  @override
  State<BudgetSavingsScreen> createState() => _BudgetSavingsScreenState();
}

class _BudgetSavingsScreenState extends State<BudgetSavingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  SavingsGoal? _selectedGoal;
  bool _isCustomGoal = false;
  final _customGoalController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _customGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allocate to Savings'),
        elevation: 0,
      ),
      body: Consumer<FinanceService>(builder: (context, financeService, _) {
        final savingsGoals = financeService.savingsGoals;

        // Predefined goals
        final predefinedGoals = [
          {'icon': Icons.house, 'title': 'Home', 'color': Colors.blue},
          {'icon': Icons.directions_car, 'title': 'Vehicle', 'color': Colors.green},
          {'icon': Icons.school, 'title': 'Education', 'color': Colors.purple},
          {'icon': Icons.flight_takeoff, 'title': 'Travel', 'color': Colors.orange},
          {'icon': Icons.shopping_bag, 'title': 'Shopping', 'color': Colors.pink},
          {'icon': Icons.medical_services, 'title': 'Medical', 'color': Colors.red},
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.savings, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            const Text(
                              'Budget Savings Summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Calculate total savings
                        Text(
                          'Total Saved: ₹${savingsGoals.fold(0.0, (sum, goal) => sum + goal.currentAmount).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Active Goals: ${savingsGoals.length}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Allocate Funds to Savings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Existing goals section
                if (savingsGoals.isNotEmpty) ...[                  
                  const Text('Your Goals:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: savingsGoals.length,
                      itemBuilder: (context, index) {
                        final goal = savingsGoals[index];
                        final isSelected = _selectedGoal == goal && !_isCustomGoal;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedGoal = goal;
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
                const Text('Suggested Goals:', style: TextStyle(fontSize: 14, color: Colors.grey)),
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
                                          _selectedGoal = customGoal;
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
                                  _isCustomGoal && _selectedGoal != null
                                      ? _selectedGoal!.title
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
                          _selectedGoal != null &&
                          _selectedGoal!.title == goal['title'];

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
                            _selectedGoal = existingGoal;
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

                const SizedBox(height: 24),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount to Allocate (₹)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.currency_rupee),
                  ),
                  validator: (value) {
                    if (_selectedGoal != null) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                    } else {
                      return 'Please select a goal first';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _allocateToSavings(financeService),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Allocate Funds',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _allocateToSavings(FinanceService financeService) async {
    if (!_formKey.currentState!.validate()) return;

    final savingsAmount = double.tryParse(_amountController.text) ?? 0;
    if (savingsAmount <= 0 || _selectedGoal == null) return;

    try {
      // If it's a custom goal that doesn't exist yet, create it first
      if (_isCustomGoal && _selectedGoal!.id.startsWith('temp_custom_')) {
        final newGoal = SavingsGoal(
          id: null, // Let the service generate an ID
          title: _selectedGoal!.title,
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

        // SnackBar removed
      } else {
        // Regular existing goal
        await financeService.addToSavingsGoal(_selectedGoal!.id, savingsAmount);

        // SnackBar removed
      }

      // Create a transaction record for this allocation
      final transaction = Transaction(
        id: null,
        title: 'Allocation to ${_selectedGoal!.title}',
        amount: savingsAmount,
        date: DateTime.now(),
        category: TransactionCategory.other_expense, // Using other_expense for savings allocations
        type: TransactionType.expense,
        description: 'Funds allocated to savings goal: ${_selectedGoal!.title}',
      );

      await financeService.addTransaction(transaction);

      // Clear form
      _amountController.clear();
      setState(() {
        _selectedGoal = null;
        _isCustomGoal = false;
      });
    } catch (e) {
      // SnackBar removed
    }
  }
}
