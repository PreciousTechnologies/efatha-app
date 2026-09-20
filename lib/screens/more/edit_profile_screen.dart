import 'package:flutter/material.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/supabase_auth_service.dart';

/// Edit Profile Screen - Allows user to edit all their information
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Controllers for text fields
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _countryController;
  late TextEditingController _regionController;
  late TextEditingController _cityController;
  late TextEditingController _residenceController;
  late TextEditingController _streetController;
  late TextEditingController _houseNumberController;
  late TextEditingController _postalAddressController;
  late TextEditingController _churchPositionController;
  late TextEditingController _serviceRegionController;
  late TextEditingController _bioController;

  String? _selectedGender;
  String? _selectedMaritalStatus;
  String? _selectedCountry;
  String? _selectedChurchPosition;
  String? _selectedServiceRegion;

  bool _isLoading = false;
  bool _hasChanges = false;

  // Dropdown options from onboarding screen
  final List<String> _genderOptions = ['Male', 'Female'];

  final List<String> _maritalStatusOptions = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
  ];

  final List<String> _churchPositions = [
    "Mtume Mkuu",
    "Msaidizi Binafsi wa Mtume Mkuu",
    "Mtume",
    "Mchungaji Kiongozi",
    "Mchungaji",
    "Katibu",
    "Mtawala",
    "Askofu",
    "Cell Leader",
    "Mweka Hazina",
    "Mwanakamati",
    "Mjumbe wa Board",
    "Funguka",
    "ICT",
    "TV",
    "Sunday School Teacher",
    "Walinzi",
    "Muumini",
  ];

  final List<String> _countries = [
    "Tanzania",
    "Kenya",
    "Malawi",
    "Zambia",
    "Rwanda",
    "Burundi",
    "Republic of Congo",
    "Mozambique",
    "Botswana",
    "South Africa",
    "South Sudan",
    "UK",
    "USA",
    "Pakistan",
    "India",
  ];

  final List<String> _tanzaniaRegions = [
    "Arusha",
    "Dar es Salaam",
    "Dodoma",
    "Geita",
    "Iringa",
    "Kagera",
    "Katavi",
    "Kigoma",
    "Kilimanjaro",
    "Lindi",
    "Manyara",
    "Mara",
    "Mbeya",
    "Morogoro",
    "Mtwara",
    "Mwanza",
    "Njombe",
    "Pemba Kaskazini",
    "Pemba Kusini",
    "Pwani",
    "Rukwa",
    "Ruvuma",
    "Shinyanga",
    "Simiyu",
    "Singida",
    "Songwe",
    "Tabora",
    "Tanga",
    "Unguja Kaskazini",
    "Unguja Kusini",
  ];

  final List<String> _mikoa = [
    "Mwenge",
    "Ushindi",
    "Temeke",
    "Kinondoni",
    "Imara",
    "Yombo",
    "Kisukuru",
    "Zanzibar",
  ];

  // Service Regions (Countries + Tanzania regions except Dar + Mikoa)
  List<String> get _serviceRegions {
    List<String> regions = [];
    regions.addAll(_countries);
    regions.addAll(_tanzaniaRegions.where((r) => r != "Dar es Salaam"));
    regions.addAll(_mikoa);
    return regions;
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController(
      text: widget.userData['first_name']?.toString() ?? '',
    );
    _middleNameController = TextEditingController(
      text: widget.userData['middle_name']?.toString() ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.userData['last_name']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: widget.userData['email']?.toString() ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.userData['phone_number']?.toString() ?? '',
    );
    _dateOfBirthController = TextEditingController(
      text: widget.userData['date_of_birth']?.toString() ?? '',
    );
    _countryController = TextEditingController(
      text: widget.userData['country']?.toString() ?? '',
    );
    _regionController = TextEditingController(
      text: widget.userData['region']?.toString() ?? '',
    );
    _cityController = TextEditingController(
      text: widget.userData['city']?.toString() ?? '',
    );
    _residenceController = TextEditingController(
      text: widget.userData['residence']?.toString() ?? '',
    );
    _streetController = TextEditingController(
      text: widget.userData['street']?.toString() ?? '',
    );
    _houseNumberController = TextEditingController(
      text: widget.userData['house_number']?.toString() ?? '',
    );
    _postalAddressController = TextEditingController(
      text: widget.userData['postal_address']?.toString() ?? '',
    );
    _churchPositionController = TextEditingController(
      text: widget.userData['church_position']?.toString() ?? '',
    );
    _serviceRegionController = TextEditingController(
      text: widget.userData['service_region']?.toString() ?? '',
    );
    _bioController = TextEditingController(
      text: widget.userData['bio']?.toString() ?? '',
    );

    _selectedGender = widget.userData['gender']?.toString();
    _selectedMaritalStatus = widget.userData['marital_status']?.toString();
    _selectedCountry = widget.userData['country']?.toString();
    _selectedChurchPosition = widget.userData['church_position']?.toString();
    _selectedServiceRegion = widget.userData['service_region']?.toString();

    // Add listeners to detect changes
    _addChangeListeners();
  }

  void _addChangeListeners() {
    final controllers = [
      _firstNameController,
      _middleNameController,
      _lastNameController,
      _emailController,
      _phoneController,
      _dateOfBirthController,
      _countryController,
      _regionController,
      _cityController,
      _residenceController,
      _streetController,
      _houseNumberController,
      _postalAddressController,
      _churchPositionController,
      _serviceRegionController,
      _bioController,
    ];

    for (var controller in controllers) {
      controller.addListener(() {
        if (!_hasChanges) {
          setState(() => _hasChanges = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _countryController.dispose();
    _regionController.dispose();
    _cityController.dispose();
    _residenceController.dispose();
    _streetController.dispose();
    _houseNumberController.dispose();
    _postalAddressController.dispose();
    _churchPositionController.dispose();
    _serviceRegionController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirthController.text.isNotEmpty
          ? DateTime.tryParse(_dateOfBirthController.text) ?? DateTime(2000)
          : DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryPurpleDeep,
              onPrimary: Colors.white,
              onSurface: AppColors.neutralTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateOfBirthController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes to save'),
          backgroundColor: AppColors.warningAmber,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare data for API
      final profileData = {
        'first_name': _firstNameController.text.trim(),
        'middle_name': _middleNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'date_of_birth': _dateOfBirthController.text.trim(),
        'gender': _selectedGender,
        'marital_status': _selectedMaritalStatus,
        'country': _selectedCountry ?? _countryController.text.trim(),
        'region': _regionController.text.trim(),
        'city': _cityController.text.trim(),
        'residence': _residenceController.text.trim(),
        'street': _streetController.text.trim(),
        'house_number': _houseNumberController.text.trim(),
        'postal_address': _postalAddressController.text.trim(),
        'church_position':
            _selectedChurchPosition ?? _churchPositionController.text.trim(),
        'service_region':
            _selectedServiceRegion ?? _serviceRegionController.text.trim(),
        'bio': _bioController.text.trim(),
      };

      // Remove empty values
      profileData.removeWhere((key, value) => value == null || value == '');

      // Supabase-first (Django fallback while migrating).
      // NOTE: this updates the profile row; the Auth sign-in email is
      // unchanged (Supabase requires a separate confirmation flow).
      if (SupabaseConfig.isConfigured) {
        try {
          await SupabaseAuthService().updateProfile(
            Map<String, dynamic>.from(profileData),
          );
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully! ✅'),
              backgroundColor: AppColors.successGreenPrimary,
              duration: Duration(seconds: 2),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;
          Navigator.pop(context, true);
        } catch (e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: $e'),
              backgroundColor: AppColors.dangerRedPrimary,
            ),
          );
        }
        return;
      }

      final response = await _apiService.updateProfile(profileData);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully! ✅'),
            backgroundColor: AppColors.successGreenPrimary,
            duration: Duration(seconds: 2),
          ),
        );

        // Wait a moment then go back
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pop(
          context,
          true,
        ); // Return true to indicate changes were saved
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to update profile'),
            backgroundColor: AppColors.dangerRedPrimary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.dangerRedPrimary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.neutralTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.neutralTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPurpleDeep,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information
              _buildSectionHeader('Personal Information', Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _firstNameController,
                label: 'First Name',
                icon: Icons.person,
                required: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _middleNameController,
                label: 'Middle Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _lastNameController,
                label: 'Last Name',
                icon: Icons.person,
                required: true,
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Gender',
                icon: Icons.wc,
                value: _selectedGender,
                items: _genderOptions,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                    _hasChanges = true;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildDateField(
                controller: _dateOfBirthController,
                label: 'Date of Birth',
                icon: Icons.calendar_today,
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Marital Status',
                icon: Icons.favorite_border,
                value: _selectedMaritalStatus,
                items: _maritalStatusOptions,
                onChanged: (value) {
                  setState(() {
                    _selectedMaritalStatus = value;
                    _hasChanges = true;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Contact Information
              _buildSectionHeader('Contact Information', Icons.contact_phone),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                required: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _postalAddressController,
                label: 'Postal Address',
                icon: Icons.markunread_mailbox,
              ),
              const SizedBox(height: 32),

              // Location Information
              _buildSectionHeader('Location Information', Icons.location_on),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Country',
                icon: Icons.flag,
                value: _selectedCountry,
                items: _countries,
                onChanged: (value) {
                  setState(() {
                    _selectedCountry = value;
                    _hasChanges = true;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _regionController,
                label: 'Region',
                icon: Icons.map,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _cityController,
                label: 'City',
                icon: Icons.location_city,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _residenceController,
                label: 'Residence',
                icon: Icons.home,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _streetController,
                label: 'Street',
                icon: Icons.add_road,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _houseNumberController,
                label: 'House Number',
                icon: Icons.home_outlined,
              ),
              const SizedBox(height: 32),

              // Church Information
              _buildSectionHeader('Church Information', Icons.church),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Church Position',
                icon: Icons.work_outline,
                value: _selectedChurchPosition,
                items: _churchPositions,
                onChanged: (value) {
                  setState(() {
                    _selectedChurchPosition = value;
                    _hasChanges = true;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Service Region',
                icon: Icons.location_on_outlined,
                value: _selectedServiceRegion,
                items: _serviceRegions,
                onChanged: (value) {
                  setState(() {
                    _selectedServiceRegion = value;
                    _hasChanges = true;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Bio (moved to last)
              _buildSectionHeader('Bio', Icons.info_outline),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bioController,
                label: 'Bio',
                icon: Icons.notes,
                maxLines: 5,
                maxLength: 500,
                hint: 'Tell us about yourself...',
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurpleDeep,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryPurpleDeep.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryPurpleDeep, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool required = false,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primaryPurpleDeep),
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
          borderSide: const BorderSide(
            color: AppColors.primaryPurpleDeep,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dangerRedPrimary),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.dangerRedPrimary,
            width: 2,
          ),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryPurpleDeep),
        suffixIcon: const Icon(Icons.calendar_today, size: 20),
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
          borderSide: const BorderSide(
            color: AppColors.primaryPurpleDeep,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryPurpleDeep),
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
          borderSide: const BorderSide(
            color: AppColors.primaryPurpleDeep,
            width: 2,
          ),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
