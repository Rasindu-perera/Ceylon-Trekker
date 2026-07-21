import 'package:flutter/material.dart';
import '../app/app_theme.dart';

class Expense {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;

  Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
  });
}

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  double _totalBudget = 50000;
  final List<Expense> _expenses = [
    Expense(id: '1', title: 'Train to Ella', category: 'Transport', amount: 1500, date: DateTime.now().subtract(const Duration(days: 1))),
    Expense(id: '2', title: 'Lunch at Cafe', category: 'Food', amount: 3500, date: DateTime.now()),
  ];

  double get _totalSpent => _expenses.fold(0, (sum, item) => sum + item.amount);
  double get _remainingBalance => _totalBudget - _totalSpent;

  String _formatCurrency(double amount) {
    String result = amount.abs().toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < result.length; i++) {
      if (i > 0 && (result.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(result[i]);
    }
    return '${amount < 0 ? '-' : ''}LKR ${buffer.toString()}';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_bus;
      case 'Stay':
        return Icons.hotel;
      case 'Activities':
        return Icons.hiking;
      default:
        return Icons.money;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orangeAccent;
      case 'Transport':
        return Colors.blueAccent;
      case 'Stay':
        return Colors.deepPurpleAccent;
      case 'Activities':
        return AppTheme.emerald;
      default:
        return Colors.grey;
    }
  }

  void _showAddExpenseDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'Food';
    DateTime selectedDate = DateTime.now();
    final categories = ['Food', 'Transport', 'Stay', 'Activities'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add New Expense', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Expense Title',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (LKR)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Category', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: categories.map((cat) {
                      final isSelected = cat == selectedCategory;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setStateSheet(() => selectedCategory = cat);
                          }
                        },
                        backgroundColor: AppTheme.surface,
                        selectedColor: AppTheme.emerald,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected ? AppTheme.emerald : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        checkmarkColor: Colors.white,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Text('Date: ${_formatDate(selectedDate)}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: AppTheme.emerald,
                                    onPrimary: Colors.white,
                                    surface: AppTheme.surfaceElevated,
                                    onSurface: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            setStateSheet(() => selectedDate = date);
                          }
                        },
                        child: const Text('Change', style: TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                          final amount = double.tryParse(amountController.text);
                          if (amount != null) {
                            setState(() {
                              _expenses.add(
                                Expense(
                                  id: DateTime.now().toString(),
                                  title: titleController.text,
                                  category: selectedCategory,
                                  amount: amount,
                                  date: selectedDate,
                                )
                              );
                              _expenses.sort((a, b) => a.date.compareTo(b.date)); // Optional: sort list by date
                            });
                            Navigator.pop(context);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Save Expense', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditBudgetDialog() {
    final budgetController = TextEditingController(text: _totalBudget.toInt().toString());
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          title: const Text('Set Total Budget', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Budget (LKR)',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                final newBudget = double.tryParse(budgetController.text);
                if (newBudget != null) {
                  setState(() {
                    _totalBudget = newBudget;
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Trip Budget', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.emerald),
            onPressed: _showEditBudgetDialog,
            tooltip: 'Edit Budget',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSummaryHeader(),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Recent Expenses', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(
              child: _expenses.isEmpty
                  ? const Center(child: Text('No expenses added yet.', style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _expenses.length,
                      itemBuilder: (context, index) {
                        // Reverse list so newest is on top
                        final expense = _expenses[_expenses.length - 1 - index];
                        return _buildExpenseTile(expense);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 140.0),
        child: FloatingActionButton(
          onPressed: _showAddExpenseDialog,
          backgroundColor: AppTheme.emerald,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('Remaining Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(_remainingBalance),
            style: TextStyle(
              color: _remainingBalance >= 0 ? AppTheme.emerald : Colors.redAccent,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBlock('Total Budget', _totalBudget, Colors.white),
              _buildStatBlock('Total Spent', _totalSpent, Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBlock(String label, double amount, Color amountColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          _formatCurrency(amount),
          style: TextStyle(color: amountColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildExpenseTile(Expense expense) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          _expenses.removeWhere((e) => e.id == expense.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${expense.title} deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  _expenses.add(expense);
                  // Sort to maintain order if desired, though here it just goes back to end
                  _expenses.sort((a, b) => a.date.compareTo(b.date));
                });
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getCategoryColor(expense.category).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(_getCategoryIcon(expense.category), color: _getCategoryColor(expense.category)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${expense.category} • ${_formatDate(expense.date)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            Text(
              '-${_formatCurrency(expense.amount)}',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}