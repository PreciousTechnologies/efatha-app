import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// User Management Screen - Admin interface for managing church members
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Members',
    'Leaders',
    'Pastors',
    'Admins',
  ];

  final List<Map<String, dynamic>> _users = [
    {
      'name': 'Sarah Johnson',
      'email': 'sarah.j@example.com',
      'role': 'Member',
      'status': 'Active',
      'joined': 'Jan 2020',
      'avatar': 'SJ',
      'color': Colors.pink,
    },
    {
      'name': 'Michael Brown',
      'email': 'michael.b@example.com',
      'role': 'Leader',
      'status': 'Active',
      'joined': 'Mar 2019',
      'avatar': 'MB',
      'color': Colors.blue,
    },
    {
      'name': 'Grace Kimathi',
      'email': 'grace.k@example.com',
      'role': 'Pastor',
      'status': 'Active',
      'joined': 'Jun 2018',
      'avatar': 'GK',
      'color': Colors.purple,
    },
    {
      'name': 'David Mwangi',
      'email': 'david.m@example.com',
      'role': 'Admin',
      'status': 'Active',
      'joined': 'Jan 2018',
      'avatar': 'DM',
      'color': Colors.orange,
    },
    {
      'name': 'Emily White',
      'email': 'emily.w@example.com',
      'role': 'Member',
      'status': 'Inactive',
      'joined': 'Nov 2021',
      'avatar': 'EW',
      'color': Colors.teal,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'User Management',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppColors.primaryPurpleDeep),
            onPressed: () {},
          ),
          IconButton(
            onPressed: _showAddUserDialog,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurpleDeep,
                    AppColors.primaryPurpleVibrant,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Stats Cards
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Users',
                    '156',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Active',
                    '142',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Inactive',
                    '14',
                    Icons.cancel,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          Container(
            height: 60,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                    },
                    backgroundColor: Colors.grey[100],
                    selectedColor: AppColors.primaryPurpleLight.withValues(
                      alpha: 0.3,
                    ),
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
                    ),
                  ),
                );
              },
            ),
          ),

          // Users List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                return _buildUserCard(_users[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [user['color'], user['color'].withOpacity(0.7)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user['avatar'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user['email'],
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildBadge(user['role'], _getRoleColor(user['role'])),
                    const SizedBox(width: 8),
                    _buildBadge(
                      user['status'],
                      user['status'] == 'Active' ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'role',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, size: 18),
                    SizedBox(width: 8),
                    Text('Change Role'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation(user['name']);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return Colors.red;
      case 'Pastor':
        return Colors.purple;
      case 'Leader':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New User'),
        content: const Text('User creation form - Coming Soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('User deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
