import 'package:flutter/material.dart';
import 'package:kealthy/view/notifications/offer.dart';
import 'notification_page.dart';

class NotificationTabPage extends StatelessWidget {
  final int initialIndex;
  const NotificationTabPage({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: initialIndex,
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text('Notifications'),
          bottom: const TabBar(
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: 'Offers & Deals'),
              Tab(text: 'Rate Us'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OffersNotificationPage(),
            NotificationsScreen(),
          ],
        ),
      ),
    );
  }
}
