import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/config/api_config.dart';
import '../../core/services/storage_service.dart';

class UploadEventScreen extends StatefulWidget {
  final Map<String, dynamic>? event; // For editing existing event

  const UploadEventScreen({super.key, this.event});

  @override
  State<UploadEventScreen> createState() => _UploadEventScreenState();
}

class _UploadEventScreenState extends State<UploadEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxAttendeesController = TextEditingController();

  File? _coverImage;
  String? _existingCoverUrl;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  DateTime? _registrationDeadline;
  String _selectedCategory = 'other';
  bool _requiresRegistration = false;
  bool _isLoading = false;

  final List<Map<String, String>> _categories = [
    {'value': 'worship', 'label': 'Worship Service'},
    {'value': 'conference', 'label': 'Conference'},
    {'value': 'seminar', 'label': 'Seminar'},
    {'value': 'fellowship', 'label': 'Fellowship'},
    {'value': 'outreach', 'label': 'Outreach'},
    {'value': 'youth', 'label': 'Youth Event'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _loadEventData();
    }
  }

  void _loadEventData() {
    final event = widget.event!;
    _titleController.text = event['title'] ?? '';
    _descriptionController.text = event['description'] ?? '';
    _locationController.text = event['location'] ?? '';
    _selectedCategory = event['category'] ?? 'other';
    _requiresRegistration = event['requires_registration'] ?? false;
    _maxAttendeesController.text = event['max_attendees']?.toString() ?? '';
    _existingCoverUrl = event['banner_image'];

    if (event['start_date'] != null) {
      final startDateTime = DateTime.parse(event['start_date']);
      _startDate = startDateTime;
      _startTime = TimeOfDay.fromDateTime(startDateTime);
    }

    if (event['end_date'] != null) {
      final endDateTime = DateTime.parse(event['end_date']);
      _endDate = endDateTime;
      _endTime = TimeOfDay.fromDateTime(endDateTime);
    }

    if (event['registration_deadline'] != null) {
      _registrationDeadline = DateTime.parse(event['registration_deadline']);
    }
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _coverImage = File(pickedFile.path);
        _existingCoverUrl = null;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _selectRegistrationDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _registrationDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: _startDate ?? DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _registrationDeadline = picked);
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _startTime == null) {
      _showError('Please select start date and time');
      return;
    }

    if (_endDate == null || _endTime == null) {
      _showError('Please select end date and time');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get auth token
      final storageService = StorageService();
      final token = await storageService.getAccessToken();

      if (token == null) {
        _showError('Authentication required. Please log in again.');
        setState(() => _isLoading = false);
        return;
      }

      // Combine date and time
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      final endDateTime = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      // Create multipart request
      final uri = widget.event == null
          ? Uri.parse(ApiConfig.events)
          : Uri.parse('${ApiConfig.events}${widget.event!['id']}/');

      final request = http.MultipartRequest(
        widget.event == null ? 'POST' : 'PUT',
        uri,
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add fields
      request.fields['title'] = _titleController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['location'] = _locationController.text;
      request.fields['start_date'] = startDateTime.toIso8601String();
      request.fields['end_date'] = endDateTime.toIso8601String();
      request.fields['category'] = _selectedCategory;
      request.fields['requires_registration'] = _requiresRegistration
          .toString();
      request.fields['is_published'] = 'true'; // Automatically publish events

      if (_maxAttendeesController.text.isNotEmpty) {
        request.fields['max_attendees'] = _maxAttendeesController.text;
      }

      if (_registrationDeadline != null) {
        request.fields['registration_deadline'] = _registrationDeadline!
            .toIso8601String();
      }

      // Add cover image if selected
      if (_coverImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('banner_image', _coverImage!.path),
        );
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
          _showSuccess(
            widget.event == null
                ? 'Event created successfully!'
                : 'Event updated successfully!',
          );
        }
      } else {
        _showError('Failed to save event: ${response.body}');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;

    return Scaffold(
      backgroundColor: AppColors.neutralBackgroundLightest,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Event' : 'Create New Event'),
        backgroundColor: AppColors.primaryPurpleDeep,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cover Photo Section
            _buildCoverPhotoSection(),
            const SizedBox(height: 24),

            // Title
            _buildTextField(
              controller: _titleController,
              label: 'Event Title',
              hint: 'e.g., Sunday Worship Service',
              icon: Icons.title,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe your event...',
              icon: Icons.description,
              maxLines: 4,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Description is required' : null,
            ),
            const SizedBox(height: 16),

            // Location
            _buildTextField(
              controller: _locationController,
              label: 'Location/Venue',
              hint: 'e.g., Main Church Hall',
              icon: Icons.location_on,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Location is required' : null,
            ),
            const SizedBox(height: 16),

            // Category
            _buildCategoryDropdown(),
            const SizedBox(height: 24),

            // Start Date and Time
            Text(
              'Start Date & Time',
              style: AppTextStyles.bodyMediumWeight.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDateTimeButton(
                    label: _startDate == null
                        ? 'Select Date'
                        : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                    icon: Icons.calendar_today,
                    onTap: _selectStartDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateTimeButton(
                    label: _startTime == null
                        ? 'Select Time'
                        : _startTime!.format(context),
                    icon: Icons.access_time,
                    onTap: _selectStartTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // End Date and Time
            Text(
              'End Date & Time',
              style: AppTextStyles.bodyMediumWeight.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDateTimeButton(
                    label: _endDate == null
                        ? 'Select Date'
                        : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                    icon: Icons.calendar_today,
                    onTap: _selectEndDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateTimeButton(
                    label: _endTime == null
                        ? 'Select Time'
                        : _endTime!.format(context),
                    icon: Icons.access_time,
                    onTap: _selectEndTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Registration Section
            _buildRegistrationSection(),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurpleDeep,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isEditing ? 'Update Event' : 'Create Event',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPhotoSection() {
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Cover Photo',
              style: AppTextStyles.bodyMediumWeight.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_coverImage != null || _existingCoverUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _coverImage != null
                    ? Image.file(_coverImage!, fit: BoxFit.cover)
                    : Image.network(_existingCoverUrl!, fit: BoxFit.cover),
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.neutralBackgroundSoft,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: AppColors.neutralTextMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No cover photo selected',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.neutralTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickCoverImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(
                  _coverImage != null || _existingCoverUrl != null
                      ? 'Change Cover Photo'
                      : 'Upload Cover Photo',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryPurpleDeep,
                  side: BorderSide(color: AppColors.primaryPurpleDeep),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primaryPurpleDeep),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Event Category',
        prefixIcon: Icon(Icons.category, color: AppColors.primaryPurpleDeep),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category['value'],
          child: Text(category['label']!),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCategory = value!),
    );
  }

  Widget _buildDateTimeButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryPurpleDeep),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            'Registration Settings',
            style: AppTextStyles.bodyMediumWeight.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Requires RSVP'),
            subtitle: const Text('Enable registration for this event'),
            value: _requiresRegistration,
            onChanged: (value) => setState(() => _requiresRegistration = value),
            activeColor: AppColors.primaryPurpleDeep,
            contentPadding: EdgeInsets.zero,
          ),
          if (_requiresRegistration) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _maxAttendeesController,
              label: 'Maximum Attendees (Optional)',
              hint: 'e.g., 100',
              icon: Icons.people,
            ),
            const SizedBox(height: 16),
            Text(
              'Registration Deadline',
              style: AppTextStyles.bodyMediumWeight.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildDateTimeButton(
              label: _registrationDeadline == null
                  ? 'Select Deadline (Optional)'
                  : '${_registrationDeadline!.day}/${_registrationDeadline!.month}/${_registrationDeadline!.year}',
              icon: Icons.event_busy,
              onTap: _selectRegistrationDeadline,
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxAttendeesController.dispose();
    super.dispose();
  }
}
