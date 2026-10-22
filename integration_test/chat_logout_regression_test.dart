import 'qa_regression_flow_test.dart' show RegressionScreenshotBinding;
import 'unicode_message_flow_test.dart' as chat;
import 'helper_logout_flow_test.dart' as helper;

void main() {
  RegressionScreenshotBinding();
  chat.main();
  helper.main();
}
