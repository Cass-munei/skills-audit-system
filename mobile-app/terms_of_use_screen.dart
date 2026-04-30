import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String termsText =
        'Terms of Use – Skills Audit System\n\n'
        'Effective Date: 03 October 2025\n'
        'Last Updated: 03 October 2025\n\n'
        'Welcome to the Skills Audit System ("System", "Platform", "Service"), provided by National Treasury ("we", "our", "us"). By accessing or using our Service, you agree to comply with and be bound by these Terms of Use. Please read them carefully before using the Platform.\n\n'
        '1. Acceptance of Terms\n\n'
        'By registering, accessing, or using the Skills Audit System, you agree to these Terms of Use and our Privacy Policy. If you do not agree, you must not use the Platform.\n\n'
        '2. Eligibility\n\n'
        'You must be at least 18 years old (or the legal age in your jurisdiction) to use the Platform.\n\n'
        'By creating an account, you confirm that all information provided is accurate, complete, and kept up to date.\n\n'
        '3. User Accounts\n\n'
        'Users are responsible for safeguarding their login credentials.\n\n'
        'Any activity carried out under your account is your responsibility.\n\n'
        'You must notify us immediately if you suspect unauthorized use of your account.\n\n'
        '4. Use of the Platform\n\n'
        'You agree to use the Platform for lawful purposes only. Prohibited uses include:\n\n'
        'Uploading false, misleading, or fraudulent information.\n\n'
        'Attempting to hack, disrupt, or exploit the Platform.\n\n'
        'Sharing or distributing other users\' data without consent.\n\n'
        'Violating any applicable laws or regulations.\n\n'
        '5. Intellectual Property\n\n'
        'All content, software, logos, designs, and functionality on the Platform are owned by or licensed to us and are protected by copyright, trademark, and intellectual property laws.\n\n'
        'You may not copy, modify, distribute, or exploit any part of the Platform without prior written permission.\n\n'
        '6. Data & Privacy\n\n'
        'Your use of the Platform is also governed by our Privacy Policy, which outlines how we collect, store, and protect your data.\n\n'
        '7. Termination\n\n'
        'We reserve the right to suspend or terminate your account at our discretion if you violate these Terms of Use or misuse the Platform.\n\n'
        '8. Disclaimers\n\n'
        'The Platform is provided on an "as is" and "as available" basis.\n\n'
        'We do not guarantee that the Service will always be error-free, secure, or uninterrupted.\n\n'
        'Skills data and assessments are intended as supportive tools and should not be treated as final professional certifications.\n\n'
        '9. Limitation of Liability\n\n'
        'To the maximum extent permitted by law:\n\n'
        'We are not liable for indirect, incidental, or consequential damages resulting from your use of the Platform.\n\n'
        'Our total liability for any claim arising out of these Terms shall not exceed the amount paid by you (if any) for using the Service.\n\n'
        '10. Modifications\n\n'
        'We may update these Terms of Use from time to time. Continued use of the Platform after updates constitutes your acceptance of the revised Terms.\n\n'
        '11. Governing Law\n\n'
        'These Terms shall be governed by and interpreted under the laws of Republic of South Africa. Any disputes shall be resolved in the courts of Statutory law.\n\n'
        '12. Contact Us\n\n'
        'If you have questions about these Terms, contact us at:';

    final List<String> sections = termsText.split('\n\n');
    final List<TextSpan> spans = [];
    for (int i = 0; i < sections.length; i++) {
      final String section = sections[i];
      final bool isHeading = RegExp(r'^\d+\.').hasMatch(section.trim());
      spans.add(TextSpan(
        text: section + (i < sections.length - 1 ? '\n\n' : ''),
        style: TextStyle(
          fontSize: 16,
          fontWeight: isHeading ? FontWeight.bold : FontWeight.normal,
        ),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Use'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(text: TextSpan(children: spans)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.email),
                  const SizedBox(width: 8),
                  Text(
                    'support@treasury.gov.za',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on),
                  const SizedBox(width: 8),
                  Text('Mvela 057', style: TextStyle(fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
