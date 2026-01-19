# Quick Reference: Hardcoded Dropdown Data

## All Hardcoded Values

### Church Positions (18)
1. Mtume Mkuu
2. Msaidizi Binafsi wa Mtume Mkuu
3. Mtume
4. Mchungaji Kiongozi
5. Mchungaji
6. Katibu
7. Mtawala
8. Askofu
9. Cell Leader
10. Mweka Hazina
11. Mwanakamati
12. Mjumbe wa Board
13. Funguka
14. ICT
15. TV
16. Sunday School Teacher
17. Walinzi
18. Muumini

### Countries (15)
1. Tanzania
2. Kenya
3. Malawi
4. Zambia
5. Rwanda
6. Burundi
7. Republic of Congo
8. Mozambique
9. Botswana
10. South Africa
11. South Sudan
12. UK
13. USA
14. Pakistan
15. India

### Tanzania Regions (30)
1. Arusha
2. Dar es Salaam
3. Dodoma
4. Geita
5. Iringa
6. Kagera
7. Katavi
8. Kigoma
9. Kilimanjaro
10. Lindi
11. Manyara
12. Mara
13. Mbeya
14. Morogoro
15. Mtwara
16. Mwanza
17. Njombe
18. Pemba Kaskazini
19. Pemba Kusini
20. Pwani
21. Rukwa
22. Ruvuma
23. Shinyanga
24. Simiyu
25. Singida
26. Songwe
27. Tabora
28. Tanga
29. Unguja Kaskazini
30. Unguja Kusini

### Mikoa - Dar es Salaam Districts (8)
1. Mwenge
2. Ushindi
3. Temeke
4. Kinondoni
5. Imara
6. Yombo
7. Kisukuru
8. Zanzibar

### Service Regions (52 total)
**Includes:**
- All 15 countries
- 29 Tanzania regions (all except "Dar es Salaam")
- 8 Mikoa (Dar es Salaam districts)

**Full List:**
Tanzania, Kenya, Malawi, Zambia, Rwanda, Burundi, Republic of Congo, Mozambique, Botswana, South Africa, South Sudan, UK, USA, Pakistan, India, Arusha, Dodoma, Geita, Iringa, Kagera, Katavi, Kigoma, Kilimanjaro, Lindi, Manyara, Mara, Mbeya, Morogoro, Mtwara, Mwanza, Njombe, Pemba Kaskazini, Pemba Kusini, Pwani, Rukwa, Ruvuma, Shinyanga, Simiyu, Singida, Songwe, Tabora, Tanga, Unguja Kaskazini, Unguja Kusini, Mwenge, Ushindi, Temeke, Kinondoni, Imara, Yombo, Kisukuru, Zanzibar

## File Location
`lib/screens/onboarding/pages/church_details_page.dart`

## How to Update

1. Open `church_details_page.dart`
2. Find the list you want to update
3. Add/remove/modify items
4. Save file
5. Hot reload (`r`) or hot restart (`R`)

## Example: Adding a New Church Position

```dart
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
  "New Position Here"  // Add your new position
];
```

## Notes
- No API calls needed for these dropdowns
- Data loads instantly (no network delay)
- Works offline
- Registration still requires backend API
