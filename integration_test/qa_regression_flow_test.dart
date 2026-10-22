import 'dart:io';
import 'helper_logout_flow_test.dart' as helper;
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'localization_flow_test.dart' as localization;
import 'meetup_community_flow_test.dart' as community;
import 'unicode_message_flow_test.dart' as independent;
import 'account_logout_flow_test.dart' as account;

// Screenshot plumbing only. Existing journeys and assertions are unchanged.
class RegressionScreenshotBinding extends IntegrationTestWidgetsFlutterBinding {
  bool converted = false;
  @override
  Future<void> convertFlutterSurfaceToImage() async {
    if (converted) return;
    await super.convertFlutterSurfaceToImage();
    converted = true;
    addTearDown(() => converted = false);
  }

  @override
  Future<List<int>> takeScreenshot(
    String name, [
    Map<String, Object?>? args,
  ]) async {
    if (Platform.isAndroid) {
      await convertFlutterSurfaceToImage();
      await pump();
    }
    return super.takeScreenshot(
      'regression-${Platform.isAndroid ? 'android' : 'ios'}-$name',
      args,
    );
  }
}

void main() {
  RegressionScreenshotBinding();
  localization.main();
  community.main();
  independent.main();
  account.main();
  helper.main();
}
