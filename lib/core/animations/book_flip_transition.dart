import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

class BookFlipTransition extends CustomTransitionPage<void> {
  BookFlipTransition({
    required LocalKey super.key,
    required super.child,
    Duration duration = const Duration(milliseconds: 600),
  }) : super(
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return AnimatedBuilder(
             animation: animation,
             builder: (context, child) {
               // The animation value goes from 0.0 to 1.0
               final rotateAnim = animation.value;

               return Stack(
                 children: [
                   // New page entering
                   Transform(
                     alignment: Alignment.centerLeft,
                     transform: Matrix4.identity()
                       ..setEntry(3, 2, 0.001) // Perspective
                       ..rotateY(
                         (1 - rotateAnim) * math.pi / 2,
                       ), // Rotate from 90 to 0 degrees
                     child: Opacity(
                       opacity: rotateAnim.clamp(0.0, 1.0),
                       child: child,
                     ),
                   ),
                 ],
               );
             },
             child: child,
           );
         },
       );
}

/// A more advanced version that shows the current page "closing" while the new one "opens"
class RealBookFlipTransition extends CustomTransitionPage<void> {
  RealBookFlipTransition({
    required LocalKey super.key,
    required super.child,
    Duration duration = const Duration(milliseconds: 800),
  }) : super(
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // Animation: 0.0 -> 1.0
           // When navigating forward:
           // animation is for the NEW page
           // secondaryAnimation is for the CURRENT page (if another one is pushed on top)

           return Stack(
             children: [
               // Incoming Page (The page we are going to)
               SlideTransition(
                 // Slightly slide in to avoid total overlap during rotation
                 position:
                     Tween<Offset>(
                       begin: const Offset(0.2, 0),
                       end: Offset.zero,
                     ).animate(
                       CurvedAnimation(
                         parent: animation,
                         curve: Curves.easeOutCubic,
                       ),
                     ),
                 child: Transform(
                   alignment: Alignment.centerLeft,
                   transform: Matrix4.identity()
                     ..setEntry(3, 2, 0.0015) // Perspective
                     ..rotateY((1 - animation.value) * math.pi / 2),
                   child: Opacity(
                     opacity: animation.value > 0.5 ? 1.0 : animation.value * 2,
                     child: child,
                   ),
                 ),
               ),
             ],
           );
         },
       );
}
