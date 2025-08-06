import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddressPopupMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AddressPopupMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: Colors.white,
      icon: const Icon(Icons.more_vert),
      onSelected: (choice) {
        if (choice == 'Edit') onEdit();
        if (choice == 'Delete') onDelete();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'Edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined),
              const SizedBox(width: 10),
              Text('Edit', style: GoogleFonts.poppins()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'Delete',
          child: Row(
            children: [
              const Icon(CupertinoIcons.delete),
              const SizedBox(width: 10),
              Text('Delete', style: GoogleFonts.poppins()),
            ],
          ),
        ),
      ],
    );
  }
}