import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/Toast/toast_helper.dart';
import 'package:kealthy/view/profile%20page/provider.dart';

final isSavingProvider = StateProvider<bool>((ref) => false);

class EditProfilePage extends ConsumerStatefulWidget {
  final String name;
  final String email;

  const EditProfilePage({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);

    // Set our provider's state to the incoming values so they're in sync
    Future.delayed(Duration.zero, () {
      final currentProfile = ref.read(profileProvider);
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      ref.read(profileProvider.notifier).state = currentProfile.copyWith(
        name: widget.name,
        email: widget.email,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final isSaving = ref.watch(isSavingProvider);
    ref.read(profileProvider.notifier);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            "Edit Profile",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 🔹 Name Input
              TextField(
                controller: _nameController,
                onChanged: (value) {
                  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                  ref.read(profileProvider.notifier).state =
                      profile.copyWith(name: value);
                },
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
                decoration: InputDecoration(
                  labelText: "Name",
                  labelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _emailController,
                onChanged: (value) {
                  // if (!value.contains('@gmail.com')) {
                  //   ToastHelper.showErrorToast(
                  //       "Please enter a valid email address");
                  //   return;
                  // }
                  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                  ref.read(profileProvider.notifier).state =
                      profile.copyWith(email: value);
                },
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
                decoration: InputDecoration(
                  labelText: "Email ID",
                  labelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 🔹 Save Button (No spinner here)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: const Color.fromARGB(255, 65, 88, 108),
                ),
                onPressed: isSaving
                    ? null // Disable button while loading
                    : () async {
                        ref.read(isSavingProvider.notifier).state =
                            true; // 🔥 Start loading

                        final newName = _nameController.text.trim();
                        final newEmail = _emailController.text.trim();

                        if (newName.isEmpty || newEmail.isEmpty) {
                          // Show a simple alert
                          ToastHelper.showErrorToast("Please fill all fields");

                          ref.read(isSavingProvider.notifier).state = false;
                          return;
                        }
                        if (!newEmail.contains('@gmail.com')) {
                          ToastHelper.showErrorToast(
                              "Please enter a valid email address");
                          ref.read(isSavingProvider.notifier).state = false;
                          return;
                        } else {
                          await ref
                              .read(profileProvider.notifier)
                              .updateUserData(newName, newEmail);
                        }

                        ref.read(isSavingProvider.notifier).state =
                            false; // 🔥 Stop loading

                        Navigator.pop(context); // ✅ Close the screen
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CupertinoActivityIndicator(
                            color: Color.fromARGB(255, 65, 88, 108)))
                    : Text(
                        "Save",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
