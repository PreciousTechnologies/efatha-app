import 'package:flutter/material.dart';
import '../../models/believer_model.dart';

/// Controller to manage onboarding flow state
class OnboardingController extends ChangeNotifier {
  int _currentPage = 0;
  final PageController pageController = PageController();

  // Temporary storage for form data
  final Map<String, dynamic> _formData = {};

  int get currentPage => _currentPage;
  Map<String, dynamic> get formData => _formData;

  // Page validation flags
  final Map<int, bool> _pageValidation = {
    0: false, // Personal Info
    1: false, // Location Info
    2: false, // Contact Info
    3: false, // Church Details
  };

  /// Update current page
  void setPage(int page) {
    _currentPage = page;
    // Guard: controller may be used without an attached PageView
    // (e.g. unit tests, or calls during disposal).
    if (pageController.hasClients) {
      pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    notifyListeners();
  }

  /// Go to next page
  void nextPage() {
    if (_currentPage < 4) {
      setPage(_currentPage + 1);
    }
  }

  /// Go to previous page
  void previousPage() {
    if (_currentPage > 0) {
      setPage(_currentPage - 1);
    }
  }

  /// Update form data
  void updateFormData(String key, dynamic value) {
    _formData[key] = value;
    _validateCurrentPage();
    notifyListeners();
  }

  /// Update multiple form fields at once
  void updateMultipleFields(Map<String, dynamic> data) {
    _formData.addAll(data);
    _validateCurrentPage();
    notifyListeners();
  }

  /// Validate current page
  void _validateCurrentPage() {
    switch (_currentPage) {
      case 0: // Personal Info
        _pageValidation[0] = _validatePersonalInfo();
        break;
      case 1: // Location Info
        _pageValidation[1] = _validateLocationInfo();
        break;
      case 2: // Contact Info
        _pageValidation[2] = _validateContactInfo();
        break;
      case 3: // Church Details
        _pageValidation[3] = _validateChurchDetails();
        break;
    }
  }

  bool _validatePersonalInfo() {
    return _formData['firstName']?.isNotEmpty == true &&
        _formData['lastName']?.isNotEmpty == true &&
        _formData['gender']?.isNotEmpty == true &&
        _formData['birthDate'] != null;
  }

  bool _validateLocationInfo() {
    // Country is always required
    final hasCountry = _formData['countryName']?.isNotEmpty == true;

    // For Tanzania, region and district are required
    if (_formData['countryName'] == 'Tanzania') {
      return hasCountry &&
          _formData['regionName']?.isNotEmpty == true &&
          _formData['districtName']?.isNotEmpty == true &&
          _formData['residence']?.isNotEmpty == true;
    }

    // For other countries, only country and residence are required
    return hasCountry && _formData['residence']?.isNotEmpty == true;
  }

  bool _validateContactInfo() {
    final phone = _formData['phone'] as String?;
    final email = _formData['email'] as String?;
    final password = _formData['password'] as String?;
    final confirmPassword = _formData['confirmPassword'] as String?;

    return phone?.isNotEmpty == true &&
        email?.isNotEmpty == true &&
        _isValidEmail(email ?? '') &&
        (password?.length ?? 0) >= 6 &&
        password == confirmPassword;
  }

  bool _validateChurchDetails() {
    return _formData['churchPosition']?.isNotEmpty == true &&
        _formData['serviceRegion']?.isNotEmpty == true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Check if current page is valid
  bool get isCurrentPageValid => _pageValidation[_currentPage] ?? false;

  /// Check if all pages are valid
  bool get isAllPagesValid => _pageValidation.values.every((valid) => valid);

  /// Get progress percentage
  double get progress => (_currentPage + 1) / 5;

  /// Convert form data to BelieverModel
  BelieverModel toBelieverModel() {
    return BelieverModel(
      firstName: _formData['firstName'] ?? '',
      middleName: _formData['middleName'] ?? '',
      lastName: _formData['lastName'] ?? '',
      gender: _formData['gender'] ?? '',
      birthDate: _formData['birthDate'] ?? DateTime.now(),
      countryId: _formData['countryId'],
      countryName: _formData['countryName'],
      regionId: _formData['regionId'],
      regionName: _formData['regionName'],
      districtId: _formData['districtId'],
      districtName: _formData['districtName'],
      birthPlace: _formData['birthPlace'] ?? '',
      residence: _formData['residence'] ?? '',
      street: _formData['street'] ?? '',
      houseNumber: _formData['houseNumber'] ?? '',
      postalAddress: _formData['postalAddress'] ?? '',
      phone: _formData['phone'] ?? '',
      email: _formData['email'] ?? '',
      marriageStatus: _formData['marriageStatus'],
      serviceRegionId: _formData['serviceRegionId'],
      serviceRegionName: _formData['serviceRegion'],
      centreId: _formData['centreId'],
      centreName: _formData['centreName'],
      areaId: _formData['areaId'],
      areaName: _formData['areaName'],
      zoneId: _formData['zoneId'],
      zoneName: _formData['zoneName'],
      cellId: _formData['cellId'],
      cellName: _formData['cellName'],
      churchPosition: _formData['churchPosition'] ?? '',
      registrationNumber: _formData['registrationNumber'],
      registrationDate: DateTime.now(),
    );
  }

  /// Reset controller
  void reset() {
    _currentPage = 0;
    _formData.clear();
    _pageValidation.updateAll((key, value) => false);
    if (pageController.hasClients) {
      pageController.jumpToPage(0);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
