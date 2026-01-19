import 'package:flutter/material.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_dropdown.dart';
import '../../../core/theme/app_colors.dart';
import '../onboarding_controller.dart';

/// Page 2: Location Information
class LocationInfoPage extends StatefulWidget {
  final OnboardingController controller;

  const LocationInfoPage({super.key, required this.controller});

  @override
  State<LocationInfoPage> createState() => _LocationInfoPageState();
}

class _LocationInfoPageState extends State<LocationInfoPage> {
  final _formKey = GlobalKey<FormState>();

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

  // Hardcoded Districts by Region (Tanzania)
  final Map<String, List<String>> _districtsByRegion = {
    "Arusha": [
      "Arusha City",
      "Arusha Rural",
      "Karatu",
      "Longido",
      "Monduli",
      "Ngorongoro",
    ],
    "Dar es Salaam": ["Ilala", "Kinondoni", "Temeke", "Ubungo", "Kigamboni"],
    "Dodoma": [
      "Dodoma Urban",
      "Bahi",
      "Chamwino",
      "Chemba",
      "Kondoa",
      "Kongwa",
      "Mpwapwa",
    ],
    "Geita": [
      "Geita Town",
      "Bukombe",
      "Chato",
      "Geita",
      "Mbogwe",
      "Nyang'hwale",
    ],
    "Iringa": [
      "Iringa Urban",
      "Iringa Rural",
      "Kilolo",
      "Mafinga Town",
      "Mufindi",
    ],
    "Kagera": [
      "Bukoba Urban",
      "Bukoba Rural",
      "Biharamulo",
      "Karagwe",
      "Kyerwa",
      "Missenyi",
      "Muleba",
      "Ngara",
    ],
    "Katavi": ["Mpanda Town", "Mpanda", "Mlele", "Tanganyika"],
    "Kigoma": [
      "Kigoma Urban",
      "Buhigwe",
      "Kakonko",
      "Kasulu Town",
      "Kasulu",
      "Kibondo",
      "Uvinza",
    ],
    "Kilimanjaro": [
      "Moshi Urban",
      "Moshi Rural",
      "Hai",
      "Mwanga",
      "Rombo",
      "Same",
      "Siha",
    ],
    "Lindi": [
      "Lindi Urban",
      "Lindi Rural",
      "Kilwa",
      "Liwale",
      "Nachingwea",
      "Ruangwa",
    ],
    "Manyara": [
      "Babati Town",
      "Babati",
      "Hanang",
      "Kiteto",
      "Mbulu",
      "Simanjiro",
    ],
    "Mara": [
      "Musoma Urban",
      "Musoma Rural",
      "Bunda",
      "Butiama",
      "Rorya",
      "Serengeti",
      "Tarime",
    ],
    "Mbeya": [
      "Mbeya City",
      "Chunya",
      "Kyela",
      "Mbarali",
      "Mbeya Rural",
      "Rungwe",
    ],
    "Morogoro": [
      "Morogoro Urban",
      "Gairo",
      "Kilombero",
      "Kilosa",
      "Morogoro Rural",
      "Mvomero",
      "Ulanga",
      "Malinyi",
    ],
    "Mtwara": [
      "Mtwara Urban",
      "Mtwara Rural",
      "Masasi Town",
      "Masasi",
      "Nanyumbu",
      "Newala",
      "Tandahimba",
    ],
    "Mwanza": [
      "Mwanza City",
      "Ilemela",
      "Nyamagana",
      "Kwimba",
      "Magu",
      "Misungwi",
      "Sengerema",
      "Ukerewe",
    ],
    "Njombe": [
      "Njombe Town",
      "Njombe Rural",
      "Ludewa",
      "Makambako Town",
      "Makete",
      "Wanging'ombe",
    ],
    "Pemba Kaskazini": ["Micheweni", "Wete"],
    "Pemba Kusini": ["Chake Chake", "Mkoani"],
    "Pwani": [
      "Bagamoyo",
      "Kibaha Town",
      "Kibaha",
      "Kisarawe",
      "Mafia",
      "Mkuranga",
      "Rufiji",
    ],
    "Rukwa": ["Sumbawanga Urban", "Kalambo", "Nkasi", "Sumbawanga Rural"],
    "Ruvuma": [
      "Songea Urban",
      "Songea Rural",
      "Mbinga",
      "Namtumbo",
      "Nyasa",
      "Tunduru",
    ],
    "Shinyanga": [
      "Shinyanga Urban",
      "Shinyanga Rural",
      "Kahama Town",
      "Kahama",
      "Kishapu",
      "Msalala",
    ],
    "Simiyu": ["Bariadi", "Busega", "Itilima", "Maswa", "Meatu"],
    "Singida": [
      "Singida Urban",
      "Singida Rural",
      "Ikungi",
      "Iramba",
      "Manyoni",
      "Mkalama",
    ],
    "Songwe": ["Ileje", "Mbozi", "Momba", "Songwe", "Tunduma"],
    "Tabora": [
      "Tabora Urban",
      "Igunga",
      "Kaliua",
      "Nzega Town",
      "Nzega",
      "Sikonge",
      "Urambo",
      "Uyui",
    ],
    "Tanga": [
      "Tanga City",
      "Handeni Town",
      "Handeni",
      "Kilindi",
      "Korogwe Town",
      "Korogwe",
      "Lushoto",
      "Mkinga",
      "Muheza",
      "Pangani",
    ],
    "Unguja Kaskazini": ["Kaskazini A", "Kaskazini B"],
    "Unguja Kusini": ["Kati", "Kusini", "Mjini Magharibi"],
  };

  String? _selectedCountry;
  String? _selectedRegion;
  String? _selectedDistrict;
  List<String>? _availableRegions;
  List<String>? _availableDistricts;

  @override
  void initState() {
    super.initState();
    // Load existing data if available
    _selectedCountry = widget.controller.formData['countryName'];
    _selectedRegion = widget.controller.formData['regionName'];
    _selectedDistrict = widget.controller.formData['districtName'];

    if (_selectedCountry == "Tanzania") {
      _availableRegions = _tanzaniaRegions;
      if (_selectedRegion != null) {
        _availableDistricts = _districtsByRegion[_selectedRegion];
      }
    }
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
                  gradient: const LinearGradient(
                    colors: [AppColors.accentBlueBrand, AppColors.accentTeal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Location Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.neutralTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Where do you call home? Help us know your location',
              style: TextStyle(fontSize: 14, color: AppColors.neutralTextMuted),
            ),
            const SizedBox(height: 32),

            // Country
            CustomDropdown<String>(
              label: 'Country',
              isRequired: true,
              prefixIcon: Icons.public,
              value: _selectedCountry,
              items: _countries.map((country) {
                return DropdownMenuItem<String>(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCountry = value;
                  widget.controller.updateFormData('countryName', value);

                  // If Tanzania selected, show regions. Otherwise, clear regions/districts
                  if (value == "Tanzania") {
                    _availableRegions = _tanzaniaRegions;
                  } else {
                    _availableRegions = null;
                    _availableDistricts = null;
                    _selectedRegion = null;
                    _selectedDistrict = null;
                    widget.controller.updateFormData('regionName', null);
                    widget.controller.updateFormData('districtName', null);
                  }
                });
              },
            ),
            const SizedBox(height: 20),

            // Region (only for Tanzania)
            if (_selectedCountry == "Tanzania")
              CustomDropdown<String>(
                label: 'Region',
                isRequired: true,
                prefixIcon: Icons.map,
                value: _selectedRegion,
                items: (_availableRegions ?? []).map((region) {
                  return DropdownMenuItem<String>(
                    value: region,
                    child: Text(region),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRegion = value;
                    widget.controller.updateFormData('regionName', value);

                    // Load districts for selected region
                    _availableDistricts = _districtsByRegion[value];
                    _selectedDistrict = null;
                    widget.controller.updateFormData('districtName', null);
                  });
                },
              ),
            if (_selectedCountry == "Tanzania") const SizedBox(height: 20),

            // District (only for Tanzania)
            if (_selectedCountry == "Tanzania" && _selectedRegion != null)
              CustomDropdown<String>(
                label: 'District',
                isRequired: true,
                prefixIcon: Icons.place,
                value: _selectedDistrict,
                items: (_availableDistricts ?? []).map((district) {
                  return DropdownMenuItem<String>(
                    value: district,
                    child: Text(district),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDistrict = value;
                    widget.controller.updateFormData('districtName', value);
                  });
                },
              ),
            if (_selectedCountry == "Tanzania" && _selectedRegion != null)
              const SizedBox(height: 20),

            // Residence
            CustomTextField(
              label: 'Residence',
              isRequired: true,
              prefixIcon: Icons.home,
              hint: 'e.g., Mikocheni',
              initialValue: widget.controller.formData['residence'],
              onChanged: (value) {
                widget.controller.updateFormData('residence', value);
              },
            ),
            const SizedBox(height: 20),

            // Street
            CustomTextField(
              label: 'Street',
              prefixIcon: Icons.signpost,
              hint: 'e.g., Sam Nujoma Road',
              initialValue: widget.controller.formData['street'],
              onChanged: (value) {
                widget.controller.updateFormData('street', value);
              },
            ),
            const SizedBox(height: 20),

            // House Number
            CustomTextField(
              label: 'House Number',
              prefixIcon: Icons.home_outlined,
              hint: 'e.g., Plot 123',
              initialValue: widget.controller.formData['houseNumber'],
              onChanged: (value) {
                widget.controller.updateFormData('houseNumber', value);
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
