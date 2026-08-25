import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/finance_models.dart';
import '../services/finance_service.dart';
import '../widgets/app_drawer.dart';
import 'gamification/gamification_screen.dart';

class StatisticsScreen extends StatefulWidget {
  final void Function()? onAddExpense;
  final void Function()? onAddIncome;
  final void Function()? onReceiptScanner;

  const StatisticsScreen({
    Key? key,
    this.onAddExpense,
    this.onAddIncome,
    this.onReceiptScanner,
  }) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with TickerProviderStateMixin {
  // Tab controller
  late TabController _tabController;

  // Date ranges for filtering
  late DateTime _currentMonth;
  late DateTime _startOfMonth;
  late DateTime _endOfMonth;

  // UI state variables
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  // Data variables
  double income = 0.0;
  double expense = 0.0;
  double savings = 0.0;
  List<Transaction> transactions = [];
  Map<String, double> incomeByCategory = {};
  Map<String, double> expenseByCategory = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 4 tabs: Overview, Income, Expenses, Trends
    _initDateRange();
    
    // Fetch data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initDateRange() {
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _updateDateRange();
  }

  void _updateDateRange() {
    _startOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    _endOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
  }

  // Navigation methods using standard Navigator.pushNamed
  // Navigation methods for FAB removed

  // Month navigation methods removed as they are no longer needed

  // Safely fetch data with error handling
  Future<void> _fetchData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final financeService = Provider.of<FinanceService>(context, listen: false);

      // Get transactions for the current month
      final monthTransactions = financeService.getTransactionsForDateRange(
          _startOfMonth,
          _endOfMonth
      );

      // Calculate totals
      double totalIncome = 0.0;
      double totalExpense = 0.0;
      Map<String, double> incomeCategories = {};
      Map<String, double> expenseCategories = {};

      for (var transaction in monthTransactions) {
        if (transaction.type == TransactionType.income) {
          totalIncome += transaction.amount;

          // Aggregate by category
          final category = transaction.category?.name ?? 'Other';
          incomeCategories[category] = (incomeCategories[category] ?? 0) + transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          totalExpense += transaction.amount;

          // Aggregate by category
          final category = transaction.category?.name ?? 'Other';
          expenseCategories[category] = (expenseCategories[category] ?? 0) + transaction.amount;
        }
      }

      if (!mounted) return;

      setState(() {
        transactions = monthTransactions;
        income = totalIncome;
        expense = totalExpense;
        savings = totalIncome - totalExpense;
        incomeByCategory = incomeCategories;
        expenseByCategory = expenseCategories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          child: const Text('Statistics'),
        ),
        actions: [
          // Gamification button with animated effects
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: IconButton(
                    icon: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.amber,
                      size: 28,
                    ),
                    tooltip: 'Finance Quest',
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const GamificationScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            var begin = const Offset(1.0, 0.0);
                            var end = Offset.zero;
                            var curve = Curves.easeOutCubic;
                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            return SlideTransition(position: animation.drive(tween), child: child);
                          },
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
        elevation: 0,
        backgroundColor: theme.primaryColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Income'),
            Tab(text: 'Expenses'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/statistics'),
      body: _hasError
          ? _buildErrorView()
          : _isLoading
          ? _buildLoadingView()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(income, expense, savings),
          _buildIncomeTab(),
          _buildExpensesTab(),
          _buildTrendsTab(),
        ],
      ),
      // Floating action button removed
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'An error occurred',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(_errorMessage ?? 'Could not load statistics'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading statistics...'),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Text(
          DateFormat('MMMM yyyy').format(_currentMonth),
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(double income, double expense, double savings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSelector(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeInOut,
            child: _buildSummaryCards(income, expense, savings),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              'Financial Summary',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Theme.of(context).primaryColor,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _buildSummaryChart(income, expense),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(double income, double expense, double savings) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Income',
                '₹${income.toStringAsFixed(0)}',
                Icons.arrow_upward,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Expenses',
                '₹${expense.toStringAsFixed(0)}',
                Icons.arrow_downward,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(
          'Savings',
          '₹${savings.toStringAsFixed(0)}',
          Icons.savings,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? Colors.grey[850]! : Colors.white,
              isDark ? Colors.grey[900]! : Colors.grey[50]!,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryChart(double income, double expense) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: isDark ? 4 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Income vs Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: _buildBarChart(income, expense, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(double income, double expense, bool isDark) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.center,
        maxY: max(income, expense) * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String text = '';
                switch (value.toInt()) {
                  case 0:
                    text = 'Income';
                    break;
                  case 1:
                    text = 'Expense';
                    break;
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(text, style: const TextStyle(fontSize: 12)),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('₹${value.toInt()}', style: const TextStyle(fontSize: 10));
              },
              reservedSize: 40,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: income,
                color: Colors.green,
                width: 30,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: expense,
                color: Colors.red,
                width: 30,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Income tab with category breakdown and analytics
  Widget _buildIncomeTab() {
    final financeService = Provider.of<FinanceService>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get income transactions for the selected period
    final incomeTransactions = financeService
        .getTransactionsForDateRange(_startOfMonth, _endOfMonth)
        .where((t) => t.type == TransactionType.income)
        .toList();

    // Group by category
    final categoryMap = <TransactionCategory, List<Transaction>>{};
    for (var transaction in incomeTransactions) {
      if (transaction.category == null) continue;

      final category = transaction.category;
      if (!categoryMap.containsKey(category)) {
        categoryMap[category] = [];
      }
      categoryMap[category]?.add(transaction);
    }

    // Empty state handling
    if (incomeTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No income transactions in ${DateFormat('MMMM yyyy').format(_currentMonth)}',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/add-income'),
              icon: const Icon(Icons.add),
              label: const Text('Add Income'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSelector(),
          const SizedBox(height: 16),

          // Income summary card
          _buildSummaryCard(
            'Total Income',
            '₹${income.toStringAsFixed(0)}',
            Icons.arrow_upward,
            Colors.green,
          ),

          const SizedBox(height: 24),

          // Income frequency analysis
          _buildIncomeFrequencyCard(incomeTransactions),

          const SizedBox(height: 24),

          // Category breakdown heading
          Text(
            'Income by Category',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Category breakdown visualization
          _buildIncomePieChart(),

          const SizedBox(height: 24),

          // Category list with details
          _buildEnhancedIncomeCategoryList(categoryMap),
        ],
      ),
    );
  }

  // Income frequency analysis card
  Widget _buildIncomeFrequencyCard(List<Transaction> transactions) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate frequency metrics
    final daysInPeriod = _endOfMonth.difference(_startOfMonth).inDays + 1;
    final incomeFrequency = transactions.length / daysInPeriod;
    final avgIncomeAmount = transactions.isNotEmpty
        ? transactions.fold(0.0, (sum, t) => sum + t.amount) / transactions.length
        : 0.0;

    // Get most common income source if available
    String mostCommonSource = 'N/A';
    if (transactions.isNotEmpty) {
      final sourceCount = <String, int>{};
      for (var t in transactions) {
        final source = t.category.name ?? 'Other';
        sourceCount[source] = (sourceCount[source] ?? 0) + 1;
      }

      if (sourceCount.isNotEmpty) {
        mostCommonSource = sourceCount.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        mostCommonSource = mostCommonSource[0].toUpperCase() + mostCommonSource.substring(1);
      }
    }

    return Card(
      elevation: isDark ? 3 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Income Insights',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInsightRow(
              'Average Income',
              '₹${avgIncomeAmount.toStringAsFixed(0)}',
              Icons.payments,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInsightRow(
              'Income Frequency',
              '${incomeFrequency.toStringAsFixed(1)} per day',
              Icons.calendar_today,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInsightRow(
              'Most Common Source',
              mostCommonSource,
              Icons.source,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  // Helper for building insight rows
  Widget _buildInsightRow(String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  // Expenses tab with comprehensive analytics
  Widget _buildExpensesTab() {
    final financeService = Provider.of<FinanceService>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get expense transactions for the selected period
    final expenseTransactions = financeService
        .getTransactionsForDateRange(_startOfMonth, _endOfMonth)
        .where((t) => t.type == TransactionType.expense)
        .toList();

    // Group by category
    final categoryMap = <TransactionCategory, List<Transaction>>{};
    for (var transaction in expenseTransactions) {
      if (transaction.category == null) continue;

      if (!categoryMap.containsKey(transaction.category)) {
        categoryMap[transaction.category] = [];
      }
      categoryMap[transaction.category]?.add(transaction);
    }

    // Empty state handling
    if (expenseTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No expense transactions in ${DateFormat('MMMM yyyy').format(_currentMonth)}',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/add-expense'),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Calculate expense metrics
    final totalExpense = expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final avgExpensePerTransaction = expenseTransactions.length > 0
        ? totalExpense / expenseTransactions.length
        : 0.0;

    // Calculate expense frequency
    final daysInPeriod = _endOfMonth.difference(_startOfMonth).inDays + 1;
    final expenseFrequency = expenseTransactions.length / daysInPeriod;

    // Get top expense categories
    final sortedCategories = categoryMap.entries.toList();
    sortedCategories.sort((a, b) {
      final aTotal = a.value.fold(0.0, (sum, t) => sum + t.amount);
      final bTotal = b.value.fold(0.0, (sum, t) => sum + t.amount);
      return bTotal.compareTo(aTotal);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSelector(),
          const SizedBox(height: 16),

          // Expense summary card
          _buildSummaryCard(
            'Total Expenses',
            '₹${totalExpense.toStringAsFixed(0)}',
            Icons.arrow_downward,
            Colors.red,
          ),

          const SizedBox(height: 24),

          // Expense analysis
          _buildExpenseAnalysisCard(expenseTransactions, daysInPeriod, avgExpensePerTransaction, expenseFrequency),

          const SizedBox(height: 24),

          // Day of week spending pattern
          _buildDayOfWeekSpendingCard(expenseTransactions),

          const SizedBox(height: 24),

          // Category breakdown heading
          Text(
            'Expenses by Category',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Category breakdown visualization
          _buildExpensePieChart(),

          const SizedBox(height: 24),

          // Category list with details
          _buildEnhancedExpenseCategoryList(categoryMap),
        ],
      ),
    );
  }

  // Expense analysis card
  Widget _buildExpenseAnalysisCard(List<Transaction> transactions, int daysInPeriod, double avgAmount, double frequency) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get most expensive day if available
    String mostExpensiveDay = 'N/A';
    double highestDailySpend = 0.0;

    if (transactions.isNotEmpty) {
      // Group by day
      final dailySpending = <DateTime, double>{};
      for (var t in transactions) {
        final date = DateTime(t.date.year, t.date.month, t.date.day);
        dailySpending[date] = (dailySpending[date] ?? 0) + t.amount;
      }

      if (dailySpending.isNotEmpty) {
        final entry = dailySpending.entries.reduce(
                (a, b) => a.value > b.value ? a : b);
        mostExpensiveDay = DateFormat('MMM d').format(entry.key);
        highestDailySpend = entry.value;
      }
    }

    return Card(
      elevation: isDark ? 3 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense Insights',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInsightRow(
              'Average Expense',
              '₹${avgAmount.toStringAsFixed(0)}',
              Icons.receipt,
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildInsightRow(
              'Daily Spending',
              '₹${(transactions.fold(0.0, (sum, t) => sum + t.amount) / daysInPeriod).toStringAsFixed(0)}',
              Icons.calendar_today,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildInsightRow(
              'Highest Spend Day',
              '$mostExpensiveDay (₹${highestDailySpend.toStringAsFixed(0)})',
              Icons.trending_up,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  // Day of week spending patterns
  Widget _buildDayOfWeekSpendingCard(List<Transaction> transactions) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Group transactions by day of week and calculate total for each day
    final dayTotals = List<double>.filled(7, 0.0); // Sun to Sat

    for (var transaction in transactions) {
      final dayOfWeek = transaction.date.weekday % 7; // 0 = Sunday, 6 = Saturday
      dayTotals[dayOfWeek] += transaction.amount;
    }

    // Find max value for scaling
    final maxValue = dayTotals.reduce(max);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuint,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Pattern by Day',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: _buildWeekdayBarChart(dayTotals, maxValue, isDark),
            ),
          ],
        ),
      ),
    );
  }

  // Bar chart for day of week spending
  Widget _buildWeekdayBarChart(List<double> dayTotals, double maxValue, bool isDark) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final barColors = [
      Colors.red.shade300,
      Colors.orange.shade300,
      Colors.yellow.shade300,
      Colors.green.shade300,
      Colors.blue.shade300,
      Colors.indigo.shade300,
      Colors.purple.shade300,
    ];

    // Find highest spending day
    int maxIndex = 0;
    for (int i = 1; i < dayTotals.length; i++) {
      if (dayTotals[i] > dayTotals[maxIndex]) {
        maxIndex = i;
      }
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.1,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${days[groupIndex]}\n₹${dayTotals[groupIndex].toStringAsFixed(0)}',
                TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    days[value.toInt()],
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      fontSize: 12,
                      fontWeight: value.toInt() == maxIndex ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        barGroups: List.generate(
          7,
              (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: dayTotals[index],
                color: barColors[index],
                width: 22,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxValue,
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Trends tab showing monthly comparisons
  Widget _buildTrendsTab() {
    final financeService = Provider.of<FinanceService>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get transactions for the current and previous months
    final currentMonthTransactions = financeService.getTransactionsForDateRange(
        _startOfMonth,
        _endOfMonth
    );

    // Previous month date range
    final previousMonthStart = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    final previousMonthEnd = DateTime(_currentMonth.year, _currentMonth.month, 0);

    // Get previous month transactions
    final previousMonthTransactions = financeService.getTransactionsForDateRange(
        previousMonthStart,
        previousMonthEnd
    );

    // Calculate totals for current month
    final currentIncome = currentMonthTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final currentExpense = currentMonthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Calculate totals for previous month
    final previousIncome = previousMonthTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final previousExpense = previousMonthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Empty state handling
    if (currentMonthTransactions.isEmpty && previousMonthTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No transaction data available to analyze',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/add-income'),
              icon: const Icon(Icons.add),
              label: const Text('Add Transaction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSelector(),
          const SizedBox(height: 24),

          // Month-to-month comparison
          _buildMonthComparisonCard(currentIncome, previousIncome, currentExpense, previousExpense),

          const SizedBox(height: 24),

          // Savings analysis
          _buildSavingsCard(),

          const SizedBox(height: 16),

          _buildSavingsRateCard(),

          const SizedBox(height: 24),

          // Income vs Expense visualization
          Text(
            'Income vs Expense Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildIncomePieChart(),
              ),
              Expanded(
                child: _buildExpensePieChart(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Monthly trend visualization
          Text(
            'Monthly Trends',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          _buildMonthlyTrendsChart(),

          const SizedBox(height: 24),

          // Predictive analytics section
          Text(
            'Predictive Analytics',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          _buildPredictiveAnalyticsCard(currentIncome, previousIncome, currentExpense, previousExpense),
        ],
      ),
    );
  }

  // Income pie chart visualization
  Widget _buildIncomePieChart() {
    if (incomeByCategory.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No income data available for this period'),
        ),
      );
    }

    // Calculate total for percentages
    final total = incomeByCategory.values.fold(0.0, (sum, amount) => sum + amount);

    // Generate pie chart sections
    final sections = <PieChartSectionData>[];
    final items = incomeByCategory.entries.toList();

    // Sort by amount (descending)
    items.sort((a, b) => b.value.compareTo(a.value));

    // Generate colors for sections
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
    ];

    for (var i = 0; i < items.length; i++) {
      final entry = items[i];
      final percentage = (entry.value / total) * 100;
      final color = i < colors.length ? colors[i] : Colors.grey;

      sections.add(
        PieChartSectionData(
          value: entry.value,
          title: '${percentage.toStringAsFixed(1)}%',
          color: color,
          radius: 100,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              // Could implement selection highlight here
            },
          ),
        ),
      ),
    );
  }

  // Expense pie chart visualization
  Widget _buildExpensePieChart() {
    if (expenseByCategory.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No expense data available for this period'),
        ),
      );
    }

    // Calculate total for percentages
    final total = expenseByCategory.values.fold(0.0, (sum, amount) => sum + amount);

    // Generate pie chart sections
    final sections = <PieChartSectionData>[];
    final items = expenseByCategory.entries.toList();

    // Sort by amount (descending)
    items.sort((a, b) => b.value.compareTo(a.value));

    // Generate colors for sections
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.purple,
      Colors.indigo,
      Colors.pink,
      Colors.brown,
      Colors.deepOrange,
    ];

    for (var i = 0; i < items.length; i++) {
      final entry = items[i];
      final percentage = (entry.value / total) * 100;
      final color = i < colors.length ? colors[i] : Colors.grey;

      sections.add(
        PieChartSectionData(
          value: entry.value,
          title: '${percentage.toStringAsFixed(1)}%',
          color: color,
          radius: 100,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              // Could implement selection highlight here
            },
          ),
        ),
      ),
    );
  }

  // Enhanced income category list with details
  Widget _buildEnhancedIncomeCategoryList(Map<TransactionCategory, List<Transaction>> categoryMap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (categoryMap.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate totals and percentages
    final items = <MapEntry<TransactionCategory, double>>[];
    double total = 0.0;

    for (var entry in categoryMap.entries) {
      final amount = entry.value.fold(0.0, (sum, t) => sum + t.amount);
      items.add(MapEntry(entry.key, amount));
      total += amount;
    }

    // Sort by amount (descending)
    items.sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: isDark ? 3 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Income Sources',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...List.generate(items.length, (index) {
              final category = items[index].key;
              final amount = items[index].value;
              final percentage = (amount / total) * 100;
              final count = categoryMap[category]!.length;

              return _buildCategoryItem(
                category.displayName,
                '${percentage.toStringAsFixed(1)}%',
                category.icon,
                '₹${amount.toStringAsFixed(0)}',
                category.color.withOpacity(isDark ? 0.8 : 0.2),
                category.color,
                percentage,
                '$count ${count == 1 ? 'transaction' : 'transactions'}',
              );
            }),
          ],
        ),
      ),
    );
  }

  // Enhanced expense category list with details
  Widget _buildEnhancedExpenseCategoryList(Map<TransactionCategory, List<Transaction>> categoryMap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (categoryMap.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate totals and percentages
    final items = <MapEntry<TransactionCategory, double>>[];
    double total = 0.0;

    for (var entry in categoryMap.entries) {
      final amount = entry.value.fold(0.0, (sum, t) => sum + t.amount);
      items.add(MapEntry(entry.key, amount));
      total += amount;
    }

    // Sort by amount (descending)
    items.sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: isDark ? 3 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense Categories',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...List.generate(items.length, (index) {
              final category = items[index].key;
              final amount = items[index].value;
              final percentage = (amount / total) * 100;
              final count = categoryMap[category]!.length;

              return _buildCategoryItem(
                category.displayName,
                '${percentage.toStringAsFixed(1)}%',
                category.icon,
                '₹${amount.toStringAsFixed(0)}',
                category.color.withOpacity(isDark ? 0.8 : 0.2),
                category.color,
                percentage,
                '$count ${count == 1 ? 'transaction' : 'transactions'}',
              );
            }),
          ],
        ),
      ),
    );
  }

  // Helper to build a category item
  Widget _buildCategoryItem(
      String title,
      String percent,
      IconData icon,
      String amount,
      Color bg,
      Color fg,
      double percentValue,
      [String? subtitle]
      ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isDark ? Colors.white : fg, size: 24),
          ),
          const SizedBox(width: 12),
          // Category details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category title
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentValue / 100,
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Amount and percentage
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                percent,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? fg.withOpacity(0.9) : fg,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // This is replaced by _buildEnhancedExpenseCategoryList

  // Monthly trends chart
  Widget _buildMonthlyTrendsChart() {
    // This would normally fetch data for multiple months
    // For now, we'll just use current month data

    final spots = [
      FlSpot(0, income),
      FlSpot(1, expense),
    ];

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  String text = '';
                  switch (value.toInt()) {
                    case 0:
                      text = 'Income';
                      break;
                    case 1:
                      text = 'Expense';
                      break;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(text, style: const TextStyle(fontSize: 12)),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('₹${value.toInt()}', style: const TextStyle(fontSize: 10));
                },
                reservedSize: 40,
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Savings rate card for trends tab
  Widget _buildSavingsCard() {
    final savingsRate = income > 0 ? (savings / income) * 100 : 0.0;
    final savingsColor = savingsRate >= 0 ? Colors.green : Colors.red;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.savings, color: savingsColor),
                const SizedBox(width: 8),
                const Text(
                  'This Month\'s Savings',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '₹${savings.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: savingsColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Month comparison card for trends tab
  Widget _buildMonthComparisonCard(double currentIncome, double previousIncome,
      double currentExpense, double previousExpense) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentMonth = DateFormat('MMMM').format(_currentMonth);
    final previousMonth = DateFormat('MMMM').format(DateTime(_currentMonth.year, _currentMonth.month - 1));

    // Calculate percentage changes
    final incomeChange = previousIncome > 0
        ? ((currentIncome - previousIncome) / previousIncome) * 100
        : 0.0;

    final expenseChange = previousExpense > 0
        ? ((currentExpense - previousExpense) / previousExpense) * 100
        : 0.0;

    return Card(
      elevation: isDark ? 3 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Month-to-Month Comparison',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Income comparison
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.green.withOpacity(0.2) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Income',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentMonth,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '₹${currentIncome.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.green.withOpacity(0.9) : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  previousMonth,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '₹${previousIncome.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(
                          incomeChange >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 14,
                          color: incomeChange >= 0 ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${incomeChange.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: incomeChange >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      incomeChange >= 0 ? 'Increase' : 'Decrease',
                      style: TextStyle(
                        fontSize: 12,
                        color: incomeChange >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Expense comparison
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.red.withOpacity(0.2) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_downward,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expenses',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentMonth,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '₹${currentExpense.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.red.withOpacity(0.9) : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  previousMonth,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '₹${previousExpense.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(
                          expenseChange >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 14,
                          color: expenseChange >= 0 ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${expenseChange.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: expenseChange >= 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      expenseChange >= 0 ? 'Increase' : 'Decrease',
                      style: TextStyle(
                        fontSize: 12,
                        color: expenseChange >= 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Savings rate visualization for trends tab
  Widget _buildSavingsRateCard() {
    final savingsRate = income > 0 ? (savings / income) * 100 : 0.0;
    final savingsColor = savingsRate >= 0 ? Colors.green : Colors.red;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Savings Rate',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '${savingsRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: savingsColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (savingsRate / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    color: savingsColor,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              savingsRate >= 20
                  ? 'Excellent savings rate!'
                  : savingsRate >= 10
                  ? 'Good savings rate'
                  : savingsRate >= 0
                  ? 'Try to increase your savings'
                  : 'You\'re spending more than you earn',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helpers

  // Predictive analytics card with forecasts
  Widget _buildPredictiveAnalyticsCard(double currentIncome, double previousIncome,
      double currentExpense, double previousExpense) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate predicted values using simple linear projection
    // For a more sophisticated app, this would use machine learning models
    final incomeGrowthRate = previousIncome > 0
        ? (currentIncome - previousIncome) / previousIncome
        : 0.0;

    final expenseGrowthRate = previousExpense > 0
        ? (currentExpense - previousExpense) / previousExpense
        : 0.0;

    // Project next month values
    final predictedIncome = currentIncome * (1 + incomeGrowthRate);
    final predictedExpense = currentExpense * (1 + expenseGrowthRate);
    final predictedSavings = predictedIncome - predictedExpense;

    // Calculate savings rate projection
    final currentSavingsRate = currentIncome > 0
        ? ((currentIncome - currentExpense) / currentIncome) * 100
        : 0.0;

    final predictedSavingsRate = predictedIncome > 0
        ? (predictedSavings / predictedIncome) * 100
        : 0.0;

    // Determine if financial health is improving
    final isImproving = predictedSavingsRate > currentSavingsRate;

    return Card(
      elevation: isDark ? 3 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Next Month Forecast',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isImproving
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isImproving ? 'Improving' : 'Declining',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isImproving ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Predicted income card
            _buildPredictionItem(
              'Income',
              currentIncome,
              predictedIncome,
              Icons.trending_up,
              Colors.green,
            ),

            const SizedBox(height: 16),

            // Predicted expense card
            _buildPredictionItem(
              'Expenses',
              currentExpense,
              predictedExpense,
              Icons.trending_down,
              Colors.red,
            ),

            const SizedBox(height: 16),

            // Predicted savings card
            _buildPredictionItem(
              'Savings',
              currentIncome - currentExpense,
              predictedSavings,
              Icons.savings,
              Colors.blue,
            ),

            const SizedBox(height: 16),

            // Financial health indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isImproving
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isImproving ? Icons.health_and_safety : Icons.warning,
                    color: isImproving ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isImproving
                              ? 'Your financial health is improving'
                              : 'Your financial health needs attention',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isImproving
                              ? 'Keep up the good work! Your savings rate is projected to increase.'
                              : 'Consider reducing expenses or finding additional income sources.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build prediction item
  Widget _buildPredictionItem(String title, double current, double predicted,
      IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final percentChange = current > 0
        ? ((predicted - current) / current) * 100
        : 0.0;

    final isPositive = predicted > current;
    final isGood = (title == 'Income' || title == 'Savings') ? isPositive : !isPositive;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Row(
                children: [
                  Text(
                    '₹${predicted.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? color.withOpacity(0.9) : color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 12,
                    color: isGood ? Colors.green : Colors.red,
                  ),
                  Text(
                    '${percentChange.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: isGood ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Current',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Text(
              '₹${current.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Returns a deterministic color based on the category name.
  Color _getCategoryColor(String category, {bool isExpense = false}) {
    final colors = isExpense
        ? [
            Colors.red,
            Colors.orange,
            Colors.amber,
            Colors.purple,
            Colors.indigo,
            Colors.pink,
            Colors.brown,
            Colors.deepOrange,
          ]
        : [
            Colors.blue,
            Colors.green,
            Colors.teal,
            Colors.cyan,
            Colors.lightBlue,
            Colors.lime,
            Colors.lightGreen,
            Colors.indigoAccent,
          ];

    // Generate a deterministic color based on category name
    final index = category.hashCode % colors.length;
    return colors[index.abs()];
  }
}
