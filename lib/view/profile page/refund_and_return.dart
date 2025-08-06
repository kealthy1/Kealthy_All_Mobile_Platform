import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RefundAndReturn extends StatelessWidget {
  const RefundAndReturn({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Return and Refund Policy',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Last updated: December 18, 2024",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Thank you for shopping at Kealthy.",
              style: GoogleFonts.poppins(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "If, for any reason, You are not completely satisfied with a purchase We invite You to review our policy on refunds and returns.",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "The following terms are applicable for any products that You purchased with Us.",
              style: GoogleFonts.poppins(
                fontSize: 14,
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
              "Company",
              "COTOLORE ENTERPRISES LLP, located at Floor No.: 1, Building No./Flat No.: 15/293 - C, Name Of Premises/Building: Peringala, Road/Street: Muriyankara-Pinarmunda Milma Road, City/Town/Village: Kunnathunad, District: Ernakulam, State: Kerala, PIN Code: 683565.",
            ),
            _buildDefinition(
              "Goods",
              "The items offered for sale on the Service.",
            ),
            _buildDefinition(
              "Orders",
              "A request by You to purchase Goods from Us.",
            ),
            _buildDefinition(
              "Service",
              "The Application.",
            ),
            _buildDefinition(
              "You",
              "The individual accessing or using the Service, or the company, or other legal entity on behalf of which such individual is accessing or using the Service, as applicable.",
            ),
            const SizedBox(height: 10),
            Text(
              "In order to exercise Your right of cancellation, You must inform Us of your decision by means of a clear statement. You can inform us of your decision by:",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            _buildContactDetail("By email", "project@kealthy.com"),
            const SizedBox(height: 10),
            Text(
              "We will reimburse You no later than 14 days from the day on which We receive the returned Goods. We will use the same means of payment as You used for the Order, and You will not incur any fees for such reimbursement.",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Conditions for Returns"),
            Text(
              "In order for the Goods to be eligible for a return, please make sure that:",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            _buildBulletPoint("The Goods are in the original packaging."),
            const SizedBox(height: 10),
            Text(
              "The following Goods cannot be returned:",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            _buildBulletPoint(
                "The supply of Goods made to Your specifications or clearly personalized."),
            _buildBulletPoint(
                "The supply of Goods which according to their nature are not suitable to be returned, deteriorate rapidly or where the date of expiry is over."),
            _buildBulletPoint(
                "The supply of Goods which are not suitable for return due to health protection or hygiene reasons and were unsealed after delivery."),
            _buildBulletPoint(
                "The supply of Goods which are, after delivery, according to their nature, inseparably mixed with other items."),
            const SizedBox(height: 10),
            Text(
              "We reserve the right to refuse returns of any merchandise that does not meet the above return conditions in our sole discretion.",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Only regular priced Goods may be refunded. Unfortunately, Goods on sale cannot be refunded. This exclusion may not apply to You if it is not permitted by applicable law.",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Returning Goods"),
            Text(
              "You are responsible for the cost and risk of returning the Goods to Us. You should send the Goods at the following address:",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Floor No.: 1\nBuilding No./Flat No.: 15/293 - C\nName Of Premises/Building: Peringala\nRoad/Street: Muriyankara-Pinarmunda Milma Road\nCity/Town/Village: Kunnathunad\nDistrict: Ernakulam\nState: Kerala\nPIN Code: 683565",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "We cannot be held responsible for Goods damaged or lost in return shipment. Therefore, We recommend an insured and trackable mail service. We are unable to issue a refund without actual receipt of the Goods or proof of received return delivery.",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Gifts"),
            Text(
              "If the Goods were marked as a gift when purchased and then shipped directly to you, You'll receive a gift credit for the value of your return. Once the returned product is received, a gift certificate will be mailed to You.",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "If the Goods weren't marked as a gift when purchased, or the gift giver had the Order shipped to themselves to give it to You later, We will send the refund to the gift giver.",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionTitle("Contact Us"),
            Text(
              "If you have any questions about our Returns and Refunds Policy, please contact us:",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            _buildContactDetail("By email", "project@kealthy.com 📧"),
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

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: GoogleFonts.poppins(
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactDetail(String method, String detail) {
    return Row(
      children: [
        Text(
          "$method: ",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          detail,
          style: GoogleFonts.poppins(
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}