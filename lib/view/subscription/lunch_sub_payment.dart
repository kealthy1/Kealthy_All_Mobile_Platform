import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kealthy/view/Cart/cart_controller.dart';
import 'package:kealthy/view/Login/login_page.dart';
import 'package:kealthy/view/food/food_subcategory.dart';
import 'package:kealthy/view/payment/Online_payment.dart';
import 'package:kealthy/view/payment/services.dart';
import 'package:kealthy/view/profile%20page/provider.dart';
import 'package:kealthy/view/subscription/subscription_lunch_dinner_page.dart'
    hide phoneNumberProvider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:kealthy/view/subscription/dietType.dart';
import 'package:kealthy/view/subscription/new_subscription_page.dart'; // Import to access LunchDinnerState and dfmt if needed

final subscriptionLoadingProvider = StateProvider<bool>((ref) => false);

class MealsSubPaymentPage extends ConsumerWidget {
  final String title;
  final int quantity;
  final dynamic address;
  final double totalAmount;
  final String productName;
  final double baseRate;
  final int handlingCharge;

  const MealsSubPaymentPage({
    super.key,
    required this.title,
    required this.quantity,
    required this.address,
    required this.totalAmount,
    required this.productName,
    required this.baseRate,
    required this.handlingCharge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String normalizePhone(String? s) => (s ?? '').replaceAll(RegExp(r'\D'), '');
    final rawPhone = ref.watch(phoneNumberProvider);
    final number = normalizePhone(rawPhone);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        title: const Text("Make Subscription Payment"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Review Your Subscription",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Plan: $title"),
                  Text("Product: $productName"),
                  Text("Base price: ₹${baseRate.toStringAsFixed(0)}/day"),
                  Text("Quantity: $quantity"),
                  const SizedBox(height: 12),
                  const Text("Delivery Address",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(address.type),
                  Text("${address.name}, ${address.selectedRoad}"),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Text("To Pay : ",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text("₹${totalAmount.toStringAsFixed(0)}",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 65, 88, 108),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final isLoading = ref.read(subscriptionLoadingProvider);
                    if (isLoading) return;
                    ref.read(subscriptionLoadingProvider.notifier).state = true;

                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('subscription_plan_title', title);
                      await prefs.setString(
                          'subscription_product_name', productName);
                      await prefs.setDouble(
                          'subscription_qty', quantity.toDouble());
                      await prefs.setDouble('sub_baseRate', baseRate);
                      await prefs.setInt('sub_handlingFee', handlingCharge);
                      print('Createrazorpay orders:');

                      final razorpayOrderId =
                          await OrderService.createRazorpayOrder(
                        category: 'Kealthy Kitchen',
                        totalAmount: totalAmount,
                        address: address,
                        packingInstructions: '',
                        deliveryInstructions: '',
                        deliveryTime: '',
                        preferredTime: '',
                        isSubscription: true,
                        deliveryFee: 0,
                      );

                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OnlinePaymentProcessing(
                            preferredTime: '',
                            totalAmount: totalAmount,
                            packingInstructions: '',
                            deliveryInstructions: '',
                            address: address,
                            deliverytime: '',
                            deliveryFee: 0,
                            razorpayOrderId: razorpayOrderId,
                            orderType: 'subscription',
                          ),
                        ),
                      );

                      print('Payment result from OnlinePayment: $result');
                      if (result == 'success') {
                        // Save subscription to Firebase
                        final db = ref.read(databaseProvider);
                        final st = ref.read(lunchDinnerProvider);

                        final planDays = st.totalDays;
                        final isTwoMeals = st.isTwoMeals;
                        final dietType = title.contains("Veg")
                            ? DietType.veg
                            : DietType.nonVeg;

                        final primaryMeal =
                            productName.toLowerCase(); // "lunch" | "dinner"
                        final secondaryMeal =
                            primaryMeal == "lunch" ? "dinner" : "lunch";

                        final selectedMealCount = quantity;
                        final allowNonVeg = dietType != DietType.veg;
                        final mealType =
                            dietType == DietType.veg ? "Veg" : "Non Veg";
                        final createdAt =
                            DateTime.now().toUtc().toIso8601String();

                        final fetchedSlot =
                            prefs.getString('selected_slot') ?? '';
                        final fetchedType =
                            prefs.getString('selectedType') ?? '';
                        final fetchedName =
                            prefs.getString('selectedName') ?? '';
                        final fetchedLandmark =
                            prefs.getString('selectedLandmark') ?? '';
                        final fetchedInstruction =
                            prefs.getString('selectedInstruction') ?? '';
                        final fetchedRoad =
                            prefs.getString('selectedRoad') ?? '';
                        final fetchedDistance =
                            prefs.getDouble('selectedDistance') ?? 0.0;
                        final fetchedSelectedLatitude =
                            prefs.getDouble('selectedLatitude') ?? 0.0;
                        final fetchedSelectedLongitude =
                            prefs.getDouble('selectedLongitude') ?? 0.0;

                        final customer = {
                          "activityLevel": "light",
                          "age": "",
                          "gender": "",
                          "height": "",
                          "name": fetchedName,
                          "weight": ""
                        };

                        final delivery = {
                          "address":
                              "${address.type}, ${address.name}, $fetchedRoad",
                          "directions": "",
                          "distance": fetchedDistance,
                          "instruction": fetchedInstruction,
                          "landmark": fetchedLandmark,
                          "latitude": fetchedSelectedLatitude,
                          "longitude": fetchedSelectedLongitude,
                          "phone": number
                        };

                        final preferredSlot = {
                          "lunch": "12:00 PM - 3:00 PM",
                          "dinner": "6:00 PM - 9:00 PM"
                        };
                        final preferredTime = {
                          "lunch": "1:30 PM",
                          "dinner": "6:30 PM"
                        };

                        final pricing = {
                          "baseMonthlyPrice":
                              dietType == DietType.veg ? 6000 : 7500,
                          "currency": "INR",
                          "grandTotal": totalAmount,
                          "pricePerSelectedMeal": totalAmount / quantity,
                        };

                        // ---- NEW: per-meal arrays for skipDates & vegDates ----
                        String dfmt(DateTime d) => DateFormat('yyyy-MM-dd')
                            .format(DateTime(d.year, d.month, d.day));

                        // Skip dates per meal (from your provider's sets)
                        final skipDatesPayload = <String, List<String>>{
                          primaryMeal: (st.skipDates.map(dfmt).toList()
                            ..sort()),
                          if (isTwoMeals)
                            secondaryMeal:
                                (st.skipDatesSecondary.map(dfmt).toList()
                                  ..sort()),
                        };
                        final List<String> selectedMeals = isTwoMeals
                            ? const ['lunch', 'dinner']
                            : <String>[primaryMeal];
                        // Veg dates per meal: mark any date whose override is veg
                        final vegSet = st.dietOverrides.entries
                            .where((e) => e.value == DietType.veg)
                            .map((e) => dfmt(e.key))
                            .toSet();

                        final vegDatesPayload = <String, List<String>>{
                          for (final meal in selectedMeals)
                            meal: (vegSet.toList()..sort()),
                        };
                        // -------------------------------------------------------

                        final mealDateRanges = <String, dynamic>{};
                        final deliveriesDetailed = <Map<String, dynamic>>[];

                        for (final m in selectedMeals) {
                          final isPrimary = m == primaryMeal;
                          final mSkipSet =
                              isPrimary ? st.skipDates : st.skipDatesSecondary;
                          final mHour = m == 'lunch' ? 12 : 18;

                          final dates = <DateTime>[];
                          var cursor = st.startDate;
                          while (dates.length < planDays) {
                            final d =
                                DateTime(cursor.year, cursor.month, cursor.day);
                            if (d.weekday != DateTime.sunday &&
                                !mSkipSet.contains(d)) {
                              dates.add(d);
                            }
                            cursor = cursor.add(const Duration(days: 1));
                          }

                          final mStart =
                              DateFormat('yyyy-MM-dd').format(st.startDate);
                          final mEnd = dates.isNotEmpty
                              ? DateFormat('yyyy-MM-dd').format(dates.last)
                              : mStart;

                          mealDateRanges[m] = {
                            "startDate": mStart,
                            "endDate": mEnd
                          };

                          for (final d in dates) {
                            final diet = st.dietOverrides[d] == DietType.veg
                                ? "veg"
                                : "nonVeg";
                            final dateIso =
                                DateTime(d.year, d.month, d.day, mHour)
                                    .toIso8601String();
                            deliveriesDetailed
                                .add({"date": dateIso, "diet": diet});
                          }
                        }
// Normalize helper
                        String _meal(String s) => s.trim().toLowerCase();

// ✅ Always save in a stable, deduped order

// (Optional but recommended) keep this as number of meals, not item quantity,
// because other parts of your app check == 2 to detect two-meal plans.

                        final menu = {};
                        final allergies = st.allergies.toList();
                        final subData = {
                          "allowNonVeg": allowNonVeg,
                          "createdAt": createdAt,
                          "customer": customer,
                          "delivery": delivery,
                          "preferredSlot": preferredSlot,
                          "preferredTime": preferredTime,
                          "mealDateRanges": mealDateRanges,
                          "mealType": mealType,
                          "menu": menu,
                          "planDays": planDays,
                          "pricing": pricing,
                          "selectedMealCount": selectedMealCount,
                          "selectedMeals": selectedMeals,
                          "skipDates": skipDatesPayload, // ← arrays per meal
                          "vegDates": vegDatesPayload, // ← arrays per meal
                          "deliveriesDetailed": deliveriesDetailed,
                          "allergies": allergies,
                        };

                        final timestamp = DateTime.now().millisecondsSinceEpoch;
                        final subId = timestamp.toString();

                        print('About to save subscription: $subData');
                        await db
                            .child('food_subscription')
                            .child(subId)
                            .set(subData);
                        print('Saved subscription: $subData');

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Subscription created successfully!')),
                        );

                        // Navigate to LunchDinnerPlanPage
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LunchDinnerPlanPage(
                                    mealType: MealType.lunch,
                                  )),
                          (route) => route
                              .isFirst, // This removes all previous routes until the first one
                        );
                      } else if (result == 'failure') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Payment failed. Please try again.')),
                        );
                      } else {
                        print('Payment result: $result');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Payment was cancelled or failed.')),
                        );
                      }
                    } catch (e) {
                      print('Error in payment processing: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('An error occurred. Please try again.')),
                      );
                    } finally {
                      ref.read(subscriptionLoadingProvider.notifier).state =
                          false;
                    }
                  },
                  child: ref.watch(subscriptionLoadingProvider)
                      ? const CupertinoActivityIndicator(
                          radius: 12.0,
                          color: Colors.white,
                        )
                      : const Text("Proceed to Payment"),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
