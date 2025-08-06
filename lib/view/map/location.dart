import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy/view/Toast/toast_helper.dart';
import 'package:kealthy/view/address/adress_model.dart';
import 'package:kealthy/view/address/provider.dart';
import 'package:kealthy/view/map/address_bottom_sheet.dart';
import 'package:kealthy/view/map/distance_service.dart';
import 'package:kealthy/view/map/location_service.dart';
import 'package:kealthy/view/map/place%20suggestion_provider.dart';
import 'package:kealthy/view/map/provider.dart';
import 'package:kealthy/view/map/suggestions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class LocationPage extends ConsumerStatefulWidget {
  final AddressDetails? addressDetails;
  final bool isUpdating;

  const LocationPage({
    super.key,
    this.addressDetails,
    this.isUpdating = false,
  });

  @override
  ConsumerState<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends ConsumerState<LocationPage> {
  @override
  void initState() {
    super.initState();

    // Delay the state update to avoid modifying providers during widget building
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedLocationProvider.notifier).state;
    });
  }

  final _searchController = TextEditingController();
  final nameController = TextEditingController();
  final flatRoomAreaController = TextEditingController();
  final landmarkController = TextEditingController();
  final otherInstructionsController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final currentPosition = ref.watch(locationProvider);
    final address = ref.watch(addressProviders);
    ref.watch(suggestionsProvider); // Watch suggestions
    ref.watch(placeSuggestionsProvider);
    bool isBottomSheetOpen = false;
    final asyncShowMap = ref.watch(showMapProvider);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: true,
        title: Text(
          'Confirm delivery location',
          style: GoogleFonts.poppins(),
        ),
      ),
      body: SafeArea(
        child: currentPosition != null && asyncShowMap.asData?.value == true
            ? Stack(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: GoogleMap(
                      key: ValueKey(
                          '${currentPosition.latitude}_${currentPosition.longitude}'),
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          currentPosition.latitude,
                          currentPosition.longitude,
                        ),
                        zoom: 18.0,
                      ),
                      onMapCreated: (controller) {
                        ref.read(mapControllerProvider.notifier).state =
                            controller;
                      },
                      onCameraMove: (position) {
                        // Update position as the camera moves
                        ref.read(selectedPositionProvider.notifier).state =
                            position.target;
                      },
                      onCameraIdle: () async {
                        final targetPosition =
                            ref.read(selectedPositionProvider);
                        if (targetPosition != null) {
                          // Get the address from the selected position
                          final address =
                              await LocationHelper.getAddressFromLatLng(
                                  targetPosition);

                          // Update the address provider with the fetched address
                          ref.read(addressProviders.notifier).state = address;
                        }
                      },
                      myLocationButtonEnabled: false,
                      myLocationEnabled: false,
                      mapType: MapType.terrain,
                      mapToolbarEnabled: true,
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.65 / 2 - 25,
                    left: MediaQuery.of(context).size.width / 2 - 25,
                    child: Image.asset(
                      'lib/assets/images/location.png',
                      width: 50,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(10.0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8.0,
                            offset: Offset(0, -2),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            child: Row(
                              children: [
                                Text(
                                  'DELIVERING YOUR ORDER TO',
                                  style: GoogleFonts.poppins(
                                      color: Colors.blue, fontSize: 12),
                                ),
                                const Spacer(),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    side: const BorderSide(
                                      color: Color.fromARGB(255, 65, 88, 108),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final notifier =
                                        ref.read(locationProvider.notifier);
                                    final loader = ref.read(
                                        isFetchingLocationProvider.notifier);
                                    loader.state = true;

                                    try {
                                      await notifier.getCurrentLocation();
                                      final currentPosition =
                                          ref.read(locationProvider);

                                      if (currentPosition != null) {
                                        notifier.selectedPosition = LatLng(
                                          currentPosition.latitude,
                                          currentPosition.longitude,
                                        );

                                        final controller =
                                            ref.read(mapControllerProvider);
                                        if (controller != null) {
                                          await controller.animateCamera(
                                            CameraUpdate.newCameraPosition(
                                              CameraPosition(
                                                target: LatLng(
                                                  currentPosition.latitude,
                                                  currentPosition.longitude,
                                                ),
                                                zoom: 18.0,
                                              ),
                                            ),
                                          );
                                        }

                                        final address = await LocationHelper
                                            .getAddressFromLatLng(
                                          LatLng(currentPosition.latitude,
                                              currentPosition.longitude),
                                        );
                                        ref
                                            .read(addressProviders.notifier)
                                            .state = address;
                                      }
                                    } finally {
                                      loader.state = false;
                                    }
                                  },
                                  child: ref.watch(isFetchingLocationProvider)
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color.fromARGB(
                                                255, 65, 88, 108),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.my_location,
                                          color:
                                              Color.fromARGB(255, 65, 88, 108),
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          address != null
                              ? Row(
                                  children: [
                                    Image.asset(
                                      'lib/assets/images/location.png',
                                      width: 50,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        address,
                                        style: GoogleFonts.poppins(
                                            color: Colors.black, fontSize: 20),
                                      ),
                                    ),
                                  ],
                                )
                              : Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    width: double.infinity,
                                    height: 20,
                                    color: Colors.white,
                                  ),
                                ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.9,
                              height: 50,
                              child: ElevatedButton(
                                // Track bottom sheet status

                                onPressed: () async {
                                  if (isBottomSheetOpen) {
                                    return; // Prevent multiple openings
                                  }
                                  isBottomSheetOpen = true;

                                  final position =
                                      ref.read(selectedPositionProvider);

                                  if (position == null) {
                                    ToastHelper.showErrorToast(
                                        'Please select a location on the map.');
                                    isBottomSheetOpen =
                                        false; // Reset flag on failure

                                    return;
                                  }

                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  bool isTestMode =
                                      prefs.getBool('isTestMode') ?? false;

                                  if (!isTestMode) {
                                    // Define restaurant coordinates
                                    const double restaurantLatitude =
                                        10.010099620051944;
                                    const double restaurantLongitude =
                                        76.38422358870001;

                                    // Get driving distance
                                    final drivingDistanceInKm =
                                        await DistanceService()
                                            .getDrivingDistanceInKm(
                                      startLat: restaurantLatitude,
                                      startLng: restaurantLongitude,
                                      endLat: position.latitude,
                                      endLng: position.longitude,
                                    );

                                    print(
                                        "Driving distance: ${drivingDistanceInKm?.toStringAsFixed(2)} km");

                                    if (drivingDistanceInKm != null &&
                                        drivingDistanceInKm > 12) {
                                      ToastHelper.showErrorToast(
                                          'Location not serviceable');

                                      isBottomSheetOpen = false;
                                      return;
                                    }
                                  }
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(20))),
                                    builder: (context) =>
                                        AddressDetailsBottomSheet(
                                      addressDetails: widget.addressDetails,
                                    ),
                                  );
                                  isBottomSheetOpen =
                                      false; // Reset flag when bottom sheet is dismissed
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 65, 88, 108),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Add more address details',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontSize: 18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.01,
                    left: 16.0,
                    right: 16.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Consumer(
                                    builder: (context, ref, child) {
                                      return TextField(
                                        controller: _searchController,
                                        readOnly:
                                            true, // Prevent keyboard from appearing
                                        onTap: () async {
                                          final selectedSuggestion =
                                              await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const PlaceSuggestionPage(),
                                            ),
                                          );

                                          if (selectedSuggestion != null) {
                                            final placeId =
                                                selectedSuggestion['placeId'];
                                            final description =
                                                selectedSuggestion[
                                                    'description'];

                                            // Update text field with selected address
                                            _searchController.text =
                                                description;

                                            // Navigate map camera to selected place
                                            final LatLng? position =
                                                await LocationHelper
                                                    .searchLocation(placeId);

                                            if (position != null) {
                                              final controller = ref
                                                  .read(mapControllerProvider);
                                              controller?.animateCamera(
                                                CameraUpdate.newCameraPosition(
                                                  CameraPosition(
                                                      target: position,
                                                      zoom: 18.0),
                                                ),
                                              );

                                              // Update providers with selected address details
                                              final address =
                                                  await LocationHelper
                                                      .getAddressFromLatLng(
                                                          position);
                                              ref
                                                  .read(
                                                      addressProviders.notifier)
                                                  .state = address;
                                              ref
                                                  .read(selectedPositionProvider
                                                      .notifier)
                                                  .state = position;
                                            } else {
                                              print(
                                                  "Unable to locate this position");
                                            }
                                          }
                                        },
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 12, horizontal: 12),
                                          hintText: 'Search for location',
                                          hintStyle: GoogleFonts.poppins(
                                              color: Colors.black38,
                                              fontSize: 15),
                                          border: InputBorder.none,
                                          suffixIcon: _searchController
                                                  .text.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear,
                                                      color: Colors.grey),
                                                  onPressed: () {
                                                    _searchController.clear();
                                                    ref
                                                        .read(searchTextProvider
                                                            .notifier)
                                                        .state = '';
                                                    ref
                                                        .read(
                                                            placeSuggestionsProvider
                                                                .notifier)
                                                        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                                                        .state = [];
                                                  },
                                                )
                                              : null,
                                        ),
                                        style:
                                            GoogleFonts.poppins(fontSize: 16),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                ref.watch(isSearchingProvider)
                                    ? const SizedBox(
                                        width: 24.0,
                                        height: 24.0,
                                        child: Center(
                                            child: CupertinoActivityIndicator(
                                          color:
                                              Color.fromARGB(255, 65, 88, 108),
                                        )),
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : const Center(
                child: CupertinoActivityIndicator(
                color: Color.fromARGB(255, 65, 88, 108),
              )),
      ),
    );
  }
}
