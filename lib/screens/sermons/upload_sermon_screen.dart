import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';

/// Upload/Edit Sermon Screen for Editors
/// Enhanced UI/UX with comprehensive form validation
class UploadSermonScreen extends StatefulWidget {
  final Map<String, dynamic>? sermonData; // For editing existing sermon

  const UploadSermonScreen({super.key, this.sermonData});

  @override
  State<UploadSermonScreen> createState() => _UploadSermonScreenState();
}

class _UploadSermonScreenState extends State<UploadSermonScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controllers
  final _titleController = TextEditingController();
  final _pastorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _topicsController = TextEditingController();
  final _durationController = TextEditingController();

  // Dropdowns
  String? _selectedCategory;
  final List<String> _categories = [
    'Sunday Service',
    'Midweek Service',
    'Youth Service',
    'Special Event',
    'Conference',
    'Revival',
    'Worship Night',
    'Bible Study',
  ];

  // File uploads
  File? _audioFile;
  File? _videoFile;
  File? _thumbnailFile;
  String? _audioFileName;
  String? _videoFileName;
  String? _thumbnailFileName; // ignore: unused_field

  bool _isSubmitting = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    if (widget.sermonData != null) {
      _populateFormData();
    }
  }

  void _populateFormData() {
    final data = widget.sermonData!;
    _titleController.text = data['title'] ?? '';
    _pastorController.text = data['pastor'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _topicsController.text = data['topics'] ?? '';
    _durationController.text = data['duration'] ?? '';
    _selectedCategory = data['category'];
    _thumbnailFileName = data['thumbnail'];
    _audioFileName = data['audio_url'];
    _videoFileName = data['video_url'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pastorController.dispose();
    _descriptionController.dispose();
    _topicsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _audioFile = File(result.files.single.path!);
          _audioFileName = result.files.single.name;
          _hasChanges = true;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking audio file: $e', isError: true);
    }
  }

  Future<void> _pickVideoFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _videoFile = File(result.files.single.path!);
          _videoFileName = result.files.single.name;
          _hasChanges = true;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking video file: $e', isError: true);
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _thumbnailFile = File(image.path);
          _thumbnailFileName = image.name;
          _hasChanges = true;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking thumbnail: $e', isError: true);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields', isError: true);
      return;
    }

    // Validate at least one media file
    if (widget.sermonData == null) {
      if (_audioFile == null && _videoFile == null) {
        _showSnackBar(
          'Please upload at least an audio or video file',
          isError: true,
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final sermonData = {
        'title': _titleController.text.trim(),
        'pastor': _pastorController.text.trim(),
        'description': _descriptionController.text.trim(),
        'topics': _topicsController.text.trim(),
        'category': _selectedCategory,
        'duration': _durationController.text.trim(),
      };

      if (widget.sermonData != null) {
        // Update existing sermon
        await _apiService.updateSermon(
          widget.sermonData!['id'],
          sermonData,
          audioFile: _audioFile,
          videoFile: _videoFile,
          thumbnailFile: _thumbnailFile,
        );
        _showSnackBar('Sermon updated successfully!');
      } else {
        // Create new sermon
        await _apiService.uploadSermon(
          sermonData,
          audioFile: _audioFile,
          videoFile: _videoFile,
          thumbnailFile: _thumbnailFile,
        );
        _showSnackBar('Sermon uploaded successfully!');
      }

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primaryPurpleDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.sermonData != null;

    return Scaffold(
      backgroundColor: AppColors.neutralBackgroundSoft,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppColors.neutralTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Sermon' : 'Upload Sermon',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.neutralTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_hasChanges || !isEditing)
            TextButton(
              onPressed: _isSubmitting ? null : _submitForm,
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          AppColors.primaryPurpleDeep,
                        ),
                      ),
                    )
                  : Text(
                      isEditing ? 'SAVE' : 'UPLOAD',
                      style: AppTextStyles.bodyMediumWeight.copyWith(
                        color: AppColors.primaryPurpleDeep,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() => _hasChanges = true),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Section
              _buildThumbnailSection(),
              const SizedBox(height: 24),

              // Basic Information Section
              _buildSectionHeader('Basic Information', Icons.info_outline),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _titleController,
                label: 'Sermon Title',
                hint: 'E.g., The Power of Faith',
                icon: Icons.title_rounded,
                validator: (val) =>
                    val?.isEmpty ?? true ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _pastorController,
                label: 'Pastor Name',
                hint: 'E.g., Pastor John Smith',
                icon: Icons.person_outline,
                validator: (val) =>
                    val?.isEmpty ?? true ? 'Pastor name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildDropdownField(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _topicsController,
                label: 'Topics (comma separated)',
                hint: 'E.g., Faith, Prayer, Healing',
                icon: Icons.label_outline,
                validator: (val) =>
                    val?.isEmpty ?? true ? 'Topics are required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _durationController,
                label: 'Duration (MM:SS)',
                hint: 'E.g., 45:30',
                icon: Icons.timer_outlined,
                keyboardType: TextInputType.text,
                validator: (val) {
                  if (val?.isEmpty ?? true) return 'Duration is required';
                  final regex = RegExp(r'^\d{1,3}:\d{2}$');
                  if (!regex.hasMatch(val!)) {
                    return 'Format: MM:SS (e.g., 45:30)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Brief description of the sermon...',
                icon: Icons.description_outlined,
                maxLines: 4,
                validator: (val) =>
                    val?.isEmpty ?? true ? 'Description is required' : null,
              ),

              const SizedBox(height: 32),

              // Media Files Section
              _buildSectionHeader('Media Files', Icons.cloud_upload_outlined),
              const SizedBox(height: 16),
              _buildFilePickerCard(
                title: 'Audio File',
                subtitle: _audioFileName ?? 'No audio file selected',
                icon: Icons.audiotrack_rounded,
                onTap: _pickAudioFile,
                hasFile: _audioFile != null || _audioFileName != null,
              ),
              const SizedBox(height: 12),
              _buildFilePickerCard(
                title: 'Video File (Optional)',
                subtitle: _videoFileName ?? 'No video file selected',
                icon: Icons.videocam_rounded,
                onTap: _pickVideoFile,
                hasFile: _videoFile != null || _videoFileName != null,
              ),

              const SizedBox(height: 32),

              // Submit Button
              _buildSubmitButton(isEditing),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurpleVibrant.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.image_outlined,
                  color: AppColors.primaryPurpleDeep,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sermon Thumbnail',
                  style: AppTextStyles.bodyMediumWeight.copyWith(
                    color: AppColors.neutralTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.neutralBackgroundMuted,
                width: 2,
              ),
              gradient: _thumbnailFile == null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryPurpleDeep.withValues(alpha: 0.1),
                        AppColors.primaryPurpleVibrant.withValues(alpha: 0.1),
                      ],
                    )
                  : null,
              image: _thumbnailFile != null
                  ? DecorationImage(
                      image: FileImage(_thumbnailFile!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _pickThumbnail,
                borderRadius: BorderRadius.circular(12),
                child: _thumbnailFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 48,
                            color: AppColors.primaryPurpleDeep,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to add thumbnail',
                            style: AppTextStyles.bodyRegular.copyWith(
                              color: AppColors.neutralTextMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              color: AppColors.primaryPurpleDeep,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryPurpleVibrant.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryPurpleDeep, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.neutralTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurpleVibrant.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: AppTextStyles.bodyRegular.copyWith(
          color: AppColors.neutralTextPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primaryPurpleDeep),
          labelStyle: AppTextStyles.bodyRegular.copyWith(
            color: AppColors.neutralTextMuted,
            fontSize: 14,
          ),
          hintStyle: AppTextStyles.bodyRegular.copyWith(
            color: AppColors.neutralTextPlaceholder,
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.neutralBackgroundMuted,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.primaryPurpleDeep,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurpleVibrant.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedCategory,
        validator: (val) => val == null ? 'Category is required' : null,
        decoration: InputDecoration(
          labelText: 'Category',
          prefixIcon: Icon(
            Icons.category_outlined,
            color: AppColors.primaryPurpleDeep,
          ),
          labelStyle: AppTextStyles.bodyRegular.copyWith(
            color: AppColors.neutralTextMuted,
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.neutralBackgroundMuted,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.primaryPurpleDeep,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.all(20),
        ),
        items: _categories.map((category) {
          return DropdownMenuItem(value: category, child: Text(category));
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCategory = value;
            _hasChanges = true;
          });
        },
      ),
    );
  }

  Widget _buildFilePickerCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool hasFile,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFile
              ? AppColors.primaryPurpleDeep.withValues(alpha: 0.3)
              : AppColors.neutralBackgroundMuted,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurpleVibrant.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasFile
                        ? AppColors.primaryPurpleDeep
                        : AppColors.primaryPurpleVibrant.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: hasFile ? Colors.white : AppColors.primaryPurpleDeep,
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
                        style: AppTextStyles.bodyMediumWeight.copyWith(
                          color: AppColors.neutralTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: hasFile
                              ? AppColors.primaryPurpleDeep
                              : AppColors.neutralTextMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  hasFile ? Icons.check_circle : Icons.upload_file_rounded,
                  color: hasFile
                      ? AppColors.primaryPurpleDeep
                      : AppColors.neutralTextMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isEditing) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurpleDeep,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: AppColors.primaryPurpleVibrant.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: AppColors.neutralBackgroundMuted,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEditing ? Icons.save_rounded : Icons.upload_rounded,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'SAVE CHANGES' : 'UPLOAD SERMON',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
