# flutter_mdns_plugin

A simple plugin for discovering mdns services in Flutter on Android and iOS. The example project is set to discover Chromecasts only, but you can set any mdns service by changing the `discovery_service` string in `device_scanner.dart`.

**iOS installation**
Make sure you add the Foundation framework to your iOS project in xcode.

**Android installation**
No installation required. Just make sure the permission `android.permission.INTERNET` is added in your `AndroidManifest.xml`, but that should be automatically set when creating a new Flutter project.

Most of the code for Android came from this repository:
https://github.com/platinumjam/flutter_mdns

Most of the code for iOS came from this resource:
https://www.eventbrite.com/engineering/bonjour-gatekeeper-how-to-implement-bonjour-service-in-an-ios-or-android-app/
