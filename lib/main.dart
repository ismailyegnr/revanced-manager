import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:revanced_manager/app/app.locator.dart';
import 'package:revanced_manager/services/github_api.dart';
import 'package:revanced_manager/services/manager_api.dart';
import 'package:revanced_manager/services/patcher_api.dart';
import 'package:revanced_manager/services/revanced_api.dart';
import 'package:revanced_manager/ui/theme/dynamic_theme_builder.dart';
import 'package:revanced_manager/ui/views/navigation/navigation_view.dart';
import 'package:revanced_manager/utils/env_class.dart';
import 'package:stacked_themes/stacked_themes.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future main() async {
  await ThemeManager.initialise();
  await setupLocator();
  WidgetsFlutterBinding.ensureInitialized();
  await locator<ManagerAPI>().initialize();
  String apiUrl = locator<ManagerAPI>().getApiUrl();
  await locator<RevancedAPI>().initialize(apiUrl);
  bool isSentryEnabled = locator<ManagerAPI>().isSentryEnabled();
  bool isCrashlyticsEnabled = locator<ManagerAPI>().isCrashlyticsEnabled();
  // Remove this line if you are building from source and don't have firebase config
  if (isCrashlyticsEnabled) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Firebase.app().setAutomaticDataCollectionEnabled(true);
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Firebase.app().setAutomaticDataCollectionEnabled(false);
  locator<GithubAPI>().initialize();
  await locator<PatcherAPI>().initialize();
  tz.initializeTimeZones();

  // Remove this line if you are building from source and don't have sentry configured
  await SentryFlutter.init(
    (options) {
      options
        ..dsn = isSentryEnabled ? Env.sentry_dsn : ''
        ..environment = 'alpha'
        ..release = '0.1'
        ..tracesSampleRate = 1.0
        ..anrEnabled = true
        ..enableOutOfMemoryTracking = true
        ..sampleRate = isSentryEnabled ? 1.0 : 0.0
        ..beforeSend = (event, hint) {
          print('isSentryEnabled: $isSentryEnabled');
          if (isSentryEnabled) {
            print("Sentry event sent");
            return event;
          } else {
            print("Sentry is disabled");
            return null;
          }
        } as BeforeSendCallback?;
    },
    appRunner: () {
      // Pass all uncaught errors from the framework to Crashlytics.
      if (isCrashlyticsEnabled) {
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
      }
      runApp(const MyApp());
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DynamicThemeBuilder(
      title: 'ReVanced Manager',
      home: const NavigationView(),
      localizationsDelegates: [
        FlutterI18nDelegate(
          translationLoader: FileTranslationLoader(
            fallbackFile: 'en_US',
            basePath: 'assets/i18n',
          ),
        ),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
    );
  }
}
