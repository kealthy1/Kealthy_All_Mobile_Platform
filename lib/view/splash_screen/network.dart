import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class InternetAwareWidget extends StatelessWidget {
  final Widget child;

  const InternetAwareWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final results = snapshot.data ?? [];
        final isOffline = results.contains(ConnectivityResult.none);

        return Stack(
          children: [
            child,
            if (isOffline)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    color: Colors.redAccent,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'You are offline',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}




//-------------x--------x----------------x------------------


// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';

// class InternetAwareWidget extends StatelessWidget {
//   final Widget child;

//   const InternetAwareWidget({super.key, required this.child});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<ConnectivityResult>(
//       stream:
//           Connectivity().onConnectivityChanged.map((results) => results.first),
//       builder: (context, snapshot) {
//         // If the snapshot has no data yet (still waiting), we can assume connected or just not show the banner
//         final connectivityResult = snapshot.data;

//         // We'll consider "offline" when the result is explicitly 'none'
//         final isOffline = (connectivityResult == ConnectivityResult.none);

//         // Use a Stack to show the main child plus an optional banner if offline
//         return Stack(
//           children: [
//             // Main content
//             child,

//             // Show an offline banner if we're offline
//             if (isOffline)
//               Positioned(
//                 bottom: 0,
//                 left: 0,
//                 right: 0,
//                 child: Container(
//                   color: Colors.redAccent,
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text(
//                     'You are offline',
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.poppins(
//                       color: Colors.white,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         );
//       },
//     );
//   }
// }
