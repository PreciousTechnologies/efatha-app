import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/supabase_auth_service.dart';
import '../../core/services/supabase_storage_service.dart';
import '../../core/config/api_config.dart';
import 'edit_profile_screen.dart';

/// Profile Section - Displays real user data from database with edit capabilities
class ProfileSection extends StatefulWidget {
  const ProfileSection({super.key});

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  final _apiService = ApiService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();

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
      // Supabase-first (Django fallback while migrating).
      if (SupabaseConfig.isConfigured) {
        try {
          final profile = await SupabaseAuthService().getCurrentProfile();
          if (profile != null && mounted) {
            setState(() {
              _userData = profile;
              _isLoading = false;
            });
            return;
          }
        } catch (_) {
          // Fall through to Django.
        }
      }

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
      final email = _userData['email']?.toString() ?? '';
      return email.isNotEmpty ? email[0].toUpperCase() : 'U';
    }

    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
        .toUpperCase();
  }

  String _getFullName() {
    final firstName = _userData['first_name']?.toString() ?? '';
    final middleName = _userData['middle_name']?.toString() ?? '';
    final lastName = _userData['last_name']?.toString() ?? '';

    if (firstName.isEmpty && lastName.isEmpty) {
      return _userData['username']?.toString() ?? 'User';
    }

    return '$firstName ${middleName.isNotEmpty ? middleName : ''} $lastName'
        .replaceAll('  ', ' ')
        .trim();
  }

  // Get the correct profile picture URL (handle both relative and absolute URLs)
  String? _getProfilePictureUrl() {
    final profilePicture = _userData['profile_picture'];
    if (profilePicture == null) return null;

    final url = profilePicture.toString();
    // If it's already a full URL, return as-is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Otherwise, prepend the base URL from ApiConfig
    return '${ApiConfig.baseUrl}$url';
  }

  Future<void> _showProfilePictureOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Profile Picture',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: AppColors.primaryPurpleDeep,
                ),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfilePicture(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primaryPurpleDeep,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfilePicture(ImageSource.gallery);
                },
              ),
              if (_userData['profile_picture'] != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteProfilePicture();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProfilePicture(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Show loading indicator
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        // Supabase-first (Django fallback while migrating).
        if (SupabaseConfig.isConfigured) {
          try {
            final auth = SupabaseAuthService();
            final uid = auth.currentUser?.id;
            if (uid == null) throw Exception('Not authenticated');
            final url = await SupabaseStorageService().uploadProfilePicture(
              uid,
              File(pickedFile.path),
            );
            await auth.updateProfile({'profile_picture_url': url});
            if (!mounted) return;
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully'),
                backgroundColor: AppColors.successGreenPrimary,
              ),
            );
            await _loadUserData(); // Reload user data
          } catch (e) {
            if (!mounted) return;
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload profile picture: $e'),
                backgroundColor: AppColors.dangerRedPrimary,
              ),
            );
          }
          return;
        }

        // Upload to backend
        final response = await _apiService.uploadProfilePicture(
          pickedFile.path,
        );

        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (response['success'] == true) {
          // Update local user data with new profile picture URL
          if (response['data'] != null) {
            await _storageService.saveUserData(response['data']);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully'),
              backgroundColor: AppColors.successGreenPrimary,
            ),
          );
          await _loadUserData(); // Reload user data
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Failed to upload profile picture',
              ),
              backgroundColor: AppColors.dangerRedPrimary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppColors.dangerRedPrimary,
          ),
        );
      }
    }
  }

  Future<void> _deleteProfilePicture() async {
    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Supabase-first (Django fallback while migrating).
      if (SupabaseConfig.isConfigured) {
        try {
          final auth = SupabaseAuthService();
          final uid = auth.currentUser?.id;
          if (uid == null) throw Exception('Not authenticated');
          await SupabaseStorageService().removeProfilePictures(uid);
          await auth.updateProfile({'profile_picture_url': null});
          if (!mounted) return;
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture deleted successfully'),
              backgroundColor: AppColors.successGreenPrimary,
            ),
          );
          await _loadUserData(); // Reload user data
        } catch (e) {
          if (!mounted) return;
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete profile picture: $e'),
              backgroundColor: AppColors.dangerRedPrimary,
            ),
          );
        }
        return;
      }

      // Call API to delete profile picture
      final response = await _apiService.deleteProfilePicture();

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture deleted successfully'),
            backgroundColor: AppColors.successGreenPrimary,
          ),
        );
        await _loadUserData(); // Reload user data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Failed to delete profile picture',
            ),
            backgroundColor: AppColors.dangerRedPrimary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting image: $e'),
            backgroundColor: AppColors.dangerRedPrimary,
          ),
        );
      }
    }
  }

  // Show full-screen profile picture viewer (WhatsApp style)
  void _showFullScreenImage() {
    final imageUrl = _getProfilePictureUrl();
    if (imageUrl == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _getFullName(),
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showProfilePictureOptions();
                },
                tooltip: 'Change photo',
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.primaryPurpleDeep,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editBio() async {
    final currentBio = _userData['bio']?.toString() ?? '';
    final controller = TextEditingController(text: currentBio);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Bio'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Tell us about yourself...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurpleDeep,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Supabase-first (Django fallback while migrating).
      if (SupabaseConfig.isConfigured) {
        try {
          await SupabaseAuthService().updateProfile({'bio': result});
          if (!mounted) return;
          Navigator.pop(context); // Close loading dialog
          setState(() {
            _userData['bio'] = result;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bio updated successfully'),
              backgroundColor: AppColors.successGreenPrimary,
            ),
          );
        } catch (e) {
          if (!mounted) return;
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update bio: $e'),
              backgroundColor: AppColors.dangerRedPrimary,
            ),
          );
        }
        return;
      }

      // Call API to update bio
      final response = await _apiService.updateBio(result);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (response['success'] == true) {
        setState(() {
          _userData['bio'] = result;
        });

        // Update local storage
        if (response['data'] != null) {
          await _storageService.saveUserData(response['data']);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bio updated successfully'),
            backgroundColor: AppColors.successGreenPrimary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to update bio'),
            backgroundColor: AppColors.dangerRedPrimary,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == '-') {
      return '-';
    }
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
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
            onPressed: () async {
              // Navigate to edit profile screen
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(userData: _userData),
                ),
              );

              // If changes were saved, reload user data
              if (result == true) {
                await _loadUserData();
              }
            },
            icon: const Icon(Icons.edit),
            color: AppColors.primaryPurpleDeep,
            tooltip: 'Edit Profile',
          ),
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
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _getProfilePictureUrl() != null
                          ? () => _showFullScreenImage()
                          : _showProfilePictureOptions,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _userData['profile_picture'] == null
                              ? const LinearGradient(
                                  colors: [
                                    AppColors.primaryPurpleDeep,
                                    AppColors.primaryPurpleLight,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          image: _getProfilePictureUrl() != null
                              ? DecorationImage(
                                  image: NetworkImage(_getProfilePictureUrl()!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _userData['profile_picture'] == null
                            ? Center(
                                child: Text(
                                  _getInitials(),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showProfilePictureOptions,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurpleDeep,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // User Name and Email
              Center(
                child: Column(
                  children: [
                    Text(
                      _getFullName(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutralTextPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userData['email']?.toString() ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (_userData['role_display'] != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurpleDeep.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _userData['role_display']?.toString() ?? '',
                          style: const TextStyle(
                            color: AppColors.primaryPurpleDeep,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
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
                    'Middle Name',
                    _userData['middle_name']?.toString() ?? '-',
                  ),
                  _buildInfoRow(
                    'Last Name',
                    _userData['last_name']?.toString() ?? '-',
                  ),
                  _buildInfoRow(
                    'Gender',
                    _userData['gender']?.toString() ?? '-',
                  ),
                  _buildInfoRow(
                    'Date of Birth',
                    _formatDate(_userData['date_of_birth']?.toString()),
                  ),
                  _buildInfoRow(
                    'Marital Status',
                    _userData['marital_status']?.toString() ?? '-',
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
                    'Residence',
                    _userData['residence']?.toString() ?? '-',
                  ),
                  _buildInfoRow(
                    'Street',
                    _userData['street']?.toString() ?? '-',
                  ),
                  _buildInfoRow(
                    'House Number',
                    _userData['house_number']?.toString() ?? '-',
                  ),
                  _buildInfoRow(
                    'Postal Address',
                    _userData['postal_address']?.toString() ?? '-',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Contact Information Card
              _buildSectionCard(
                title: 'Contact Information',
                icon: Icons.contact_phone_outlined,
                gradient: [Colors.purple[700]!, Colors.purple[400]!],
                children: [
                  _buildInfoRow(
                    'Phone Number',
                    _userData['phone_number']?.toString() ?? '-',
                  ),
                  _buildInfoRow(
                    'Email Address',
                    _userData['email']?.toString() ?? '-',
                  ),
                  _buildInfoRow(
                    'Postal Address',
                    _userData['postal_address']?.toString() ?? '-',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Bio Card (moved to last position)
              _buildSectionCard(
                title: 'Bio',
                icon: Icons.info_outline,
                gradient: [Colors.orange[700]!, Colors.orange[400]!],
                trailing: IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: _editBio,
                  color: Colors.white,
                ),
                children: [
                  Text(
                    _userData['bio']?.toString().isNotEmpty == true
                        ? _userData['bio'].toString()
                        : 'No bio added yet. Tap the edit button to add your bio.',
                    style: TextStyle(
                      fontSize: 14,
                      color: _userData['bio']?.toString().isNotEmpty == true
                          ? AppColors.neutralTextPrimary
                          : Colors.grey[500],
                      fontStyle: _userData['bio']?.toString().isNotEmpty == true
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
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
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
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
                fontSize: 14,
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
                color: AppColors.neutralTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
