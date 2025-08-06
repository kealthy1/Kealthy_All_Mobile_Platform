import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

// Define the app link as a provider
final appLinkProvider = Provider<String>((ref) {
  return 'https://apps.apple.com/app/kealthy/id6740621148'; // Replace with your app's actual link
});

class ShareAppButton extends ConsumerWidget {
  const ShareAppButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLink = ref.watch(appLinkProvider);

    return IconButton(
     
      onPressed: () {
        Share.share(
          'Check out Kealthy app: $appLink',
          subject: 'Check out Kealthy app!',
        );
      },
      icon: const Icon(Icons.ios_share_outlined, color: Colors.black,size: 22,),
      
    );
  }
}