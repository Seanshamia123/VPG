import 'package:escort/constants/app_colors.dart';
import 'package:escort/widgets/comments/comment-header.dart';
import 'package:escort/widgets/comments/comment-input.dart';
import 'package:escort/widgets/comments/comment-list.dart';
import 'package:flutter/material.dart';

class CommentSection extends StatelessWidget {
  const CommentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final verticalPadding = screenWidth < 600 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  SizedBox(height: verticalPadding),
                  const CommentHeader(),
                  const CommentList(),
                  const CommentInput(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
