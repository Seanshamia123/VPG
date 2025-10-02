/// Feature: Messages
/// Widget: PlaceholderWidget
///
/// Simple placeholder for empty/message entry states.
import 'package:escort/styles/app_size.dart';
import 'package:flutter/material.dart';
import 'package:escort/device_utility/device_checker.dart';

class PlaceholderWidget extends StatelessWidget {
  const PlaceholderWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyle = context.textStyle;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.send, size: 100, color: colorScheme.primary),
          SizedBox(height: Insets.med),
          Text(
            'Your Messages',
            style: textStyle.titleMdMedium.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Insets.sm),
          Text(
            'Send private photos and messages to a friend or group.',
            style: textStyle.bodyMdMedium.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Insets.med),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Sizes.buttonRadius),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: Insets.xl,
                vertical: Insets.sm,
              ),
            ),
            child: Text(
              'Send Message',
              style: textStyle.bodyMdMedium.copyWith(
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
