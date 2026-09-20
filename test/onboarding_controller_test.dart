import 'package:flutter_test/flutter_test.dart';
import 'package:efatha_app/screens/onboarding/onboarding_controller.dart';

// NOTE: page navigation uses PageController.animateToPage (timers), so these
// are testWidgets tests ending with pumpAndSettle to flush animations.
void main() {
  group('OnboardingController validation', () {
    testWidgets('personal info page validates required fields', (tester) async {
      final c = OnboardingController();
      expect(c.isCurrentPageValid, isFalse);

      c.updateFormData('firstName', 'Amina');
      c.updateFormData('lastName', 'Juma');
      c.updateFormData('gender', 'Female');
      c.updateFormData('birthDate', DateTime(1995, 4, 12));
      expect(c.isCurrentPageValid, isTrue);
      c.dispose();
      await tester.pumpAndSettle();
    });

    testWidgets('location info requires region+district for Tanzania only',
        (tester) async {
      final c = OnboardingController();
      c.setPage(1);

      // Other country: country + residence is enough.
      c.updateFormData('countryName', 'Kenya');
      c.updateFormData('residence', 'Nairobi');
      expect(c.isCurrentPageValid, isTrue);

      // Tanzania: region + district become mandatory.
      c.updateFormData('countryName', 'Tanzania');
      expect(c.isCurrentPageValid, isFalse);
      c.updateFormData('regionName', 'Dar es Salaam');
      c.updateFormData('districtName', 'Kinondoni');
      expect(c.isCurrentPageValid, isTrue);
      c.dispose();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'contact info requires phone, valid email AND matching password',
        (tester) async {
      final c = OnboardingController();
      c.setPage(2);

      c.updateFormData('phone', '0712345678');
      c.updateFormData('email', 'amina@example.com');
      // No password yet -> invalid (Supabase Auth requirement).
      expect(c.isCurrentPageValid, isFalse);

      c.updateFormData('password', 'secret123');
      // Confirm missing -> still invalid.
      expect(c.isCurrentPageValid, isFalse);

      c.updateFormData('confirmPassword', 'secret12');
      expect(c.isCurrentPageValid, isFalse); // mismatch

      c.updateFormData('confirmPassword', 'secret123');
      expect(c.isCurrentPageValid, isTrue);

      // Bad email fails even with good password.
      c.updateFormData('email', 'not-an-email');
      expect(c.isCurrentPageValid, isFalse);
      c.dispose();
      await tester.pumpAndSettle();
    });

    testWidgets('short password fails validation', (tester) async {
      final c = OnboardingController();
      c.setPage(2);
      c.updateFormData('phone', '0712345678');
      c.updateFormData('email', 'amina@example.com');
      c.updateFormData('password', '123');
      c.updateFormData('confirmPassword', '123');
      expect(c.isCurrentPageValid, isFalse);
      c.dispose();
      await tester.pumpAndSettle();
    });

    testWidgets('church details page validates position + service region',
        (tester) async {
      final c = OnboardingController();
      c.setPage(3);
      expect(c.isCurrentPageValid, isFalse);
      c.updateFormData('churchPosition', 'muumini');
      c.updateFormData('serviceRegion', 'Dar es Salaam');
      expect(c.isCurrentPageValid, isTrue);
      c.dispose();
      await tester.pumpAndSettle();
    });

    testWidgets('progress and reset behave', (tester) async {
      final c = OnboardingController();
      expect(c.progress, 1 / 5);
      c.setPage(2);
      expect(c.currentPage, 2);
      expect(c.progress, 3 / 5);
      c.reset();
      expect(c.currentPage, 0);
      expect(c.formData, isEmpty);
      c.dispose();
      await tester.pumpAndSettle();
    });

    testWidgets('toBelieverModel maps form data', (tester) async {
      final c = OnboardingController();
      c.updateMultipleFields({
        'firstName': 'Amina',
        'middleName': 'Rehema',
        'lastName': 'Juma',
        'gender': 'Female',
        'birthDate': DateTime(1995, 4, 12),
        'phone': '0712345678',
        'email': 'amina@example.com',
        'countryName': 'Tanzania',
        'regionName': 'Dar es Salaam',
        'districtName': 'Kinondoni',
        'residence': 'Mbezi',
        'churchPosition': 'muumini',
        'serviceRegion': 'Dar es Salaam',
      });
      final m = c.toBelieverModel();
      expect(m.fullName, 'Amina Rehema Juma');
      expect(m.phone, '0712345678');
      expect(m.isValid, isTrue);
      final json = m.toJson();
      expect(json['First_Name'], 'Amina');
      expect(json['Church_Position'], 'muumini');
      c.dispose();
      await tester.pumpAndSettle();
    });
  });
}
