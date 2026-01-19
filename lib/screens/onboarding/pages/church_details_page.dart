import 'package:flutter/material.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_dropdown.dart';
import '../../../core/theme/app_colors.dart';
import '../onboarding_controller.dart';

/// Page 4: Church Details
class ChurchDetailsPage extends StatefulWidget {
  final OnboardingController controller;

  const ChurchDetailsPage({super.key, required this.controller});

  @override
  State<ChurchDetailsPage> createState() => _ChurchDetailsPageState();
}

class _ChurchDetailsPageState extends State<ChurchDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  // Hardcoded Church Positions
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

  // Hardcoded Countries
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

  // Hardcoded Tanzania Regions
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

  // Hardcoded Mikoa (Dar es Salaam districts)
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
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurpleVibrant.withValues(
                        alpha: 0.2,
                      ),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/efathalogo.jpeg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Church Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.neutralTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect with your church community',
              style: TextStyle(fontSize: 14, color: AppColors.neutralTextMuted),
            ),
            const SizedBox(height: 32),

            // Church Position Dropdown
            CustomDropdown<String>(
              label: 'Church Position',
              isRequired: true,
              prefixIcon: Icons.badge_outlined,
              value: widget.controller.formData['churchPosition'],
              items: _churchPositions.map((position) {
                return DropdownMenuItem<String>(
                  value: position,
                  child: Text(position),
                );
              }).toList(),
              onChanged: (value) {
                widget.controller.updateFormData('churchPosition', value);
              },
            ),
            const SizedBox(height: 20),

            // Service Region Dropdown
            CustomDropdown<String>(
              label: 'Service Region',
              isRequired: true,
              prefixIcon: Icons.location_city,
              value: widget.controller.formData['serviceRegion'],
              items: _serviceRegions.map((region) {
                return DropdownMenuItem<String>(
                  value: region,
                  child: Text(region),
                );
              }).toList(),
              onChanged: (value) {
                widget.controller.updateFormData('serviceRegion', value);
              },
            ),
            const SizedBox(height: 20),

            // Membership Number
            CustomTextField(
              label: 'Membership Number',
              prefixIcon: Icons.person_outline,
              hint: 'Enter your membership number',
              initialValue: widget.controller.formData['membershipNumber'],
              onChanged: (value) {
                widget.controller.updateFormData('membershipNumber', value);
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
