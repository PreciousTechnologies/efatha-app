import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_dropdown.dart';
import '../../../core/theme/app_colors.dart';
import '../onboarding_controller.dart';

/// Page 1: Personal Information
class PersonalInfoPage extends StatefulWidget {
  final OnboardingController controller;

  const PersonalInfoPage({super.key, required this.controller});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  DateTime? _selectedDate;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.controller.formData['birthDate'];
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        widget.controller.updateFormData('profileImage', pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _showImageSourceDialog() {
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
                'Select Profile Picture',
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
                  _pickImage(ImageSource.camera);
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
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_profileImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _profileImage = null;
                    });
                    widget.controller.updateFormData('profileImage', null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryPurpleDeep,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.neutralTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      widget.controller.updateFormData('birthDate', picked);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page icon and title
            Center(
              child: Column(
                children: [
                  // Profile Picture
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _profileImage == null
                                ? const LinearGradient(
                                    colors: [
                                      AppColors.primaryPurpleDeep,
                                      AppColors.primaryPurpleLight,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            image: _profileImage != null
                                ? DecorationImage(
                                    image: FileImage(_profileImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _profileImage == null
                              ? const Icon(
                                  Icons.person_outline_rounded,
                                  size: 60,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _profileImage == null
                        ? 'Add Profile Picture'
                        : 'Change Picture',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryPurpleDeep,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.neutralTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tell us about yourself so we can get to know you better',
              style: TextStyle(fontSize: 14, color: AppColors.neutralTextMuted),
            ),
            const SizedBox(height: 32),

            // First Name
            CustomTextField(
              label: 'First Name',
              isRequired: true,
              prefixIcon: Icons.person,
              initialValue: widget.controller.formData['firstName'],
              onChanged: (value) {
                widget.controller.updateFormData('firstName', value);
              },
            ),
            const SizedBox(height: 20),

            // Middle Name
            CustomTextField(
              label: 'Middle Name',
              prefixIcon: Icons.person_outline,
              initialValue: widget.controller.formData['middleName'],
              onChanged: (value) {
                widget.controller.updateFormData('middleName', value);
              },
            ),
            const SizedBox(height: 20),

            // Last Name
            CustomTextField(
              label: 'Last Name',
              isRequired: true,
              prefixIcon: Icons.person,
              initialValue: widget.controller.formData['lastName'],
              onChanged: (value) {
                widget.controller.updateFormData('lastName', value);
              },
            ),
            const SizedBox(height: 20),

            // Gender
            CustomDropdown<String>(
              label: 'Gender',
              isRequired: true,
              prefixIcon: Icons.wc,
              value: widget.controller.formData['gender'],
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
              ],
              onChanged: (value) {
                widget.controller.updateFormData('gender', value);
              },
            ),
            const SizedBox(height: 20),

            // Birth Date
            CustomTextField(
              label: 'Birth Date',
              isRequired: true,
              prefixIcon: Icons.calendar_today,
              readOnly: true,
              initialValue: _formatDate(_selectedDate),
              onTap: _selectDate,
              suffixIcon: IconButton(
                icon: const Icon(Icons.edit_calendar, size: 20),
                onPressed: _selectDate,
                color: AppColors.primaryPurpleDeep,
              ),
            ),
            const SizedBox(height: 20),

            // Marital Status (Optional)
            CustomDropdown<String>(
              label: 'Marital Status',
              prefixIcon: Icons.favorite_outline,
              value: widget.controller.formData['marriageStatus'],
              items: const [
                DropdownMenuItem(value: 'Single', child: Text('Single')),
                DropdownMenuItem(value: 'Married', child: Text('Married')),
                DropdownMenuItem(value: 'Divorced', child: Text('Divorced')),
                DropdownMenuItem(value: 'Widowed', child: Text('Widowed')),
              ],
              onChanged: (value) {
                widget.controller.updateFormData('marriageStatus', value);
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
