import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
// Fixture journeys only. Real local-account journeys run in separate app processes.
// The visual audit includes Review 60; wrapper entry points are not registered twice.
import 'localization_flow_test.dart' as s0;
import 'meetup_studio_flow_test.dart' as s1;
import 'meetup_community_flow_test.dart' as s2;
import 'onboarding_studio_flow_test.dart' as s3;
import 'unicode_message_flow_test.dart' as s4;
import 'people_studio_flow_test.dart' as s5;
import 'chat_profile_studio_flow_test.dart' as s6;
import 'walks_studio_flow_test.dart' as s7;
import 'personal_walking_flow_test.dart' as s8;
import 'nearby_studio_parity_test.dart' as s9;
import 'simulator_visual_audit_test.dart' as s10;
import 'nearby_location_flow_test.dart' as s11;
import 'event_location_flow_test.dart' as s12;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUp(binding.platformDispatcher.clearTextScaleFactorTestValue);
  tearDown(binding.platformDispatcher.clearTextScaleFactorTestValue);
  s0.main();
  s1.main();
  s2.main();
  s3.main();
  s4.main();
  s5.main();
  s6.main();
  s7.main();
  s8.main();
  s9.main();
  s10.main();
  s11.main();
  s12.main();
}
