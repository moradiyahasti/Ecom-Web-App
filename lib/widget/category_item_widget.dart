

import 'package:demo/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryItem extends StatelessWidget {
  final String title;
  final IconData icon;

  const CategoryItem(this.title, this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.bgRight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class CategoryItem extends StatefulWidget {
//   final String name;
//   final IconData icon;

//   const CategoryItem(this.name, this.icon, {super.key});

//   @override
//   State<CategoryItem> createState() => _CategoryItemState();
// }

// class _CategoryItemState extends State<CategoryItem> 
//     with SingleTickerProviderStateMixin {
  
//   late AnimationController _controller;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _rotateAnimation;
//   bool _isHovered = false;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 200),
//       vsync: this,
//     );

//     _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//     );

//     _rotateAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MouseRegion(
//       onEnter: (_) {
//         setState(() => _isHovered = true);
//         _controller.forward();
//       },
//       onExit: (_) {
//         setState(() => _isHovered = false);
//         _controller.reverse();
//       },
//       child: GestureDetector(
//         onTap: () {
//           // Add navigation logic
//         },
//         child: ScaleTransition(
//           scale: _scaleAnimation,
//           child: RotationTransition(
//             turns: _rotateAnimation,
//             child: Container(
//               margin: const EdgeInsets.symmetric(horizontal: 8),
//               width: 100,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   AnimatedContainer(
//                     duration: const Duration(milliseconds: 200),
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       gradient: _isHovered
//                           ? LinearGradient(
//                               colors: [
//                                 Colors.deepPurple.shade400,
//                                 Colors.deepPurple.shade600,
//                               ],
//                             )
//                           : LinearGradient(
//                               colors: [
//                                 Colors.deepPurple.shade50,
//                                 Colors.purple.shade50,
//                               ],
//                             ),
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(
//                           color: _isHovered 
//                               ? Colors.deepPurple.withOpacity(0.3)
//                               : Colors.black.withOpacity(0.05),
//                           blurRadius: _isHovered ? 15 : 8,
//                           offset: Offset(0, _isHovered ? 6 : 3),
//                         ),
//                       ],
//                     ),
//                     child: Icon(
//                       widget.icon,
//                       size: 32,
//                       color: _isHovered ? Colors.white : Colors.deepPurple,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     widget.name,
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.poppins(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: _isHovered 
//                           ? Colors.deepPurple.shade700 
//                           : Colors.black87,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }