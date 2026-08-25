import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/finance_models.dart';
import '../services/finance_service.dart';
import '../widgets/gradient_button.dart';

class SavingsGoalScreen extends StatefulWidget {
  const SavingsGoalScreen({Key? key}) : super(key: key);

  @override
  State<SavingsGoalScreen> createState() => _SavingsGoalScreenState();
}

class _SavingsGoalScreenState extends State<SavingsGoalScreen> {
  // Helper method to convert icon name string to IconData constant
  IconData _getIconFromName(String iconName) {
    // Try to parse the icon code point
    try {
      int iconCode = int.parse(iconName);

      // Map common icon code points to constant IconData objects
      switch (iconCode) {
        case 0xe578:
          return Icons.savings;
        case 0xe430:
          return Icons.monetization_on;
        case 0xef63:
          return Icons.account_balance;
        case 0xe263:
          return Icons.credit_card;
        case 0xe8f8:
          return Icons.shopping_cart;
        case 0xe195:
          return Icons.attach_money;
        case 0xf090:
          return Icons.trending_up;
        case 0xeb43:
          return Icons.favorite;
        case 0xe80e:
          return Icons.home;
        case 0xe571:
          return Icons.flight;
        case 0xea49:
          return Icons.school;
        case 0xe57f:
          return Icons.directions_car;
        // Add more mappings as needed
        default:
          return Icons.savings; // Default icon
      }
    } catch (e) {
      // If parsing fails, return a default icon
      return Icons.savings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          // Refresh button to manually refresh savings goals
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              print('🔄 Manually refreshing savings goals...');
              await Provider.of<FinanceService>(
                context,
                listen: false,
              ).forceRefreshData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Savings goals refreshed'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<FinanceService>(
        builder: (context, financeService, _) {
          final goals = financeService.savingsGoals;
          print('\n🎯 SavingsGoalScreen rebuilding with ${goals.length} goals');
          print('📊 FinanceService instance: ${financeService.hashCode}');
          for (var goal in goals) {
            print(
              '  - ${goal.title}: ₹${goal.currentAmount} / ₹${goal.targetAmount} (id: ${goal.id})',
            );
          }

          return goals.isEmpty ? _buildEmptyState() : _buildGoalsList(goals);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context),
        label: const Text('New Goal'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No savings goals yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up savings goals to track your progress',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddGoalDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Goal'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(List<SavingsGoal> goals) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black;
        final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
        final progressBackgroundColor =
            isDarkMode ? Colors.grey[700] : Colors.grey[200];

        // Create gradient colors based on the goal's color
        final gradientColors = [
          goal.color.withOpacity(0.7),
          goal.color.withOpacity(0.3),
        ];

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: goal.color.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showGoalDetails(context, goal),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cardColor!, cardColor],
                  ),
                  border: Border.all(
                    color: goal.color.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Decorative elements
                      Positioned(
                        top: -15,
                        right: -15,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: goal.color.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20,
                        left: -20,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: goal.color.withOpacity(0.1),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Icon container with gradient
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: gradientColors,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: goal.color.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    goal.iconName != null
                                        ? _getIconFromName(goal.iconName!)
                                        : Icons.savings,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        goal.title,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      if (goal.description != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          goal.description!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: subtitleColor,
                                            letterSpacing: 0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Amount display with modern styling
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDarkMode
                                        ? Colors.black12
                                        : Colors.white10,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: goal.color.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Current',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: subtitleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${goal.currentAmount.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: goal.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Target',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: subtitleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${goal.targetAmount.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Progress section
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Remaining amount
                                    Text(
                                      'Remaining: ₹${goal.remainingAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: subtitleColor,
                                      ),
                                    ),
                                    // Progress percentage with pill background
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: goal.color.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${(goal.progress * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: goal.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Enhanced progress bar
                                Stack(
                                  children: [
                                    // Background
                                    Container(
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: progressBackgroundColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    // Progress
                                    Container(
                                      height: 12,
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.9 *
                                          goal.progress.clamp(0.0, 1.0),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            goal.color,
                                            goal.color.withBlue(
                                              (goal.color.blue + 40).clamp(
                                                0,
                                                255,
                                              ),
                                            ),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: goal.color.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Time remaining
                                if (goal.targetDate != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isDarkMode
                                              ? Colors.black12
                                              : Colors.white10,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            goal.daysRemaining < 30
                                                ? Colors.orange.withOpacity(0.3)
                                                : goal.color.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.timer_outlined,
                                          size: 16,
                                          color:
                                              goal.daysRemaining < 30
                                                  ? Colors.orange
                                                  : subtitleColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${goal.daysRemaining} days left',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                goal.daysRemaining < 30
                                                    ? Colors.orange
                                                    : subtitleColor,
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showGoalDetails(BuildContext context, SavingsGoal goal) {
    final addAmountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: goal.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          goal.iconName != null
                              ? _getIconFromName(goal.iconName!)
                              : Icons.savings,
                          color: goal.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          goal.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (goal.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      goal.description!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Goal progress
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Goal Progress',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${(goal.progress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: goal.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: goal.progress.clamp(0.0, 1.0),
                            backgroundColor: Colors.grey.shade200,
                            color: goal.isCompleted ? Colors.green : goal.color,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Saved'),
                                    Text(
                                      '₹${goal.currentAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text('Target'),
                                    Text(
                                      '₹${goal.targetAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Remaining'),
                                    Text(
                                      '\u{20B9}${goal.remainingAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            goal.isCompleted
                                                ? Colors.green
                                                : Colors.grey.shade700,
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
                  ),
                  const SizedBox(height: 16),
                  // Goal details
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Goal Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.calendar_today),
                            title: const Text('Created On'),
                            subtitle: Text(
                              DateFormat(
                                'MMM d, yyyy',
                              ).format(goal.createdDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (goal.targetDate != null)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.event),
                              title: const Text('Target Date'),
                              subtitle: Text(
                                DateFormat(
                                  'MMM d, yyyy',
                                ).format(goal.targetDate!),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Add funds section
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add Funds',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: addAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              prefixText: '\u{20B9} ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                print('🎯 Add Funds button pressed');
                                final amount = double.tryParse(
                                  addAmountController.text,
                                );
                                print(
                                  '📝 Parsed amount: $amount from text: ${addAmountController.text}',
                                );
                                if (amount == null || amount < 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a valid amount',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                // Show loading indicator
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Adding funds...'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }

                                // Add funds to savings goal
                                print(
                                  '🔥 About to call addToSavingsGoal with goalId: ${goal.id}, amount: $amount',
                                );
                                await Provider.of<FinanceService>(
                                  context,
                                  listen: false,
                                ).addToSavingsGoal(goal.id, amount);
                                print('✅ addToSavingsGoal completed');

                                // Wait a bit for the backend to process and UI to update
                                await Future.delayed(
                                  const Duration(milliseconds: 500),
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: goal.color,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Add Funds'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditGoalDialog(context, goal);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Goal'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmDeleteGoal(context, goal),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showAddGoalDialog(BuildContext context, [SavingsGoal? goal]) {
    final isEditing = goal != null;
    final titleController = TextEditingController(
      text: isEditing ? goal.title : '',
    );
    final descriptionController = TextEditingController(
      text: isEditing ? goal.description ?? '' : '',
    );
    final targetAmountController = TextEditingController(
      text: isEditing ? goal.targetAmount.toString() : '',
    );
    final currentAmountController = TextEditingController(
      text: isEditing ? goal.currentAmount.toString() : '0',
    );

    DateTime? targetDate = isEditing ? goal.targetDate : null;
    Color selectedColor = isEditing ? goal.color : Colors.blue;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickTargetDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate:
                    targetDate ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime(DateTime.now().year + 10),
              );
              if (picked != null) {
                setState(() {
                  targetDate = picked;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    isEditing ? 'Edit Savings Goal' : 'Create New Savings Goal',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Goal Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: targetAmountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Target Amount (₹)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: currentAmountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Initial Amount (\u{20B9})',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: pickTargetDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Target Date (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  targetDate != null
                                      ? DateFormat(
                                        'MMM d, yyyy',
                                      ).format(targetDate!)
                                      : 'No deadline',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                targetDate != null
                                    ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          targetDate = null;
                                        });
                                      },
                                    )
                                    : const Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Color:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children:
                          [
                            Colors.blue,
                            Colors.green,
                            Colors.red,
                            Colors.orange,
                            Colors.purple,
                            Colors.pink,
                            Colors.teal,
                            Colors.indigo,
                          ].map((color) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedColor = color;
                                });
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        selectedColor == color
                                            ? Colors.white
                                            : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow:
                                      selectedColor == color
                                          ? [
                                            BoxShadow(
                                              color: color.withOpacity(0.5),
                                              spreadRadius: 1,
                                              blurRadius: 4,
                                            ),
                                          ]
                                          : null,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    onPressed: () {
                      if (titleController.text.isEmpty ||
                          targetAmountController.text.isEmpty) {
                        return;
                      }

                      final double? targetAmount = double.tryParse(
                        targetAmountController.text,
                      );
                      if (targetAmount == null || targetAmount < 0) {
                        return;
                      }

                      final double? currentAmount = double.tryParse(
                        currentAmountController.text,
                      );
                      if (currentAmount == null || currentAmount < 0) {
                        return;
                      }

                      if (currentAmount > targetAmount) {
                        return;
                      }

                      final financeService = Provider.of<FinanceService>(
                        context,
                        listen: false,
                      );

                      final newGoal = SavingsGoal(
                        id: isEditing ? goal!.id : null,
                        title: titleController.text,
                        description:
                            descriptionController.text.isNotEmpty
                                ? descriptionController.text
                                : null,
                        targetAmount: targetAmount,
                        currentAmount: currentAmount,
                        targetDate: targetDate,
                        color: selectedColor,
                        iconName: 'savings',
                      );

                      if (isEditing) {
                        financeService.updateSavingsGoal(newGoal);
                      } else {
                        financeService.addSavingsGoal(newGoal);
                      }

                      Navigator.pop(context);
                    },
                    gradient: LinearGradient(
                      colors: [selectedColor, selectedColor.withOpacity(0.7)],
                    ),
                    child: Text(isEditing ? 'Update Goal' : 'Create Goal'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditGoalDialog(BuildContext context, SavingsGoal goal) {
    _showAddGoalDialog(context, goal);
  }

  void _confirmDeleteGoal(BuildContext context, SavingsGoal goal) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Savings Goal'),
            content: Text('Are you sure you want to delete "${goal.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Provider.of<FinanceService>(
                    context,
                    listen: false,
                  ).deleteSavingsGoal(goal.id);
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close bottom sheet
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
