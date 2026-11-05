import 'backend/backend.dart';

/// Keep the native display convention; the English portfolio uses a decimal dot.
String displayDecimal(double value) {
  final text = value.toStringAsFixed(1);
  return AppConfig.portfolio ? text : text.replaceAll('.', ',');
}
