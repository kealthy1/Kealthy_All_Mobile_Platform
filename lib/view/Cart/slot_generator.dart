// import 'package:ntp/ntp.dart';

// class AvailableSlotsGenerator {
//   final int slotDurationMinutes;

//   AvailableSlotsGenerator({
//     required this.slotDurationMinutes,
//   });

//   Future<List<Map<String, DateTime>>> getAvailableSlots(
//     DateTime startBoundary,
//     DateTime endBoundary,
//     DateTime currentTime,
//     double etaMinutes,
//   ) async {
//     DateTime etaPlusBreak = currentTime;

//     DateTime adjustedStartTime = DateTime(
//       etaPlusBreak.year,
//       etaPlusBreak.month,
//       etaPlusBreak.day,
//       ((etaPlusBreak.hour ~/ 3) + 1) * 3,
//     );

//     if (adjustedStartTime.isBefore(startBoundary)) {
//       adjustedStartTime = startBoundary;
//     }

//     List<Map<String, DateTime>> slots = [];

//     while (adjustedStartTime.isBefore(endBoundary)) {
//       DateTime slotEndTime = adjustedStartTime.add(const Duration(hours: 3));

//       if (slotEndTime.isAfter(endBoundary)) {
//         slotEndTime = endBoundary;
//       }
//       if (adjustedStartTime.difference(currentTime).inMinutes >= 0) {
//         slots.add({"start": adjustedStartTime, "end": slotEndTime});
//       }

//       //slots.add({"start": adjustedStartTime, "end": slotEndTime});

//       adjustedStartTime = slotEndTime;
//     }

//     return slots;
//   }

//   Future<Map<String, dynamic>> getSlots(double etaMinutes) async {
//     DateTime currentTime = await NTP.now();

//     DateTime todayStartBoundary = DateTime(
//       currentTime.year,
//       currentTime.month,
//       currentTime.day,
//       9,
//     );

//     DateTime todayEndBoundary = DateTime(
//       currentTime.year,
//       currentTime.month,
//       currentTime.day,
//       18,
//     );

//     DateTime tomorrowStartBoundary = DateTime(
//       currentTime.year,
//       currentTime.month,
//       currentTime.day + 1,
//       9,
//     );

//     DateTime tomorrowEndBoundary = DateTime(
//       currentTime.year,
//       currentTime.month,
//       currentTime.day + 1,
//       18,
//     );

//     List<Map<String, DateTime>> todaySlots = [];
//     List<Map<String, DateTime>> tomorrowSlots = [];

//     if (currentTime.isBefore(todayEndBoundary)) {
//       todaySlots = await getAvailableSlots(
//         todayStartBoundary,
//         todayEndBoundary,
//         currentTime,
//         etaMinutes,
//       );
//     }

//     tomorrowSlots = await getAvailableSlots(
//       tomorrowStartBoundary,
//       tomorrowEndBoundary,
//       currentTime,
//       etaMinutes,
//     );

//     return {
//       "slots": [...todaySlots, ...tomorrowSlots],
//     };
//   }
// }
