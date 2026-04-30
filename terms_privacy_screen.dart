import 'package:flutter/material.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String privacyText =
        'Privacy Policy – Skills Audit System\n\n'
        'Effective Date: 03 October 2025\n'
        'Last Updated: 03 October 2025\n\n'
        'Skills Audit System ("we", "our", "us") respects your privacy and is committed to protecting your personal data. This Privacy Policy explains how we collect, use, store, and share information when you use the Skills Audit System ("Platform", "Service").\n\n'
        '1. Information We Collect\n\n'
        'We may collect the following categories of information:\n\n'
        'a) Personal Information\n\n'
        'Name, surname, and contact details (email, phone number).\n\n'
        'Job role, department, and employment details.\n\n'
        'b) Skills & Assessment Data\n\n'
        'Skills profiles, competencies, and self-assessments.\n\n'
        'Results of skill audits, feedback, and performance insights.\n\n'
        'c) Usage Information\n\n'
        'Device information (browser type, operating system, IP address).\n\n'
        'Login activity, session duration, and feature usage.\n\n'
        '2. How We Use Your Information\n\n'
        'We process your data to:\n\n'
        'Provide access to the Platform and its features.\n\n'
        'Conduct skills audits, generate reports, and match skill requirements.\n\n'
        'Improve and personalize your experience.\n\n'
        'Ensure security, prevent fraud, and monitor compliance.\n\n'
        'Communicate important updates, notifications, or service changes.\n\n'
        '3. Sharing of Information\n\n'
        'We do not sell your personal information. However, we may share data:\n\n'
        'With authorized administrators in your organization for reporting purposes.\n\n'
        'With trusted third-party service providers who help us operate the Platform.\n\n'
        'When required by law, regulation, or legal process.\n\n'
        '4. Data Security\n\n'
        'We implement appropriate technical and organizational measures to protect your information, including encryption, access controls, and secure storage practices. However, no system is 100% secure, and we cannot guarantee absolute security.\n\n'
        '5. Data Retention\n\n'
        'We retain personal and skills data only for as long as necessary to fulfill the purposes outlined in this Policy or as required by law.\n\n'
        'Once data is no longer required, we securely delete or anonymize it.\n\n'
        '6. Your Rights\n\n'
        'Depending on your jurisdiction, you may have rights such as:\n\n'
        'Accessing the data we hold about you.\n\n'
        'Correcting inaccurate or incomplete data.\n\n'
        'Requesting deletion of your data ("right to be forgotten").\n\n'
        'Restricting or objecting to certain processing activities.\n\n'
        'Requesting data portability.\n\n'
        'You can exercise these rights by contacting us at skills_audit@support.gov.za.\n\n'
        '7. Cookies & Tracking\n\n'
        'We may use cookies and similar technologies to enhance user experience, track platform usage, and improve system performance. You may manage cookie preferences in your browser settings.\n\n'
        '8. Children\'s Privacy\n\n'
        'The Platform is not intended for children under 18. We do not knowingly collect personal data from minors.\n\n'
        '9. International Data Transfers\n\n'
        'If you access the Platform from outside Republic of South Africa, your data may be transferred to and processed in jurisdictions with different data protection laws.\n\n'
        '10. Changes to this Policy\n\n'
        'We may update this Privacy Policy from time to time. We will notify users of any significant changes by posting an update on the Platform.\n\n'
        '11. Contact Us\n\n'
        'For privacy-related inquiries, please contact:\n';

    final List<String> sections = privacyText.split('\n\n');
    final List<TextSpan> spans = [];
    for (int i = 0; i < sections.length; i++) {
      final String section = sections[i];
      final bool isHeading = RegExp(r'^\d+\.').hasMatch(section.trim());
      spans.add(
        TextSpan(
          text: section + (i < sections.length - 1 ? '\n\n' : ''),
          style: TextStyle(
            fontSize: 16,
            fontWeight: isHeading ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
