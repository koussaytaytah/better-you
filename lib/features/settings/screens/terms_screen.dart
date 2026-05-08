import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';

enum LegalDocType { terms, privacy }

class LegalScreen extends StatelessWidget {
  final LegalDocType type;

  const LegalScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isTerms = type == LegalDocType.terms;
    return Scaffold(
      appBar: AppBar(
        title: Text(isTerms ? 'Terms of Service' : 'Privacy Policy',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              icon: isTerms ? Icons.gavel_outlined : Icons.privacy_tip_outlined,
              title: isTerms ? 'Terms of Service' : 'Privacy Policy',
              lastUpdated: 'Last updated: May 2026',
            ),
            const SizedBox(height: 24),
            if (isTerms) ..._termsContent() else ..._privacyContent(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  List<Widget> _termsContent() => [
    _Section('1. Acceptance of Terms',
        'By accessing or using BetterYou ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.'),
    _Section('2. Use of the App',
        'BetterYou is a health and fitness tracking application. You must be at least 13 years old to use this App. You are responsible for maintaining the confidentiality of your account credentials.'),
    _Section('3. Health Disclaimer',
        'The content provided in this App is for informational purposes only and does not constitute medical advice. Always consult with a qualified healthcare provider before starting any fitness or nutrition program. BetterYou is not responsible for any health outcomes.'),
    _Section('4. Coach & Doctor Services',
        'Coaches and healthcare professionals listed in the App are independent service providers. BetterYou facilitates connections but does not employ these professionals. Sessions booked through the App are subject to individual professional agreements.'),
    _Section('5. Subscriptions & Payments',
        'Subscription fees are billed in advance. You may cancel your subscription at any time. Refunds are subject to the App Store (Apple) or Google Play refund policies. BetterYou does not process payments directly.'),
    _Section('6. User Content',
        'You retain ownership of content you submit. By posting content, you grant BetterYou a non-exclusive license to display and distribute that content within the App. You must not post harmful, illegal, or misleading content.'),
    _Section('7. Prohibited Activities',
        'You may not: use the App for any unlawful purpose, attempt to gain unauthorized access, transmit malware, harass other users, or misrepresent your identity or professional qualifications.'),
    _Section('8. Termination',
        'We reserve the right to suspend or terminate your account at any time for violation of these terms, without prior notice.'),
    _Section('9. Limitation of Liability',
        'BetterYou is provided "as is". We are not liable for any indirect, incidental, or consequential damages arising from your use of the App.'),
    _Section('10. Contact',
        'For questions about these Terms, contact us at: support@betteryou.app'),
  ];

  List<Widget> _privacyContent() => [
    _Section('1. Information We Collect',
        'We collect information you provide directly (name, email, health metrics, goals), automatically (usage data, device info), and from third-party services (Google/Apple sign-in).'),
    _Section('2. How We Use Your Information',
        'We use your data to: provide and improve the App, personalize your experience, send notifications you have opted into, process bookings, and comply with legal obligations.'),
    _Section('3. Health Data',
        'Health information you enter (weight, activity, nutrition) is stored securely in Firebase (Google Cloud). We do not sell your health data. It is used solely to provide personalized features within the App.'),
    _Section('4. Data Sharing',
        'We share data with: Firebase/Google for infrastructure, coaches and doctors you book sessions with (limited to booking details), and analytics providers. We do not sell your personal data to third parties.'),
    _Section('5. Data Retention',
        'Your data is retained while your account is active. You may delete your account and all associated data at any time from Settings → Delete Account.'),
    _Section('6. Your Rights',
        'Depending on your location, you may have rights to access, correct, or delete your personal data. Contact us at privacy@betteryou.app to exercise these rights.'),
    _Section('7. Cookies & Tracking',
        'The App uses Firebase Analytics to understand usage patterns. You can opt out of analytics tracking in Settings → Privacy.'),
    _Section('8. Security',
        'We implement industry-standard security measures including encrypted data transmission and Firebase Security Rules. However, no system is 100% secure.'),
    _Section('9. Children\'s Privacy',
        'The App is not intended for children under 13. We do not knowingly collect data from children under 13.'),
    _Section('10. Changes to This Policy',
        'We may update this Privacy Policy. We will notify you of significant changes via email or in-app notification.'),
    _Section('11. Contact',
        'For privacy questions: privacy@betteryou.app\nFor general support: support@betteryou.app'),
  ];
}

class _Header extends StatelessWidget {
  final IconData icon;
  final String title;
  final String lastUpdated;

  const _Header({required this.icon, required this.title, required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.04)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(lastUpdated, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.text)),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(color: Colors.grey[700], height: 1.6, fontSize: 14)),
        ],
      ),
    );
  }
}
