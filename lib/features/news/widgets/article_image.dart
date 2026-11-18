import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ArticleImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double placeholderIconSize;

  const ArticleImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholderIconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return _placeholder();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: fit,
      placeholder: (_, _) => _placeholder(),
      errorWidget: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: placeholderIconSize,
        color: Colors.grey,
      ),
    );
  }
}
