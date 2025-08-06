import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/Login/login_page.dart';
import 'package:kealthy/view/address/adress.dart';
import 'package:kealthy/view/orders/myorders.dart';
import 'package:kealthy/view/profile%20page/Terms_and_condition.dart';
import 'package:kealthy/view/profile%20page/edit_profile.dart';
import 'package:kealthy/view/profile%20page/privacy_policy.dart';
import 'package:kealthy/view/profile%20page/provider.dart';
import 'package:kealthy/view/profile%20page/refund_and_return.dart';
import 'package:kealthy/view/profile%20page/share.dart';
import 'package:kealthy/view/profile%20page/support.dart';
import 'package:kealthy/view/subscription/sub_view_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shimmer/shimmer.dart';

// Example: version from package_info
final versionProvider = FutureProvider<String>((ref) async {
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version; // e.g. "1.0.0"
});

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Fetch latest data each time this page is visited
    Future.microtask(() {
      ref.read(profileProvider.notifier).fetchProfileData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final versionAsyncValue = ref.watch(versionProvider);
    final phoneNumber = ref.watch(phoneNumberProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      // 🚀 No more `profile.isLoading ? spinner : content`
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top + 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 50,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        profile.isLoading
                            ? Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  width: 120,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300]!,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              )
                            : Text(
                                profile.name.isNotEmpty
                                    ? profile.name
                                    : 'Guest',
                                overflow: TextOverflow.visible,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                        // Email
                        profile.isLoading
                            ? Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  width: 180,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300]!,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              )
                            : profile.email.isNotEmpty
                                ? Text(
                                    profile.email,
                                    overflow: TextOverflow.visible,
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  )
                                : const SizedBox
                                    .shrink(), // 🔁 hide completely if no value
                      ],
                    ),
                  ),
                  if (phoneNumber.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfilePage(
                              name: profile.name,
                              email: profile.email,
                            ),
                          ),
                        ).then((_) {
                          ref.read(profileProvider.notifier).fetchProfileData();
                        });
                      },
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  const ShareAppButton(),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // 🔹 Tiles

            _buildTile(
              context: context,
              title: 'Orders',
              icon: CupertinoIcons.bag,
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) => const MyOrdersPage()),
                );
              },
            ),
            _divider(),
            _buildTile(
              context: context,
              title: 'Subscriptions',
              icon: CupertinoIcons.check_mark_circled,
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) =>
                          const SubscriptionOrderDetailsPage()),
                );
              },
            ),
            _divider(),
            _buildTile(
              context: context,
              title: 'My Address',
              icon: CupertinoIcons.home,
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => const AddressPage()),
                );
              },
            ),

            _divider(),
            _buildTile(
              context: context,
              title: 'Privacy Policy',
              icon: Icons.privacy_tip_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) => const PrivacyPolicy()),
                );
              },
            ),
            _divider(),
            _buildTile(
              context: context,
              title: 'Terms and Conditions',
              icon: Icons.assignment_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) => const TermsAndCondition()),
                );
              },
            ),
            _divider(),
            _buildTile(
              context: context,
              title: 'Return and Refund Policies',
              icon: CupertinoIcons.arrow_uturn_left,
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) => const RefundAndReturn()),
                );
              },
            ),
            _divider(),
            _buildTile(
              context: context,
              title: 'Help & Support',
              icon: CupertinoIcons.chat_bubble_text,
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => const SupportPage()),
                );
              },
            ),
            _divider(),
            if (phoneNumber.isNotEmpty) ...[
              _buildTile(
                context: context,
                title: 'Delete Account',
                icon: CupertinoIcons.delete,
                onTap: () => deleteAccount(ref, context), // Call the function
              ),
              _divider(),
            ],

            const SizedBox(height: 20),
            // 🔹 Logout Button

            if (phoneNumber.isNotEmpty) ...[
              // 🔹 Logout Button
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return buildLogoutAlertDialog(context);
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    CupertinoIcons.power,
                    size: 25,
                    color: Colors.red,
                  ),
                  label: Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              versionAsyncValue.maybeWhen(
                data: (version) => Text(
                  'Version: $version',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // Reusable tile
  Widget _buildTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 28,
        color: const Color.fromARGB(255, 65, 88, 108),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Divider(
          thickness: 0.1,
        ),
      );

  Widget buildLogoutAlertDialog(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: Colors.white,
      icon: const Icon(
        Icons.exit_to_app,
        size: 60,
        color: Color(0xFF273847),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Are You Leaving?',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Are you sure to logout? All your data may be lost.',
            style: GoogleFonts.poppins(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              color: Colors.grey[700],
              fontSize: 15,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            logoutUser(context, ref);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF273847),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          ),
          child: Text(
            'Yes',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }
}
