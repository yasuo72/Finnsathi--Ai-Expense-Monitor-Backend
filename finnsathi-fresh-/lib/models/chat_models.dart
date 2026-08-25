enum MessageSender {
  user,
  ai
}

class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.text,
    required this.sender,
    DateTime? timestamp,
    String? id,
    this.isLoading = false,
  }) : 
    this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    this.timestamp = timestamp ?? DateTime.now();

  // Create a loading message placeholder while AI is generating a response
  factory ChatMessage.loading() {
    return ChatMessage(
      text: 'Thinking...',
      sender: MessageSender.ai,
      isLoading: true,
    );
  }
  
  // Copy with method for updating messages
  ChatMessage copyWith({
    String? id,
    String? text,
    MessageSender? sender,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Predefined responses and prompts for the AI
class AIResponseGenerator {
  // Sample questions to suggest to the user
  static List<String> getSampleQuestionsForScreen(String screen) {
    final map = <String, List<String>>{
      'Monthly Budget Analysis': [
        'Show me my spending breakdown for this month',
        'Which category exceeded budget?',
        'How does this month compare to last?',
        'What is my average daily spending this month?',
        'Which days had the highest expenses?',
        'How much budget do I have left in each category?',
        'Did I stay within my overall budget?',
        'Alert me if any category goes over 90% of budget',
        'Suggest adjustments to balance my budget',
        'Forecast my spending for the rest of the month',
      ],
      'Savings Plan Assistant': [
        'Help me set a goal to save ₹50,000',
        'How much should I save weekly?',
        'Suggest ways to boost my savings rate',
        'How long will it take to reach my emergency fund target?',
        'What’s my current savings rate?',
        'Recommend how to transfer surplus funds to savings',
        'Remind me to save right after payday',
        'Compare my savings goal progress month-over-month',
        'Recommend high-yield savings account options',
        'How can I automate my savings?',
      ],
      'Expense Optimization': [
        'Where can I cut expenses?',
        'Give me tips to lower my food budget',
        'Find redundant subscriptions',
        'Show my top 5 discretionary expenses',
        'Suggest cheaper alternatives to my recurring bills',
        'Predict savings from cancelling streaming services',
        'How much could I save by cooking at home?',
        'Recommend ways to reduce utility costs',
        'Identify unusually high transactions this month',
        'Create a 10% cost-cutting plan',
      ],
      'Income vs Expenses': [
        'Compare my total income and expenses',
        'Am I spending more than I earn?',
        'Plot income vs expenses trend',
        'What percentage of income do I save?',
        'How much of my income goes to fixed costs?',
        'Show income vs expense by category',
        'Forecast my net cash flow this month',
        'Did my expenses grow faster than income?',
        'Calculate my break-even date each month',
        'Suggest strategies to increase my disposable income',
      ],
    };
    return map[screen] ?? getGenericSampleQuestions();
  }

  static List<String> getGenericSampleQuestions() {
    return [
      'How much did I spend this month?',
      "What's my biggest expense category?",
      'How am I doing on my savings goals?',
      'Compare my income vs expenses',
      'What financial advice can you give me?',
      'How can I improve my budget?',
      'Show spending trends for the last 6 months',
      'What is my current savings rate?',
      'Identify my top 3 recurring expenses',
      'Suggest ways to optimize my budget',
    ];
  }
  
  // Generate greeting message
  static List<String> getSampleQuestions() => getGenericSampleQuestions();
  
  static String getGreeting() {
    final hour = DateTime.now().hour;
    String greeting = "Hello";
    
    if (hour < 12) {
      greeting = "Good morning";
    } else if (hour < 17) {
      greeting = "Good afternoon";
    } else {
      greeting = "Good evening";
    }
    
    return "$greeting! I'm your FinnSathi AI assistant. I can help answer questions about your finances, analyze your spending patterns, and offer personalized advice. What would you like to know today?";
  }
}
