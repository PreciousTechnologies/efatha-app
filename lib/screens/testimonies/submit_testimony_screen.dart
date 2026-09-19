import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/config/api_config.dart';
import '../../core/services/storage_service.dart';

/// Submit Testimony Screen - Create new testimony with photo/video upload
class SubmitTestimonyScreen extends StatefulWidget {
  final int? prayerRequestId;
  final String? prayerRequestTitle;
  final Map<String, dynamic>? testimonyData; // For editing

  const SubmitTestimonyScreen({
    super.key,
    this.prayerRequestId,
    this.prayerRequestTitle,
    this.testimonyData,
  });

  @override
  State<SubmitTestimonyScreen> createState() => _SubmitTestimonyScreenState();
}

class _SubmitTestimonyScreenState extends State<SubmitTestimonyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final StorageService _storage = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedCategory = 'other';
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  bool _isSundayService = false;
  String? _userRole;
  XFile? _selectedPhoto;
  XFile? _selectedThumbnail;
  PlatformFile? _selectedVideo;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Healing', 'value': 'healing', 'icon': Icons.healing},
    {
      'label': 'Financial Breakthrough',
      'value': 'financial',
      'icon': Icons.attach_money,
    },
    {
      'label': 'Family Restoration',
      'value': 'family',
      'icon': Icons.family_restroom,
    },
    {'label': 'Salvation', 'value': 'salvation', 'icon': Icons.church},
    {'label': 'Deliverance', 'value': 'deliverance', 'icon': Icons.shield},
    {'label': 'Career/Job', 'value': 'career', 'icon': Icons.work},
    {
      'label': 'Answered Prayer',
      'value': 'answered_prayer',
      'icon': Icons.check_circle,
    },
    {'label': 'Other', 'value': 'other', 'icon': Icons.more_horiz},
  ];

  bool get isEditing => widget.testimonyData != null;
  bool get canCreateSundayService =>
      _userRole == 'admin' || _userRole == 'editor';
  bool get isLinkedToPrayer => widget.prayerRequestId != null;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    if (isEditing) {
      _loadExistingData();
    }
  }

  Future<void> _loadUserRole() async {
    final role = await _storage.getUserRole();
    setState(() {
      _userRole = role;
    });
  }

  void _loadExistingData() {
    final data = widget.testimonyData!;
    _titleController.text = data['title'] ?? '';
    _contentController.text = data['content'] ?? '';
    _selectedCategory = data['category'] ?? 'other';
    _isAnonymous = data['is_anonymous'] ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedPhoto = photo;
        });
      }
    } catch (e) {
      _showError('Error picking photo: ${e.toString()}');
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final XFile? thumbnail = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 720,
        imageQuality: 90,
      );

      if (thumbnail != null) {
        setState(() {
          _selectedThumbnail = thumbnail;
        });
      }
    } catch (e) {
      _showError('Error picking thumbnail: ${e.toString()}');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Check file size (max 100MB)
        if (file.size > 100 * 1024 * 1024) {
          _showError('Video file is too large. Maximum size is 100MB.');
          return;
        }

        setState(() {
          _selectedVideo = file;
        });
      }
    } catch (e) {
      _showError('Error picking video: ${e.toString()}');
    }
  }

  Future<void> _submitTestimony() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate Sunday Service requirements
    if (_isSundayService) {
      if (_selectedVideo == null) {
        _showError('Sunday Service testimonies require a video');
        return;
      }
      if (_selectedThumbnail == null) {
        _showError('Sunday Service testimonies require a thumbnail');
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        _showError('Please log in again');
        setState(() => _isSubmitting = false);
        return;
      }

      // Create multipart request
      final uri = isEditing
          ? Uri.parse('${ApiConfig.testimonies}${widget.testimonyData!['id']}/')
          : Uri.parse(ApiConfig.testimonies);

      final request = http.MultipartRequest(isEditing ? 'PUT' : 'POST', uri);

      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      request.fields['title'] = _titleController.text;
      request.fields['content'] = _contentController.text;
      request.fields['category'] = _selectedCategory;
      request.fields['is_anonymous'] = _isAnonymous.toString();
      request.fields['testimony_type'] = _isSundayService
          ? 'sunday_service'
          : 'regular';

      // Add prayer request link if provided
      if (isLinkedToPrayer) {
        request.fields['prayer_request'] = widget.prayerRequestId.toString();
      }

      // Add photo if selected
      if (_selectedPhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', _selectedPhoto!.path),
        );
      }

      // Add thumbnail if selected (for Sunday Service)
      if (_selectedThumbnail != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'thumbnail',
            _selectedThumbnail!.path,
          ),
        );
      }

      // Add video if selected
      if (_selectedVideo != null && _selectedVideo!.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath('video', _selectedVideo!.path!),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      setState(() => _isSubmitting = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccess(
          isEditing
              ? 'Testimony updated successfully!'
              : 'Testimony submitted successfully! It will be visible after approval.',
        );

        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        _showError('Failed to submit testimony: ${response.body}');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showError('Error: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Testimony' : 'Share Your Testimony',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitTestimony,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isEditing ? 'Update' : 'Submit',
                    style: TextStyle(
                      color: AppColors.primaryPurpleDeep,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Prayer Link Banner (if linked to prayer)
              if (isLinkedToPrayer) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryPurpleLight.withValues(alpha: 0.2),
                        AppColors.primaryPurpleVibrant.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryPurpleLight,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurpleDeep,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.link,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Linked to Prayer Request',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.prayerRequestTitle ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.primaryPurpleDeep,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Title
              Text(
                'Title',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Give your testimony a title',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primaryPurpleDeep,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Category Selection
              Text(
                'Category',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category['value'];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category['value'];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  AppColors.primaryPurpleDeep,
                                  AppColors.primaryPurpleVibrant,
                                ],
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category['icon'],
                            size: 18,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category['label'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Sunday Service Toggle (Admin/Editor Only)
              if (canCreateSundayService)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isSundayService
                          ? AppColors.primaryPurpleDeep
                          : Colors.grey[300]!,
                      width: _isSundayService ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryPurpleDeep,
                              AppColors.primaryPurpleVibrant,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.church,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sunday Service Testimony',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Requires video and thumbnail',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isSundayService,
                        onChanged: (value) {
                          setState(() {
                            _isSundayService = value;
                          });
                        },
                        activeThumbColor: AppColors.primaryPurpleDeep,
                      ),
                    ],
                  ),
                ),

              // Thumbnail Upload (Sunday Service Only)
              if (_isSundayService) ...[
                Text(
                  'Thumbnail *',
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 12),
                _buildMediaCard(
                  icon: Icons.image,
                  title: 'Add Thumbnail',
                  subtitle: _selectedThumbnail != null
                      ? 'Thumbnail selected'
                      : 'Required for Sunday Service (16:9 recommended)',
                  onTap: _pickThumbnail,
                  isSelected: _selectedThumbnail != null,
                  onRemove: _selectedThumbnail != null
                      ? () => setState(() => _selectedThumbnail = null)
                      : null,
                ),
                const SizedBox(height: 24),
              ],

              // Content
              Text(
                'Your Testimony',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  hintText: 'Share what God has done in your life...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primaryPurpleDeep,
                      width: 2,
                    ),
                  ),
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please share your testimony';
                  }
                  if (value.trim().length < 20) {
                    return 'Testimony must be at least 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Media Upload Section
              Text(
                'Media (Optional)',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 12),

              // Photo Upload
              _buildMediaCard(
                icon: Icons.photo_library,
                title: 'Add Photo',
                subtitle: _selectedPhoto != null
                    ? 'Photo selected'
                    : 'Support your testimony with a photo',
                onTap: _pickPhoto,
                isSelected: _selectedPhoto != null,
                onRemove: _selectedPhoto != null
                    ? () => setState(() => _selectedPhoto = null)
                    : null,
              ),
              const SizedBox(height: 12),

              // Video Upload
              _buildMediaCard(
                icon: Icons.videocam,
                title: 'Add Video',
                subtitle: _selectedVideo != null
                    ? 'Video selected (${(_selectedVideo!.size / (1024 * 1024)).toStringAsFixed(1)} MB)'
                    : 'Share your testimony in video (Max 100MB)',
                onTap: _pickVideo,
                isSelected: _selectedVideo != null,
                onRemove: _selectedVideo != null
                    ? () => setState(() => _selectedVideo = null)
                    : null,
              ),
              const SizedBox(height: 24),

              // Anonymous Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_off,
                      color: AppColors.primaryPurpleDeep,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Submit Anonymously',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Your name will not be shown',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAnonymous,
                      onChanged: (value) {
                        setState(() => _isAnonymous = value);
                      },
                      activeThumbColor: AppColors.primaryPurpleDeep,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your testimony will be reviewed before being published to ensure it\'s appropriate and encouraging.',
                        style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isSelected,
    VoidCallback? onRemove,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurpleDeep : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppColors.primaryPurpleDeep,
                          AppColors.primaryPurpleVibrant,
                        ],
                      )
                    : null,
                color: isSelected ? null : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected && onRemove != null)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: onRemove,
              )
            else
              Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
