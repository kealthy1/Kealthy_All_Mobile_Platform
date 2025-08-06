import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/Toast/toast_helper.dart';
import 'package:kealthy/view/address/address_card.dart';
import 'package:kealthy/view/address/provider.dart';
import 'package:kealthy/view/home/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'adress_model.dart';

class SavedAddressesList extends ConsumerWidget {
  final Function(AddressDetails, bool) onEdit;

  const SavedAddressesList({super.key, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressFutureProvider);

    return addressesAsync.when(
      loading: () => const Center(
          child: CupertinoActivityIndicator(
        color: Color.fromARGB(255, 65, 88, 108),
      )),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (addresses) {
        if (addresses == null || addresses.isEmpty) {
          return Center(
              child: Text('No addresses found',
                  style: GoogleFonts.poppins(color: Colors.black38)));
        }

        return Column(
          children: addresses.map((addressData) {
            final distanceText =
                (addressData['distance']?.toDouble() ?? 0.0).toStringAsFixed(2);
            return AddressCard(
              addressData: addressData,
              distanceText: distanceText,
              onTap: () async {
                final address = '${addressData['road'] ?? ''}';
                final name = '${addressData['Name'] ?? ''}';
                final prefs = await SharedPreferences.getInstance();
                await saveSelectedAddress(
                  ref: ref,
                  prefs: prefs,
                  address: addressData['road'] ?? '',
                  name: addressData['Name'] ?? '',
                  type: addressData['type'] ?? '',
                  landmark: addressData['Landmark'] ?? '',
                  instructions: addressData['directions'] ?? '',
                  latitude: addressData['latitude'] ?? 0.0,
                  longitude: addressData['longitude'] ?? 0.0,
                  distance: double.parse(distanceText),
                );
                ToastHelper.showSuccessToast(
                    'Address Updated : $name, $address');
                Navigator.pop(context);
              },
              onEdit: () => onEdit(
                AddressDetails.fromMap(addressData),
                true,
              ),
              onDelete: () async {
                bool confirmed = await confirmDelete(context);
                if (confirmed) {
                  await deleteAddressFromProvider(ref, addressData, context);
                }
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<bool> confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Confirm Delete', style: GoogleFonts.poppins()),
            content: Text('Are you sure you want to delete this address?',
                style: GoogleFonts.poppins()),
            actions: [
              TextButton(
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(color: Colors.black)),
                  onPressed: () => Navigator.pop(context, false)),
              TextButton(
                  child: Text('Delete',
                      style: GoogleFonts.poppins(color: Colors.black)),
                  onPressed: () => Navigator.pop(context, true)),
            ],
          ),
        ) ??
        false;
  }

  Future<void> deleteAddressFromProvider(WidgetRef ref,
      Map<String, dynamic> addressData, BuildContext context) async {
    final phoneNumber = await getStoredPhoneNumber();
    final addressType = addressData['type'];
    if (phoneNumber != null && addressType != null) {
      await deleteAddress(phoneNumber, addressType, ref, context);
    }
  }
}
