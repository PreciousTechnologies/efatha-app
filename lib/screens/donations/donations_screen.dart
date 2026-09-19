import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/donations_service.dart';
import 'donation_flow_screen.dart';

/// Donations Screen - Giving and financial contributions
class DonationsScreen extends StatefulWidget {
  const DonationsScreen({super.key});

  @override
  State<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsScreen> {
  final DonationsService _donationsService = DonationsService();

  String _selectedPeriod = 'Monthly';
  String _selectedCategory = 'All';
  bool _showHistory = false;
  bool _isLoading = true;

  // Real data from database
  double _totalAmount = 0;
  int _totalCount = 0;
  double _averageAmount = 0;
  String _currency = 'TZS';
  List<Map<String, dynamic>> _donations = [];

  final List<String> _periods = ['Weekly', 'Monthly', 'Yearly'];

  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Tithe',
      'subtitle': '10% of your income',
      'icon': Icons.account_balance_wallet,
      'gradient': [Color(0xFF6B4CE6), Color(0xFF9B7FED)],
    },
    {
      'title': 'Charity',
      'subtitle': 'Help those in need',
      'icon': Icons.volunteer_activism,
      'gradient': [Color(0xFFE91E63), Color(0xFFFF4081)],
    },
    {
      'title': 'Gratitude',
      'subtitle': 'Thanksgiving offering',
      'icon': Icons.favorite,
      'gradient': [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
    },
    {
      'title': 'Gospel',
      'subtitle': 'Spread the good news',
      'icon': Icons.auto_stories,
      'gradient': [Color(0xFF4CAF50), Color(0xFF66BB6A)],
    },
    {
      'title': 'Firstfruits',
      'subtitle': 'First of your harvest',
      'icon': Icons.grass,
      'gradient': [Color(0xFFFFB74D), Color(0xFFFFCC80)],
    },
    {
      'title': 'Construction',
      'subtitle': 'Building projects',
      'icon': Icons.construction,
      'gradient': [Color(0xFF42A5F5), Color(0xFF64B5F6)],
    },
    {
      'title': 'Others',
      'subtitle': 'Other contributions',
      'icon': Icons.card_giftcard,
      'gradient': [Color(0xFF9C27B0), Color(0xFFBA68C8)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDonationData();
  }

  Future<void> _loadDonationData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch donation statistics
      final statsResult = await _donationsService.getDonationStats(
        period: _selectedPeriod,
      );

      // Fetch donation history
      final historyResult = await _donationsService.getDonationHistory(
        category: _selectedCategory,
        period: _selectedPeriod,
      );

      if (mounted) {
        setState(() {
          if (statsResult['success'] == true) {
            _totalAmount = (statsResult['total_amount'] ?? 0).toDouble();
            _totalCount = statsResult['total_count'] ?? 0;
            _averageAmount = (statsResult['average_amount'] ?? 0).toDouble();
            _currency = statsResult['currency'] ?? 'TZS';
          }

          if (historyResult['success'] == true) {
            _donations = List<Map<String, dynamic>>.from(
              historyResult['donations'] ?? [],
            );
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading donations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getCurrentMonthName() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = _getCurrentMonthName();
    final periodLabel = _selectedPeriod == 'Weekly'
        ? 'This Week'
        : _selectedPeriod == 'Monthly'
        ? currentMonth
        : 'This Year';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Modern Header with White Background
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _showHistory
                          ? AppColors.primaryPurpleLight.withValues(alpha: 0.2)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.history,
                      color: _showHistory
                          ? AppColors.primaryPurpleDeep
                          : Colors.black87,
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _showHistory = !_showHistory;
                    });
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(color: Colors.white),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Give',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Each of you should give what you have decided in your heart to give',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '2 Corinthians 9:7',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Total Giving Summary Card
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPurpleDeep,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Giving ${_selectedPeriod == "Monthly"
                                    ? "This Month"
                                    : _selectedPeriod == "Weekly"
                                    ? "This Week"
                                    : "This Year"}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  periodLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getCurrencySymbol(_currency),
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _totalAmount.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontSize: 48,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                '.${(_totalAmount % 1 * 100).toInt().toString().padLeft(2, "0")}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        _totalCount.toString(),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Donations',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${_getCurrencySymbol(_currency)}${_averageAmount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Average',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  const Text(
                    'Choose Category',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurpleLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_categories.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryPurpleDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Category Cards Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final category = _categories[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _DonationCategoryCard(
                    title: category['title'],
                    subtitle: category['subtitle'],
                    icon: category['icon'],
                    gradient: category['gradient'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DonationFlowScreen(category: category['title']),
                        ),
                      );
                    },
                  ),
                );
              }, childCount: _categories.length),
            ),
          ),

          // Donation History Section
          if (_showHistory) ...[
            SliverToBoxAdapter(child: SizedBox(height: 32)),

            // History Header with Filters
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Donation History',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Period Filter
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Time Period:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _periods.map((period) {
                          final isSelected = _selectedPeriod == period;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(period),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedPeriod = period;
                                });
                                _loadDonationData();
                              },
                              backgroundColor: Colors.white,
                              selectedColor: AppColors.primaryPurpleLight
                                  .withValues(alpha: 0.2),
                              checkmarkColor: AppColors.primaryPurpleDeep,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primaryPurpleDeep
                                    : Colors.grey[700],
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primaryPurpleDeep
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Category Filter
                    Row(
                      children: [
                        Icon(Icons.category, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Category:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            [
                              'All',
                              ..._categories.map(
                                (cat) => cat['title'] as String,
                              ),
                            ].map((category) {
                              final isSelected = _selectedCategory == category;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                    _loadDonationData();
                                  },
                                  backgroundColor: Colors.white,
                                  selectedColor: AppColors.primaryPurpleLight
                                      .withValues(alpha: 0.2),
                                  checkmarkColor: AppColors.primaryPurpleDeep,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? AppColors.primaryPurpleDeep
                                        : Colors.grey[700],
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primaryPurpleDeep
                                        : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // History List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final historyItems = _getFilteredHistory();
                  if (index >= historyItems.length) return null;

                  final item = historyItems[index];
                  final category = item['category'] ?? 'Others';
                  final amount = (item['amount'] is num)
                      ? (item['amount'] as num).toDouble()
                      : 0.0;
                  final currency = item['currency'] ?? _currency;
                  final date = item['created_at'] ?? item['date'] ?? 'N/A';

                  return _DonationHistoryCard(
                    category: category,
                    amount: amount,
                    date: date,
                    currency: currency,
                    gradient: _getCategoryGradient(category),
                  );
                }, childCount: _getFilteredHistory().length),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredHistory() {
    // Use real data from database
    List<Map<String, dynamic>> filtered = List.from(_donations);

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where(
            (item) =>
                item['category']?.toString().toLowerCase() ==
                _selectedCategory.toLowerCase(),
          )
          .toList();
    }

    return filtered;
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'TZS':
        return 'TSh ';
      case 'KES':
        return 'KSh ';
      case 'UGX':
        return 'USh ';
      case 'RWF':
        return 'RWF ';
      default:
        return '$currency ';
    }
  }

  List<Color> _getCategoryGradient(String category) {
    final cat = _categories.firstWhere(
      (c) => c['title'] == category,
      orElse: () => _categories[0],
    );
    return cat['gradient'];
  }
}

class _DonationCategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _DonationCategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonationHistoryCard extends StatelessWidget {
  final String category;
  final double amount;
  final String date;
  final String currency;
  final List<Color> gradient;

  const _DonationHistoryCard({
    required this.category,
    required this.amount,
    required this.date,
    required this.currency,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
                  Text(
                    _getCurrencySymbol(currency),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: gradient[0],
                    ),
                  ),
                  Text(
                    amount.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: gradient[0],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                currency,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'TZS':
        return 'TSh ';
      case 'KES':
        return 'KSh ';
      default:
        return '\$';
    }
  }
}
