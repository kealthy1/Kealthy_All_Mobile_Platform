import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kealthy/view/Cart/cart_container.dart';
import 'package:kealthy/view/Cart/cart_controller.dart';
import 'package:kealthy/view/Login/login_page.dart';
import 'package:kealthy/view/address/adress.dart';
import 'package:kealthy/view/address/provider.dart';
import 'package:kealthy/view/blog/blog.dart';
import 'package:kealthy/view/blog/blog_list.dart';
import 'package:kealthy/view/blog/blogs_tile.dart';
import 'package:kealthy/view/home/category_tab.dart';
import 'package:kealthy/view/home/changing_image.dart';
import 'package:kealthy/view/home/deal_of_day.dart';
import 'package:kealthy/view/home/deal_of_week.dart';
import 'package:kealthy/view/home/kealthy_page.dart';
import 'package:kealthy/view/home/provider.dart';
import 'package:kealthy/view/home/title.dart';
import 'package:kealthy/view/home/update_banner.dart';
import 'package:kealthy/view/notifications/feedback_alert.dart';
import 'package:kealthy/view/notifications/notification_page.dart';
import 'package:kealthy/view/notifications/notification_tab.dart';
import 'package:kealthy/view/notifications/offer.dart';
import 'package:kealthy/view/notifications/rating_alert.dart';
import 'package:kealthy/view/orders/myorders.dart';
import 'package:kealthy/view/profile%20page/edit_profile.dart';
import 'package:kealthy/view/profile%20page/provider.dart';
import 'package:kealthy/view/search/searchbar.dart';
import 'package:kealthy/view/splash_screen/version_check.dart';
import 'package:kealthy/view/splash_screen/version_update_provider.dart';
import 'package:kealthy/view/subscription/sub_details.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin,
        TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;
  bool hasShownDialog = false;
  final bool _hasLocationPermission = false;
  late ScrollController _scrollController;
  late AnimationController _badgeController;
  late Animation<double> _badgeAnimation;
  late double tileWidth;
  late double tileHeight;

  void showKitchenDialog(BuildContext context, WidgetRef ref) {
    Future.delayed(const Duration(milliseconds: 500), () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Future.delayed(const Duration(milliseconds: 500), () {
                  ref.read(tabIndexProvider.notifier).state = 1;
                });
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'lib/assets/images/kitchen logo5.png',
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Discover Kealthy Kitchen: your new healthy food destination!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded)
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartProvider.notifier).loadCartItems();
      checkLocationPermission(ref);
      ref.read(locationDataProvider);
      if (!hasShownDialog) {
        hasShownDialog = true;
        // Use SharedPreferences to show kitchen dialog only once per day
        SharedPreferences.getInstance().then((prefs) {
          final today = DateTime.now();
          final todayString = "${today.year}-${today.month}-${today.day}";

          final lastShown = prefs.getString('lastKitchenDialogDate');

          if (lastShown != todayString) {
            showKitchenDialog(context, ref);
            prefs.setString('lastKitchenDialogDate', todayString);
          }
        });
      }

      // Show combined deal alert dialog for deal of the day and week, up to two times per day
      SharedPreferences.getInstance().then((prefs) {
        final today = DateTime.now();
        final todayString = "${today.year}-${today.month}-${today.day}";

        final jsonString = prefs.getString('lastOfferDialogRecord');
        Map<String, dynamic> record = {};
        if (jsonString != null) {
          record = Map<String, dynamic>.from(json.decode(jsonString));
        }

        final count =
            (record['date'] == todayString) ? (record['count'] ?? 0) : 0;

        if (count < 2) {
          record = {'date': todayString, 'count': count + 1};
          prefs.setString('lastOfferDialogRecord', json.encode(record));

          FirebaseFirestore.instance
              .collection('Products')
              .get()
              .then((snapshot) {
            final docs = snapshot.docs;
            final dealDay =
                docs.where((doc) => (doc.data())['deal_of_the_day'] == true);
            final dealWeek =
                docs.where((doc) => (doc.data())['deal_of_the_week'] == true);

            if (dealDay.isEmpty && dealWeek.isEmpty) return;

            Future.delayed(const Duration(milliseconds: 500), () {
              showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: "Deal Dialog",
                transitionDuration: const Duration(milliseconds: 400),
                pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
                transitionBuilder: (context, animation, secondaryAnimation, _) {
                  final curvedValue =
                      Curves.easeInOut.transform(animation.value) - 1.0;
                  return Transform.translate(
                    offset: Offset(0, curvedValue * -50),
                    child: Opacity(
                      opacity: animation.value,
                      child: Dialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("Hot Deals Available!",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              if (dealDay.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const DealOfTheDayPage()),
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.orange),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Image.asset(
                                          'lib/assets/images/deal day.png',
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text("🔥 Deal of the Day",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const Text(
                                            "Tap to check today’s offer"),
                                      ],
                                    ),
                                  ),
                                ),
                              if (dealWeek.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const DealOfTheWeekPage()),
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3F2FD),
                                      borderRadius: BorderRadius.circular(10),
                                      border:
                                          Border.all(color: Colors.lightBlue),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Image.asset(
                                          'lib/assets/images/deal week.png',
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text("🎉 Deal of the Week",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const Text(
                                            "Tap to explore this week’s deal"),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            });
          });
        }
      });
    });
    WidgetsBinding.instance.addObserver(this);

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _badgeAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _badgeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkLocationPermission(ref);
    }
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      ref.read(cartVisibilityProvider.notifier).state = false;
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      ref.read(cartVisibilityProvider.notifier).state = true;
    } else {
      ref.read(cartVisibilityProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('building');
    checkVersionUpdate(ref);

    super.build(context);
    final cartItems = ref.read(cartProvider);
    final selectedAddress = ref.watch(selectedLocationProvider);
    final totalItems =
        cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final liveOrdersAsync = ref.watch(liveOrdersProvider);
    final profile = ref.watch(profileProvider);
    final phoneNumber = ref.watch(phoneNumberProvider);
    final rainStatus = ref.watch(rainingStatusStreamProvider);
    final hasCartItems = totalItems > 0;
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      tileWidth = screenWidth * 0.45;
      tileHeight = 220;
    } else if (screenWidth < 900) {
      tileWidth = screenWidth * 0.3;
      tileHeight = 280;
    } else {
      tileWidth = screenWidth * 0.4;
      tileHeight = 350;
    }

    print('Cart items: $cartItems');
    print('Total items: $totalItems');
    print('Has cart items: $hasCartItems');
    print('Location: $selectedAddress');

    // Use the stateful _scrollController and showCartContainer for scroll behavior
    ScrollController scrollController = _scrollController;
    ValueNotifier<bool> showCartContainer = ValueNotifier(true);
    // Listen to scroll events and update showCartContainer accordingly
    scrollController.addListener(() {
      if (scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        showCartContainer.value = true;
      } else if (scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        showCartContainer.value = false;
      }
    });

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: MediaQuery.of(context).size.width < 600
            ? MediaQuery.of(context).size.height * 0.15
            : MediaQuery.of(context).size.height * 0.12,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            // color: Color.fromARGB(255, 233, 210, 181), // pastel peach)
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 249, 227, 201),
                Color.fromARGB(255, 255, 255, 255), // Lighter blue// Pink shade
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: Column(
          children: [_buildHeader(context, ref)],
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Wrap the CustomScrollView with RefreshIndicator
            CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      liveOrdersAsync.when(
                        data: (liveOrders) {
                          final hasLiveOrders = liveOrders.isNotEmpty;

                          if (!hasLiveOrders) return const SizedBox.shrink();

                          return rainStatus.when(
                            data: (rainingData) {
                              final isRaining =
                                  rainingData['isRaining'] == true;
                              final rainMessage = rainingData['message'] ?? "";

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) =>
                                          const MyOrdersPage(),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Left animation (always shown)
                                      ClipOval(
                                        child: Container(
                                          color: Colors.white,
                                          width: 60,
                                          height: 60,
                                          child: Lottie.asset(
                                            'lib/assets/animations/Delivery Boy.json',
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Status and raining text block
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${liveOrders.first['status']}",
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                            if (isRaining) ...[
                                              Text(
                                                rainMessage,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 10),

                                      // Right rain animation (only if raining)
                                      if (isRaining)
                                        SizedBox(
                                          width: 60,
                                          height: 60,
                                          child: Lottie.asset(
                                            'lib/assets/animations/Animation - 1751474562248.json',
                                            fit: BoxFit.cover,
                                            repeat: true,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (error, stack) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 10),
                      Consumer(
                        builder: (context, ref, _) {
                          final showBanner =
                              ref.watch(versionUpdateAvailableProvider);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showBanner)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      right: 10.0, left: 10),
                                  child: UpdateBanner(
                                    onTap: () {
                                      final url = Platform.isIOS
                                          ? 'https://apps.apple.com/in/app/id6740621148'
                                          : 'https://play.google.com/store/apps/details?id=com.COTOLORE.Kealthy';
                                      launchUrl(Uri.parse(url),
                                          mode: LaunchMode.externalApplication);
                                    },
                                  ),
                                ),
                              const CenteredTitleWidget(
                                  title: "Fitness & Health"),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: ChangingImageWidget(),
                      ),
                      const SizedBox(height: 10),
                      const CenteredTitleWidget(title: "Categories"),
                      const SizedBox(height: 10),
                      const CategoryTabPage(),
                      const SizedBox(height: 10),
                      const CenteredTitleWidget(title: "Subscribe & Save"),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SubscriptionDetailsPage(),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: Container(
                              color: const Color(0xFFF4F4F5),
                              child: Image.asset(
                                'lib/assets/images/new1.png',
                                height: 80,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const CenteredTitleWidget(
                          title: "Hot Deals & Exclusive Offers"),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isTablet =
                                MediaQuery.of(context).size.width >= 600;
                            final imageHeight = isTablet ? 150.0 : 100.0;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const DealOfTheDayPage()),
                                    );
                                  },
                                  child: SizedBox(
                                    width: (MediaQuery.of(context).size.width -
                                            48) /
                                        2,
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: Container(
                                            color: const Color(0xFFF4F4F5),
                                            child: Image.asset(
                                              'lib/assets/images/deal day.png',
                                              height: imageHeight,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const DealOfTheWeekPage()),
                                    );
                                  },
                                  child: SizedBox(
                                    width: (MediaQuery.of(context).size.width -
                                            48) /
                                        2,
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: Container(
                                            color: const Color(0xFFF4F4F5),
                                            child: Image.asset(
                                              'lib/assets/images/deal week.png',
                                              height: imageHeight,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const CenteredTitleWidget(title: "Kealthy blogs"),
                      const SizedBox(height: 10),
                      // --- Begin: Blog Pagination Section ---
                      Consumer(
                        builder: (context, ref, _) {
                          final blogPagination =
                              ref.watch(blogPaginationProvider);
                          // Show only 6 recent blogs
                          final limitedBlogs = blogPagination.take(6).toList();
                          final screenWidth = MediaQuery.of(context).size.width;
                          double tileWidth;
                          double tileHeight;

                          if (screenWidth < 600) {
                            tileWidth = screenWidth * 0.45;
                            tileHeight = 220;
                          } else if (screenWidth < 900) {
                            tileWidth = screenWidth * 0.3;
                            tileHeight = 280;
                          } else {
                            tileWidth = screenWidth * 0.4;
                            tileHeight = 350;
                          }
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: tileHeight,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Row(
                                    children: [
                                      ...limitedBlogs.map((blog) => SizedBox(
                                            width: tileWidth,
                                            child: BlogListTile(
                                              blog: blog,
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  CupertinoPageRoute(
                                                    builder: (context) =>
                                                        BlogDetailsPage(
                                                            blog: blog),
                                                  ),
                                                );
                                              },
                                            ),
                                          )),
                                      // "See More" tile
                                      SizedBox(
                                        width: tileWidth,
                                        child: Container(
                                          height:
                                              tileHeight, // match BlogListTile height
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const BlogVerticalListPage(),
                                                ),
                                              );
                                            },
                                            child: Center(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "See More",
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Icon(Icons.arrow_forward_ios,
                                                      size: 15,
                                                      color: Theme.of(context)
                                                          .primaryColor),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (phoneNumber.isNotEmpty &&
                                  profile.name.isEmpty &&
                                  profile.email.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 10),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          "Subscribe to our newsletter",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color.fromRGBO(0, 0, 0, 0.4),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        GestureDetector(
                                          onTap: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditProfilePage(
                                                        name: profile.name,
                                                        email: profile.email),
                                              ),
                                            );
                                            if (result == true) {
                                              ref
                                                  .read(
                                                      newsletterSubscribedProvider
                                                          .notifier)
                                                  .state = true;
                                            }
                                          },
                                          child: Text(
                                            'click here',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.blue.shade400,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const CenteredTitleWidget(title: "Connect with us"),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final url = Uri.parse(
                                    'https://www.facebook.com/profile.php?id=61571096468965&mibextid=ZbWKwL');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              // ignore: prefer_const_constructors
                              child: Icon(Icons.facebook,
                                  size: 40, color: Colors.black),
                            ),
                            const SizedBox(width: 20),
                            GestureDetector(
                              onTap: () async {
                                final url = Uri.parse(
                                    'https://www.instagram.com/kealthy.life?igsh=MXVqa2hicG4ydzB5cQ==');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Image.asset(
                                  'lib/assets/images/instagram.png',
                                  height: 40),
                            ),
                            const SizedBox(width: 20),
                            GestureDetector(
                              onTap: () async {
                                final url =
                                    Uri.parse('https://x.com/Kealthy_life/');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Image.asset(
                                  'lib/assets/images/twitter.png',
                                  height: 35),
                            ),
                            const SizedBox(width: 20),
                            GestureDetector(
                              onTap: () async {
                                final url = Uri.parse(
                                    'https://chat.whatsapp.com/BxNSEDXO6jfKmUl0EuZ6qt');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Image.asset(
                                  'lib/assets/images/whatsapp.png',
                                  height: 35),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 50),
                      const KealthyPage(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
            const ReviewAlert(),
            Consumer(
              builder: (context, ref, child) {
                return const OrderFeedbackAlert();
              },
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: CartContainer(),
            ),
            if (!_hasLocationPermission) Container(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddressPage()),
        );
      },
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.location_solid,
                color: Colors.red,
                size: 35,
              ),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final locationData = ref.watch(locationDataProvider);

                    return locationData.when(
                      data: (data) {
                        String displayText;
                        String? subText;
                        bool showSubText = false;

                        if (data.isNotEmpty) {
                          if (data.containsKey('addressType')) {
                            // ✅ Selected Address: Show both fields
                            displayText = data['addressType']!;
                            subText = data['address']!;
                            showSubText = true;
                          } else {
                            // ✅ Current Location: Show only one field
                            displayText = data['address']!;
                          }
                        } else {
                          displayText = "Locating...";
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayText,
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (showSubText && subText != null)
                              Text(
                                subText,
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        );
                      },
                      loading: () => Text(
                        "Locating...",
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      error: (error, stack) => Text("Error: $error"),
                    );
                  },
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoModalPopupRoute(
                      builder: (context) => const NotificationTabPage(),
                    ),
                  );
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      CupertinoIcons.bell,
                      size: 30,
                      color: Colors.black,
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final ratingAsync = ref.watch(notificationProvider);
                        final offersAsync =
                            ref.watch(offersNotificationProvider);
                        final dismissedOffers =
                            ref.watch(dismissedOffersProvider);

                        return ratingAsync.when(
                          data: (ratingNotifications) {
                            final filteredRatings =
                                ratingNotifications.where((notification) {
                              final orderId = notification['order_id'] ?? '';
                              final orderExistsAsync =
                                  ref.watch(orderExistsProvider(orderId));
                              return orderExistsAsync.when(
                                data: (exists) => !exists,
                                loading: () => false,
                                error: (_, __) => false,
                              );
                            }).toList();

                            return offersAsync.when(
                              data: (offers) {
                                final visibleOffersCount = offers
                                    .where((offer) =>
                                        !dismissedOffers.contains(offer['id']))
                                    .length;
                                final totalCount =
                                    filteredRatings.length + visibleOffersCount;

                                if (totalCount > 0) {
                                  return Positioned(
                                    right: -3,
                                    top: -12,
                                    child: ScaleTransition(
                                      scale: _badgeAnimation,
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          totalCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  return const SizedBox.shrink();
                                }
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const SearchBarWidget(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
