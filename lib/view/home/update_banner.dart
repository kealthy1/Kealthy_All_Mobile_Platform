import 'package:flutter/material.dart';
class UpdateBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const UpdateBanner({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.yellow[100],
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.system_update, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'A new version of Kealthy is available. Tap to update!',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
