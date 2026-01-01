import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class FeatureItem extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String desc;

  const FeatureItem({
    super.key,
    required this.iconAsset,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SvgPicture.asset(
              iconAsset,
              width: 26,
              height: 26,
              colorFilter: const ColorFilter.mode(
                Colors.deepPurple,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Colors.deepPurple,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          desc,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
