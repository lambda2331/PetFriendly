import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';
Future<void> main()=>integrationDriver(onScreenshot:(name,bytes,[args])async{final f=File('/Users/artem.dudinskij/Documents/ChatGPT/PetFriendly/docs/screenshots/studio-review-20261012/$name.png');await f.parent.create(recursive:true);await f.writeAsBytes(bytes);return true;});
