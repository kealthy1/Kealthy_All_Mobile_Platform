import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndCondition extends StatelessWidget {
  const TermsAndCondition({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Terms and Conditions',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Terms and Conditions",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Last updated: December 18, 2024",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Please read these terms and conditions carefully before using Our Service.",
              style: GoogleFonts.poppins(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Interpretation and Definitions"),
            _buildSubsectionTitle("Interpretation"),
            Text(
              "The words of which the initial letter is capitalized have meanings defined under the following conditions. The following definitions shall have the same meaning regardless of whether they appear in singular or in plural.",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            _buildSubsectionTitle("Definitions"),
            _buildDefinition(
              "Application",
              "The software program provided by the Company downloaded by You on any electronic device, named Kealthy.",
            ),
            _buildDefinition(
              "Application Store",
              "The digital distribution service operated and developed by Apple Inc. (Apple App Store) or Google Inc. (Google Play Store) in which the Application has been downloaded.",
            ),
            _buildDefinition(
              "Affiliate",
              "An entity that controls, is controlled by or is under common control with a party, where 'control' means ownership of 50% or more of the shares, equity interest or other securities entitled to vote for election of directors or other managing authority.",
            ),
            _buildDefinition(
              "Country",
              "Kerala, India.",
            ),
            _buildDefinition(
              "Company",
              "Kealthy, located at  Floor No.: 1 Building No./Flat No.: 15/293 - C Name Of Premises/Building: Peringala Road/Street: Muriyankara-Pinarmunda Milma Road City/Town/Village: Kunnathunad District: Ernakulam State: Kerala PIN Code: 683565",
            ),
            _buildDefinition(
              "Device",
              "Any device that can access the Service such as a computer, a cellphone or a digital tablet.",
            ),
            _buildDefinition(
              "Service",
              "The Application.",
            ),
            _buildDefinition(
              "Terms and Conditions",
              "These Terms and Conditions that form the entire agreement between You and the Company regarding the use of the Service.",
            ),
            _buildDefinition(
              "Third-party Social Media Service",
              "Any services or content (including data, information, products or services) provided by a third-party that may be displayed, included or made available by the Service.",
            ),
            _buildDefinition(
              "You",
              "The individual accessing or using the Service, or the company, or other legal entity on behalf of which such individual is accessing or using the Service, as applicable.",
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Acknowledgment"),
            Text(
              "These are the Terms and Conditions governing the use of this Service and the agreement that operates between You and the Company. These Terms and Conditions set out the rights and obligations of all users regarding the use of the Service.",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Your access to and use of the Service is conditioned on Your acceptance of and compliance with these Terms and Conditions. These Terms and Conditions apply to all visitors, users and others who access or use the Service.",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "By accessing or using the Service You agree to be bound by these Terms and Conditions. If You disagree with any part of these Terms and Conditions then You may not access the Service.",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "You represent that you are over the age of 18. The Company does not permit those under 18 to use the Service.",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Your access to and use of the Service is also conditioned on Your acceptance of and compliance with the Privacy Policy of the Company. Our Privacy Policy describes Our policies and procedures on the collection, use and disclosure of Your personal information when You use the Application or the Website and tells You about Your privacy rights and how the law protects You. Please read Our Privacy Policy carefully before using Our Service.",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Termination"),
            Text(
              "We may terminate or suspend Your access immediately, without prior notice or liability, for any reason whatsoever, including without limitation if You breach these Terms and Conditions.",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Upon termination, Your right to use the Service will cease immediately.",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Limitation of Liability"),
            Text(
              "Notwithstanding any damages that You might incur,",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Contact Us"),
            Text(
              "Contact UsIf you have any questions about these Terms and Conditions, You can contact us By email\nproject@kealthy.com 📧",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubsectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDefinition(String term, String definition) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black,
          ),
          children: [
            TextSpan(
              text: "$term: ",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: definition),
          ],
        ),
      ),
    );
  }
}