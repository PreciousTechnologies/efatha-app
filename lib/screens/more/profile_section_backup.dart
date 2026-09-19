import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';

/// Profile Section - Displays real user data from database
class ProfileSection extends StatefulWidget {
  const ProfileSection({super.key});

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  final _apiService = ApiService();
  final _storageService = StorageService();

  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // First, try to get data from local storage
      final localData = await _storageService.getUserData();

      // Then fetch fresh data from API
      final response = await _apiService.getCurrentUser();

      if (response['success'] == true && response['data'] != null) {
        // Update local storage with fresh data
        await _storageService.saveUserData(response['data']);

        setState(() {
          _userData = response['data'];
          _isLoading = false;
        });
      } else {
        // If API fails, use local data
        setState(() {
          _userData = localData.map((key, value) => MapEntry(key, value ?? ''));
          _isLoading = false;
          if (response['message'] != null) {
            _errorMessage = 'Using cached data: ${response['message']}';
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading profile: ${e.toString()}';
      });
    }
  }

  String _getInitials() {
    final firstName = _userData['first_name']?.toString() ?? '';
    final lastName = _userData['last_name']?.toString() ?? '';

    if (firstName.isEmpty && lastName.isEmpty) {
      return (_userData['email']?.toString() ?? 'U')[0].toUpperCase();
    }

    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
        .toUpperCase();
  }

  String _getFullName() {
    final firstName = _userData['first_name']?.toString() ?? '';
    final lastName = _userData['last_name']?.toString() ?? '';

    if (firstName.isEmpty && lastName.isEmpty) {
      return _userData['username']?.toString() ?? 'User';
    }

    return '$firstName $lastName'.trim();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'My Profile',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loadUserData,
            icon: const Icon(Icons.refresh),
            color: AppColors.primaryPurpleDeep,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message if any
              if (_errorMessage.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.orange[900]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Profile Picture Section
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryPurpleDeep,
                        AppColors.primaryPurpleVibrant,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurpleDeep.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Name and Email
              Center(
                child: Column(
                  children: [
                    Text(
                      _getFullName(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userData['email']?.toString() ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (_userData['church_position']?.toString().isNotEmpty ==
                        true) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryPurpleDeep,
                              AppColors.primaryPurpleVibrant,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _userData['church_position'].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Personal Information Card
              _buildSectionCard(
                title: 'Personal Information',
                icon: Icons.person_outline,
                gradient: [
                  AppColors.primaryPurpleDeep,
                  AppColors.primaryPurpleVibrant,
                ],
                children: [
                  _buildInfoRow(
                    'First Name',
                    _userData['first_name']?.toString() ?? '-',
                  ),
                  _buildInfoRow(
                    'Last Name',
                    _userData['last_name']?.toString() ?? '-',
                  ),
                  _buildInfoRow('Email', _userData['email']?.toString() ?? '-'),
                  _buildInfoRow(
                    'Phone',
                    _userData['phone_number']?.toString() ?? '-',
                  ),
                  _buildInfoRow(
                    'Username',
                    _userData['username']?.toString() ?? '-',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Church Information Card
              _buildSectionCard(
                title: 'Church Information',
                icon: Icons.church_outlined,
                gradient: [Colors.blue[700]!, Colors.blue[400]!],
                children: [
                  _buildInfoRow(
                    'Church Position',
                    _userData['church_position']?.toString() ?? '-',
                  ),
                  _buildInfoRow(
                    'Service Region',
                    _userData['service_region']?.toString() ?? '-',
                  ),
                  _buildInfoRow(
                    'Membership Number',
                    _userData['membership_number']?.toString() ?? '-',
                  ),
                  _buildInfoRow(
                    'Role',
                    _userData['role_display']?.toString() ??
                        _userData['role']?.toString() ??
                        '-',
                  ),
                  _buildInfoRow(
                    'Membership Status',
                    _userData['membership_status']?.toString() ?? '-',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Location Information Card
              _buildSectionCard(
                title: 'Location Information',
                icon: Icons.location_on_outlined,
                gradient: [Colors.green[700]!, Colors.green[400]!],
                children: [
                  _buildInfoRow(
                    'Country',
                    _userData['country']?.toString() ?? '-',
                  ),
                  _buildInfoRow(
                    'Region',
                    _userData['region']?.toString() ?? '-',
                  ),
                  _buildInfoRow('City', _userData['city']?.toString() ?? '-'),
                  _buildInfoRow(
                    'Address',
                    _userData['address']?.toString() ?? '-',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Bio Card (if available)
              if (_userData['bio']?.toString().isNotEmpty == true) ...[
                _buildSectionCard(
                  title: 'About Me',
                  icon: Icons.info_outline,
                  gradient: [Colors.orange[700]!, Colors.orange[400]!],
                  children: [
                    Text(
                      _userData['bio'].toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    // ignore: unused_element
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
