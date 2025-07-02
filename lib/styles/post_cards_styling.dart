import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String imageUrl;
  final VoidCallback? onTap;

  const PostCard({super.key, required this.imageUrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Stack(
              children: [
                Container(color: Colors.grey[200]),
                Center(child: CircularProgressIndicator()),
              ],
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Center(child: Icon(Icons.error)),
            );
          },
        ),
      ),
    );
  }
}
