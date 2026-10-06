import 'package:flutter/material.dart';

/// Wait for the closing animation before callers release editor controllers.
Future<T?> showSundoEditorDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  TransitionRoute<dynamic>? route;
  final result = await showDialog<T>(
      context: context,
      builder: (context) {
        route = ModalRoute.of(context);
        return builder(context);
      });
  if (route != null) await route!.completed;
  return result;
}

Future<T?> showSundoEditorSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useSafeArea = true,
}) async {
  TransitionRoute<dynamic>? route;
  final result = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      builder: (context) {
        route = ModalRoute.of(context);
        return builder(context);
      });
  if (route != null) await route!.completed;
  return result;
}
