import 'package:escort/constants/app_colors.dart';
import 'package:escort/components/comments/comment-header.dart';
import 'package:escort/components/comments/comment-input.dart';
import 'package:escort/components/comments/comment-list.dart';
import 'package:flutter/material.dart';

class CommentSection extends StatefulWidget {
  final int? postId;
  const CommentSection({super.key, this.postId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  int _refreshTick = 0;

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
                  CommentList(postId: widget.postId, key: ValueKey(_refreshTick)),
                  CommentInput(
                    postId: widget.postId,
                    onSubmitted: () => setState(() => _refreshTick++),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
/// Feature: Advertisers
/// Screen: ReviewsPage
