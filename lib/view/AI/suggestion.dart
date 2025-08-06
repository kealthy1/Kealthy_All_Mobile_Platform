import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:kealthy/view/orders/myorders.dart';
import 'package:kealthy/view/orders/past_orders.dart';
import 'package:kealthy/view/profile%20page/support.dart';
import 'package:kealthy/view/support/live_ticket.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: const AssetImage(
                    "lib/assets/images/PHOTO-2025-02-25-15-14-38-removebg-preview.png"),
                radius: 20,
                backgroundColor: Colors.blueGrey[100],
              ),
              const SizedBox(width: 10),
              Text(
                "Need Help? Im Here for You!",
                style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          HelpOption(
              title: "Track Order",
              onTap: () => navigateTo(context, const MyOrdersPage())),
          HelpOption(
              title: "Past Orders",
              onTap: () => navigateTo(context, const OrderCard())),
          HelpOption(
              title: "Call Help Center",
              onTap: () => showCallSupportDialog(context)),
          HelpOption(
              title: "Open a Ticket",
              onTap: () => navigateTo(context, const SupportPage())),
        ],
      ),
    );
  }

  void navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void showCallSupportDialog(BuildContext context) {
    showAlertLog(
      context: context,
      title: "Contact Support",
      message:
          "Would you like to contact a support executive? Our team is here to assist you.",
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 199, 57, 47)),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Dismiss",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 57, 161, 75)),
              onPressed: () {
                FlutterPhoneDirectCaller.callNumber("8848673425");
              },
              child: Text(
                "Call Now",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class HelpOption extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const HelpOption({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 18, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
