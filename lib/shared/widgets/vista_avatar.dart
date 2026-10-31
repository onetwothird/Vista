import 'package:flutter/material.dart';
import 'package:seelai_app/themes/palette.dart';

/// Decodes a network image at the size it is drawn instead of full
/// resolution. Profile photos from Cloudinary are often 2–4 MP; decoding
/// them full size for a 48px circle is a common source of scroll jank.
ImageProvider resizedNetworkImage(
  String url,
  BuildContext context,
  double logicalSize,
) {
  final px = (logicalSize * MediaQuery.devicePixelRatioOf(context)).round();
  return ResizeImage(
    NetworkImage(url),
    width: px,
    policy: ResizeImagePolicy.fit,
  );
}

/// Circular profile photo with an initial-letter fallback.
class VistaAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool isDarkMode;

  const VistaAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    this.size = 48,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final fallback = Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: isDarkMode ? Palette.nightText : Palette.violetDeep,
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDarkMode ? Palette.violetTintNight : Palette.violetTint,
        border: Border.all(color: Palette.border(isDarkMode)),
      ),
      child: url == null || url.isEmpty
          ? fallback
          : Image(
              image: resizedNetworkImage(url, context, size),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}
