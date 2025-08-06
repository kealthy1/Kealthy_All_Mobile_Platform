import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy/custom_alert_dialogue.dart';
import 'package:kealthy/view/Login/login_page.dart';
import 'package:kealthy/view/Toast/toast_helper.dart';
import 'package:kealthy/view/address/add_address_button.dart';
import 'package:kealthy/view/address/adress_model.dart';
import 'package:kealthy/view/address/provider.dart';
import 'package:kealthy/view/address/saved_address.dart';
import 'package:kealthy/view/home/title.dart';
import 'package:kealthy/view/map/location.dart';
import 'package:kealthy/view/map/provider.dart';

class AddressPage extends ConsumerStatefulWidget {
  const AddressPage({super.key});

  @override
  ConsumerState<AddressPage> createState() => _LocationPageState();
}

class _LocationPageState extends ConsumerState<AddressPage> {
  void _navigateToLocationPage(AddressDetails addressDetails, bool isUpdating) {
    print('Navigating to Location Page with ID: ${addressDetails.id}');
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => LocationPage(
          addressDetails: addressDetails,
          isUpdating: isUpdating,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(suggestionsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        title: Text(
          'Confirm delivery location',
          style: GoogleFonts.poppins(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: SingleChildScrollView(
          child: Column(children: [
            AddAddressButton(
              onTap: () async {
                final hasPhoneNumber = await checkPhoneNumber();
                if (!hasPhoneNumber) {
                  CustomAlertDialog.show(
                    context: context,
                    title: "Login Required",
                    message:
                        "You need to log in to save your address and use location features.",
                    confirmText: "Login",
                    onConfirm: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginFields()),
                        (route) => false, // Remove all previous routes
                      );
                    },
                  );
                  return;
                }

                // 🔥 Check if location services are enabled
                final serviceEnabled =
                    await Geolocator.isLocationServiceEnabled();
                if (!serviceEnabled) {
                  ToastHelper.showErrorToast(
                      'Please enable location services.');
                  return;
                }

                // 🔥 Check current location permissions
                LocationPermission permission =
                    await Geolocator.checkPermission();
                if (permission == LocationPermission.denied) {
                  // Request permission if initially denied
                  permission = await Geolocator.requestPermission();
                }

                if (permission == LocationPermission.denied) {
                  // User denied permission again, show a toast
                  ToastHelper.showErrorToast(
                      'Location permission is required to add an address.');
                  return;
                }

                if (permission == LocationPermission.deniedForever) {
                  // If denied forever, prompt user to enable it in settings
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          "Enable Location",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                        content: Text(
                          textAlign: TextAlign.start,
                          "Location permission is permanently denied. Please enable it from settings.",
                          style: GoogleFonts.poppins(
                              fontSize: 16, color: Colors.black54),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Geolocator
                                  .openAppSettings(); // Open system settings
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Open Settings",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                  return;
                }

                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const LocationPage(),
                  ),
                );
              },
            ),
            const SizedBox(
              height: 20,
            ),
            const CenteredTitleWidget(title: 'SAVED ADDRESSES'),
            const SizedBox(
              height: 10,
            ),
            SavedAddressesList(onEdit: _navigateToLocationPage),
          ]),
        ),
      ),
    );
  }
}
