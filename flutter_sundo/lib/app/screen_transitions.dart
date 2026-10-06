import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../shared/widgets/scenic_backdrop.dart';

const sundoScreenFadeDuration = Duration(milliseconds: 600);

Widget _fadeScreen(BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation, Widget child) =>
    FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeInOutCubic)),
        child: child);

/// Every route paints its own opaque scenery surface. Fading transparent forms
/// alone would expose the root backdrop immediately when Welcome is removed.
CustomTransitionPage<void> sundoScreenPage(
        BuildContext context, GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
        key: state.pageKey,
        transitionDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : sundoScreenFadeDuration,
        reverseTransitionDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : sundoScreenFadeDuration,
        child: ScenicBackdrop(child: child),
        transitionsBuilder: _fadeScreen);

PageRoute<T> sundoScreenRoute<T>(BuildContext context, WidgetBuilder builder) =>
    PageRouteBuilder<T>(
        transitionDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : sundoScreenFadeDuration,
        reverseTransitionDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : sundoScreenFadeDuration,
        pageBuilder: (context, animation, secondaryAnimation) =>
            ScenicBackdrop(child: builder(context)),
        transitionsBuilder: _fadeScreen);
