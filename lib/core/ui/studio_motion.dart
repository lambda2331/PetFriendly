import 'package:flutter/material.dart';

/// Shared timing and platform accessibility policy; no animation dependency.
abstract final class StudioMotion {
  static const tap = Duration(milliseconds: 100);
  static const tab = Duration(milliseconds: 180);
  static const navigation = Duration(milliseconds: 220);
  static const sheet = Duration(milliseconds: 250);

  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      WidgetsBinding
          .instance
          .platformDispatcher
          .accessibilityFeatures
          .reduceMotion;

  static Duration duration(BuildContext context, Duration value) =>
      reduced(context) ? Duration.zero : value;
}
