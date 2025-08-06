import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/orders/track_provider.dart'; // <-- NEW

class TrackOrderPage extends ConsumerWidget {
  final String orderId;
  final String deliveryBoy;
  final String address;
  final String phoneNumber;
  final String status;

  const TrackOrderPage({
    super.key,
    required this.orderId,
    required this.deliveryBoy,
    required this.address,
    required this.phoneNumber,
    required this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print("TrackOrderPage received orderId: $orderId");
    final currentLocationAsyncValue =
        ref.watch(currentLocationProvider(orderId));
    final destinationLocationAsyncValue =
        ref.watch(destinationLocationProvider(orderId));
    final routeAsyncValue = ref.watch(routeProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        foregroundColor: Colors.black,
        title: Text(
          'TrackOrder #${getLast9Digits(orderId)}',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Stack(
        children: [
          /// 1) Fill the background with the map (or loading/error widget).
          Positioned.fill(
            child: currentLocationAsyncValue.when(
              data: (currentLocation) {
                if (currentLocation == null) {
                  return Center(
                    child: Text(
                      "Current location not found.",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  );
                }
                return destinationLocationAsyncValue.when(
                  data: (destinationLocation) {
                    if (destinationLocation == null) {
                      return Center(
                        child: Text(
                          "Destination location not found.",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      );
                    }
                    return routeAsyncValue.when(
                      data: (routePoints) => FlutterMap(
                        options: MapOptions(
                          initialCenter: currentLocation,
                          initialZoom: 14.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: routePoints,
                                strokeWidth: 4.0,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: currentLocation,
                                child: const Icon(
                                  size: 25,
                                  Icons.circle,
                                  color: Colors.blue,
                                ),
                              ),
                              Marker(
                                point: destinationLocation,
                                child: const Icon(
                                  size: 30,
                                  CupertinoIcons.house_fill,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      loading: () => const Center(
                          child: CupertinoActivityIndicator(
                        color: Color.fromARGB(255, 65, 88, 108),
                      )),
                      error: (error, stack) => Center(
                        child: Text(
                          "Error: $error",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(
                      child: CupertinoActivityIndicator(
                    color: Color.fromARGB(255, 65, 88, 108),
                  )),
                  error: (error, stack) => Center(
                    child: Text(
                      "Error: $error",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                  child: CupertinoActivityIndicator(
                color: Color.fromARGB(255, 65, 88, 108),
              )),
              error: (error, stack) => Center(
                child: Text(
                  "Error: $error",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),

          /// 2) Show the bottom info panel in a Positioned at the bottom.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: destinationLocationAsyncValue.when(
              data: (destinationLocation) {
                if (destinationLocation == null) {
                  return const SizedBox.shrink();
                }

                // Get the current location from the data (if already loaded)
                final currentLocation = currentLocationAsyncValue.maybeWhen(
                  data: (loc) => loc,
                  orElse: () => null,
                );

                if (currentLocation == null) {
                  return const SizedBox.shrink();
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 5,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            status,
                            style: GoogleFonts.poppins(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        address,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Circle with first letter
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color.fromARGB(255, 65, 88, 108),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  deliveryBoy.isNotEmpty
                                      ? deliveryBoy[0].toUpperCase()
                                      : '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                deliveryBoy,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () async {
                              await FlutterPhoneDirectCaller.callNumber(
                                phoneNumber,
                              );
                            },
                            icon: const Icon(
                              CupertinoIcons.phone_circle,
                              size: 40,
                              color: Color.fromARGB(255, 65, 88, 108),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                  child: CupertinoActivityIndicator(
                color: Color.fromARGB(255, 65, 88, 108),
              )),
              error: (error, stack) => Center(
                child: Text(
                  "Error: $error",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
