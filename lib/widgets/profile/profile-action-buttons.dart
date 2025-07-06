import 'package:flutter/material.dart';
import 'package:escort/styles/app_size.dart';

class ProfileActionButtons extends StatelessWidget {
  final VoidCallback onPayPressed;
  final VoidCallback onMessagePressed;

  const ProfileActionButtons({
    super.key,
    required this.onPayPressed,
    required this.onMessagePressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: onPayPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Sizes.buttonRadius + 5),
              ),
            ),
            child: const Text("Pay \$1000"),
          ),

          ///we are removing this the  pay
          SizedBox(width: Sizes.spaceBtwItems),
          ElevatedButton(
            onPressed: onMessagePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Sizes.buttonRadius + 5),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Message"),
                SizedBox(width: 8),
                Icon(Icons.chat_bubble_outline_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
