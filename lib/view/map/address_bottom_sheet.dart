import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/Toast/toast_helper.dart';
import 'package:kealthy/view/address/adress_model.dart';
import 'package:kealthy/view/map/adress_button.dart';
import 'package:kealthy/view/map/provider.dart';

class AddressDetailsBottomSheet extends ConsumerStatefulWidget {
  final AddressDetails? addressDetails;

  const AddressDetailsBottomSheet({
    super.key,
    this.addressDetails,
  });

  @override
  ConsumerState<AddressDetailsBottomSheet> createState() =>
      _AddressDetailsBottomSheetState();
}

class _AddressDetailsBottomSheetState
    extends ConsumerState<AddressDetailsBottomSheet> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController flatRoomAreaController;
  late final TextEditingController landmarkController;
  late final TextEditingController otherInstructionsController;

  @override
  void initState() {
    super.initState();
    final isUpdate = widget.addressDetails?.id != null;

    nameController =
        TextEditingController(text: widget.addressDetails?.name ?? '');
    flatRoomAreaController =
        TextEditingController(text: widget.addressDetails?.flatRoomArea ?? '');
    landmarkController =
        TextEditingController(text: widget.addressDetails?.landmark ?? '');
    otherInstructionsController = TextEditingController(
        text: widget.addressDetails?.otherInstructions ?? '');

    if (isUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedAddressTypeProvider.notifier).state =
            widget.addressDetails!.addressType;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final address = ref.watch(addressProviders);
    final isSaving = ref.watch(addressSaveProvider);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
          child: SafeArea(
        child: Form(
          key: formKey,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete Address Details',
                    style: GoogleFonts.poppins(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3.0,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select address type :',
                            style: GoogleFonts.poppins(
                              color: Colors.black45,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Consumer(
                            builder: (context, ref, child) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  AddressTypeButton(
                                    label: "Home",
                                    icon: Icons.home,
                                    selectedProvider:
                                        selectedAddressTypeProvider,
                                  ),
                                  AddressTypeButton(
                                    label: "Work",
                                    icon: Icons.work,
                                    selectedProvider:
                                        selectedAddressTypeProvider,
                                  ),
                                  AddressTypeButton(
                                    label: "Other",
                                    icon: Icons.location_on,
                                    selectedProvider:
                                        selectedAddressTypeProvider,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(color: Colors.black26),
                            ),
                            child: address != null
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 5),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          // Let the Text expand to fill available space
                                          child: Text(
                                            address,

                                            style: GoogleFonts.poppins(
                                                color: Colors.black45,
                                                fontSize: 13),
                                            // Allow 2 lines
                                            overflow: TextOverflow
                                                .clip, // Truncate if still too long
                                          ),
                                        ),
                                        Flexible(
                                          // Allow button to shrink if needed
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    side: const BorderSide(
                                                        color:
                                                            Colors.black45))),
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text(
                                              'Change',
                                              style: GoogleFonts.poppins(
                                                  color: Colors.black45,
                                                  fontSize: 11),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Text(
                                    'Loading Address...',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black45,
                                    ),
                                  ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Updated based on your map pin',
                            style: GoogleFonts.poppins(
                                color: Colors.black45, fontSize: 11),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: 'Name',
                              hintStyle: GoogleFonts.poppins(),
                              border: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Colors.black),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: flatRoomAreaController,
                            decoration: InputDecoration(
                              hintText: 'Flat / Room / area',
                              hintStyle: GoogleFonts.poppins(),
                              border: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Colors.black),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Address is required'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: landmarkController,
                            decoration: InputDecoration(
                              hintText: 'Landmark (optional)',
                              hintStyle: GoogleFonts.poppins(),
                              border: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Colors.black),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),
                          TextFormField(
                            controller: otherInstructionsController,
                            decoration: InputDecoration(
                              hintText: 'Directions (optional)',
                              hintStyle: GoogleFonts.poppins(),
                              border: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Colors.black),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),
                          // Address Type Selection - Improved layout

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (formKey.currentState!.validate()) {
                                        final selectedType = ref
                                            .read(selectedAddressTypeProvider);
                                        if (selectedType == null) {
                                          ToastHelper.showErrorToast(
                                              'Please select an address type.');
                                          return;
                                        }
                                        final position =
                                            ref.read(selectedPositionProvider);
                                        if (position == null) {
                                          ToastHelper.showErrorToast(
                                              'Please select a location on the map.');
                                          return;
                                        }
                                        final combinedAddress =
                                            '${flatRoomAreaController.text}, ${address ?? ''}';

                                        final details = AddressDetails(
                                          name: nameController.text,
                                          flatRoomArea: combinedAddress,
                                          landmark: landmarkController.text,
                                          otherInstructions:
                                              otherInstructionsController.text,
                                          addressType: selectedType,
                                        );

                                        await saveOrUpdateAddress(
                                          details,
                                          position.latitude,
                                          position.longitude,
                                          selectedType,
                                          widget.addressDetails?.id != null,
                                          widget.addressDetails?.id,
                                          ref,
                                          context,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                alignment: Alignment.center,
                                backgroundColor:
                                    const Color.fromARGB(255, 65, 88, 108),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              child: ref.watch(addressSaveProvider)
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: Center(
                                          child: CupertinoActivityIndicator(
                                        color: Color.fromARGB(255, 65, 88, 108),
                                      )),
                                    )
                                  : Text(
                                      'Save Address',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white, fontSize: 18),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
          ),
        ),
      )),
    );
  }
}
