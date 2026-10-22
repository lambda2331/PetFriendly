import 'package:integration_test/integration_test.dart';
import '../test/walking_chat_flow_test.dart' as walking;
import '../test/helper_account_mode_test.dart' as helper;

// Run current widget journeys on a native engine, without restoring old UI.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  walking.main();
  helper.main();
}
