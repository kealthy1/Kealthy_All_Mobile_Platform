import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/address/address_pop_menu.dart';

class AddressCard extends StatelessWidget {
  final Map<String, dynamic> addressData;
  final String distanceText;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AddressCard({
    super.key,
    required this.addressData,
    required this.distanceText,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5.0),
          ],
        ),
        child: Row(
          children: [
            Column(
              children: [
                Icon(
                  addressData['type'] == 'Home'
                      ? CupertinoIcons.home
                      : addressData['type'] == 'Work'
                          ? Icons.work_outline
                          : Icons.location_on_outlined,
                  size: 30,
                  color: const Color.fromARGB(255, 65, 88, 108),
                ),
                const SizedBox(height: 5),
                Text('$distanceText km',
                    style: GoogleFonts.poppins(fontSize: 10)),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (addressData['type'] != null)
                    Text(
                      addressData['type'],
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  if (addressData['Name'] != null)
                    Text(
                      '${addressData['Name']}, ${addressData['road']}',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  if (addressData['Landmark']?.isNotEmpty ?? false)
                    Text('Landmark: ${addressData['Landmark']}',
                        style: GoogleFonts.poppins(fontSize: 14)),
                  if (addressData['directions']?.isNotEmpty ?? false)
                    Text('Instructions: ${addressData['directions']}',
                        style: GoogleFonts.poppins(fontSize: 14)),
                ],
              ),
            ),
            AddressPopupMenu(onEdit: onEdit, onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}
