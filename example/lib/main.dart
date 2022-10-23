import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  bool _loadingVersions = false;
  NewVersionPlusFields? _androidVersion;
  NewVersionPlusFields? _iosVersion;

  @override
  void initState() {
    super.initState();

    // Instantiate NewVersion manager object (Using GCP Console app as example)
    final newVersion = NewVersionPlus(
      iOSId: 'com.google.Vespa',
      androidId: 'com.google.android.apps.cloudconsole',
    );

    // You can let the plugin handle fetching the status and showing a dialog,
    // or you can fetch the status and display your own dialog, or no dialog.
    const simpleBehavior = true;

    if (simpleBehavior) {
      basicStatusCheck(newVersion);
    // } else {
    //   advancedStatusCheck(newVersion);
    }

    printAllPlatforms();
  }

  basicStatusCheck(NewVersionPlus newVersion) {
    newVersion.showAlertIfNecessary(context: context);
  }

  advancedStatusCheck(NewVersionPlus newVersion) async {
    final status = await newVersion.getVersionStatus();
    if (status != null) {
      debugPrint(status.releaseNotes);
      debugPrint(status.appStoreLink);
      debugPrint(status.localVersion);
      debugPrint(status.storeVersion);
      debugPrint(status.canUpdate.toString());
      newVersion.showUpdateDialog(
        context: context,
        versionStatus: status,
        dialogTitle: 'Custom Title',
        dialogText: 'Custom Text',
      );
    }
  }

  printAllPlatforms() async {
    setState(() => _loadingVersions = true);

    try {
      _androidVersion = await NewVersionPlus()
          .getAndroidStoreVersion('com.google.android.apps.cloudconsole');
      debugPrint("Android version: ${_androidVersion?.version}");
    } catch (e, s) {
      debugPrint(e.toString());
      if (kDebugMode) print(s);
    }

    try {
      _iosVersion =
          await NewVersionPlus().getiOSStoreVersion('com.google.Vespa');
      debugPrint("iOS version: ${_iosVersion?.version}");
    } catch (e, s) {
      debugPrint(e.toString());
      if (kDebugMode) print(s);
    }

    setState(() => _loadingVersions = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Example App"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: _loadingVersions
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Text(
                          "Android version: ${_androidVersion?.version}",
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          _androidVersion?.releaseNotes ?? "",
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "iOS version: ${_iosVersion?.version}",
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          _iosVersion?.releaseNotes ?? "",
                          textAlign: TextAlign.center,
                        ),
                      ]),
          ),
        ));
  }
}
