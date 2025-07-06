import '../../constants/app_colors.dart';
import 'package:flutter/material.dart';

class CommentHeader extends StatelessWidget {
  const CommentHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 16.0 : 24.0;
    final titleFontSize = screenWidth < 600 ? 20.0 : 24.0;

    return Container(
      padding: EdgeInsets.all(horizontalPadding),
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {}, // to the user and advestiser pages
            icon: const Icon(Icons.arrow_back_ios_rounded),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Comments',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.more_horiz, color: AppColors.darkBackgroundColor),
              const SizedBox(width: 8),
              Text(
                '2.4k comments',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
