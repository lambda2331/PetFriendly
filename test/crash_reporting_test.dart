import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/diagnostics/crash_reporting.dart';

void main() {
  test('Diagnostic category excludes private exception messages', () {
    final error = StateError('fixture-token: PRIVATE_MESSAGE /private/address');
    expect(sanitizedErrorType(error), 'StateError');
    expect(sanitizedErrorType(error), isNot(contains('PRIVATE')));
  });
}
