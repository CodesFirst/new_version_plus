library new_version_plus;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Information about the app's current version, and the most recent version
/// available in the Apple App Store or Google Play Store.
class VersionStatus {
  /// The current version of the app.
  final String localVersion;

  /// The most recent version of the app in the store.
  final String storeVersion;

  /// The most recent version of the app in the store.
  final String? originalStoreVersion;

  /// A link to the app store page where the app can be updated.
  final String appStoreLink;

  /// The release notes for the store version of the app.
  final String? releaseNotes;

  /// Returns `true` if the store version of the application is greater than the local version.
  bool get canUpdate {
    final local = localVersion.split('.').map(int.parse).toList();
    final store = storeVersion.split('.').map(int.parse).toList();

    // Each consecutive field in the version notation is less significant than the previous one,
    // therefore only one comparison needs to yield `true` for it to be determined that the store
    // version is greater than the local version.
    for (var i = 0; i < store.length; i++) {
      // The store version field is newer than the local version.
      if (store[i] > local[i]) {
        return true;
      }

      // The local version field is newer than the store version.
      if (local[i] > store[i]) {
        return false;
      }
    }

    // The local and store versions are the same.
    return false;
  }

  //Public Contructor
  VersionStatus({
    required this.localVersion,
    required this.storeVersion,
    required this.appStoreLink,
    this.releaseNotes,
    this.originalStoreVersion,
  });

  VersionStatus._({
    required this.localVersion,
    required this.storeVersion,
    required this.appStoreLink,
    this.releaseNotes,
    this.originalStoreVersion,
  });
}

class NewVersionPlus {
  /// An optional value that can override the default packageName when
  /// attempting to reach the Apple App Store. This is useful if your app has
  /// a different package name in the App Store.
  final String? iOSId;

  /// An optional value that can override the default packageName when
  /// attempting to reach the Google Play Store. This is useful if your app has
  /// a different package name in the Play Store.
  final String? androidId;

  /// Only affects iOS App Store lookup: The two-letter country code for the store you want to search.
  /// Provide a value here if your app is only available outside the US.
  /// For example: US. The default is US.
  /// See http://en.wikipedia.org/wiki/ ISO_3166-1_alpha-2 for a list of ISO Country Codes.
  final String? iOSAppStoreCountry;

  /// Only affects Android Play Store lookup: The two-letter country code for the store you want to search.
  /// Provide a value here if your app is only available outside the US.
  /// For example: US. The default is US.
  /// See http://en.wikipedia.org/wiki/ ISO_3166-1_alpha-2 for a list of ISO Country Codes.
  /// see https://www.ibm.com/docs/en/radfws/9.6.1?topic=overview-locales-code-pages-supported
  final String? androidPlayStoreCountry;

  /// An optional value that will force the plugin to always return [forceAppVersion]
  /// as the value of [storeVersion]. This can be useful to test the plugin's behavior
  /// before publishng a new version.
  final String? forceAppVersion;

  //Html original body request
  final bool androidHtmlReleaseNotes;

  NewVersionPlus({
    this.androidId,
    this.iOSId,
    this.iOSAppStoreCountry,
    this.forceAppVersion,
    this.androidPlayStoreCountry,
    this.androidHtmlReleaseNotes = false,
  });

  /// This checks the version status, then displays a platform-specific alert
  /// with buttons to dismiss the update alert, or go to the app store.
  showAlertIfNecessary({
    required BuildContext context,
    LaunchModeVersion launchModeVersion = LaunchModeVersion.normal,
  }) async {
    final VersionStatus? versionStatus = await getVersionStatus();

    if (versionStatus != null && versionStatus.canUpdate) {
      // ignore: use_build_context_synchronously
      showUpdateDialog(
        context: context,
        versionStatus: versionStatus,
        launchModeVersion: launchModeVersion,
      );
    }
  }

  /// This checks the version status and returns the information. This is useful
  /// if you want to display a custom alert, or use the information in a different
  /// way.
  Future<VersionStatus?> getVersionStatus() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (Platform.isIOS) {
      return _getiOSStoreVersion(packageInfo);
    } else if (Platform.isAndroid) {
      return _getAndroidStoreVersion(packageInfo);
    } else {
      debugPrint(
          'The target platform "${Platform.operatingSystem}" is not yet supported by this package.');
      return null;
    }
  }

  /// This function attempts to clean local version strings so they match the MAJOR.MINOR.PATCH
  /// versioning pattern, so they can be properly compared with the store version.
  String _getCleanVersion(String version) =>
      RegExp(r'\d+\.\d+(\.\d+)?').stringMatch(version) ?? '0.0.0';
  //RegExp(r'\d+\.\d+(\.[a-z]+)?(\.([^"]|\\")*)?').stringMatch(version) ?? '0.0.0';

  /// iOS info is fetched by using the iTunes lookup API, which returns a
  /// JSON document.
  Future<VersionStatus?> _getiOSStoreVersion(PackageInfo packageInfo) async {
    final id = iOSId ?? packageInfo.packageName;
    Map<String, dynamic> parameters = {};

    /// programmermager:fix/issue-35-ios-failed-host-lookup
    if (id.contains('.')) {
      parameters['bundleId'] = id;
    } else {
      parameters['id'] = id;
    }

    parameters['timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();

    if (iOSAppStoreCountry != null) {
      parameters.addAll({"country": iOSAppStoreCountry!});
    }
    var uri = Uri.https("itunes.apple.com", "/lookup", parameters);
    http.Response response;
    try {
      response = await http.get(uri);
    } catch (e) {
      debugPrint('Failed to query iOS App Store\n$e');
      return null;
    }
    if (response.statusCode != 200) {
      debugPrint('Failed to query iOS App Store');
      return null;
    }
    final jsonObj = json.decode(response.body);
    final List results = jsonObj['results'];
    if (results.isEmpty) {
      debugPrint('Can\'t find an app in the App Store with the id: $id');
      return null;
    }
    return VersionStatus._(
      localVersion: _getCleanVersion(packageInfo.version),
      storeVersion:
          _getCleanVersion(forceAppVersion ?? jsonObj['results'][0]['version']),
      originalStoreVersion: forceAppVersion ?? jsonObj['results'][0]['version'],
      appStoreLink: jsonObj['results'][0]['trackViewUrl'],
      releaseNotes: jsonObj['results'][0]['releaseNotes'],
    );
  }

  /// Android info is fetched by parsing the html of the app store page.
  Future<VersionStatus?> _getAndroidStoreVersion(
      PackageInfo packageInfo) async {
    final id = androidId ?? packageInfo.packageName;
    final uri = Uri.https("play.google.com", "/store/apps/details", {
      "id": id.toString(),
      "hl": androidPlayStoreCountry ?? "en_US",
      "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
    });
    http.Response response;
    try {
      response = await http.get(uri);
    } catch (e) {
      debugPrint('Failed to query Google Play Store\n$e');
      return null;
    }
    if (response.statusCode != 200) {
      throw Exception("Invalid response code: ${response.statusCode}");
    }
    // Supports 1.2.3 (most of the apps) and 1.2.prod.3 (e.g. Google Cloud)
    //final regexp = RegExp(r'\[\[\["(\d+\.\d+(\.[a-z]+)?\.\d+)"\]\]');
    final regexp =
        RegExp(r'\[\[\[\"(\d+\.\d+(\.[a-z]+)?(\.([^"]|\\")*)?)\"\]\]');
    final storeVersion = regexp.firstMatch(response.body)?.group(1);

    //Description
    //final regexpDescription = RegExp(r'\[\[(null,)\"((\.[a-z]+)?(([^"]|\\")*)?)\"\]\]');

    //Release
    final regexpRelease =
        RegExp(r'\[(null,)\[(null,)\"((\.[a-z]+)?(([^"]|\\")*)?)\"\]\]');

    final expRemoveSc = RegExp(r"\\u003c[A-Za-z]{1,10}\\u003e",
        multiLine: true, caseSensitive: true);

    final expRemoveQuote =
        RegExp(r"\\u0026quot;", multiLine: true, caseSensitive: true);

    final releaseNotes = regexpRelease.firstMatch(response.body)?.group(3);
    //final descriptionNotes = regexpDescription.firstMatch(response.body)?.group(2);

    return VersionStatus._(
      localVersion: _getCleanVersion(packageInfo.version),
      storeVersion: _getCleanVersion(forceAppVersion ?? storeVersion ?? ""),
      originalStoreVersion: forceAppVersion ?? storeVersion ?? "",
      appStoreLink: uri.toString(),
      releaseNotes: androidHtmlReleaseNotes
          ? _parseUnicodeToString(releaseNotes)
          : releaseNotes
              ?.replaceAll(expRemoveSc, '')
              .replaceAll(expRemoveQuote, '"'),
    );
  }

  /// Update action fun
  /// show modal
  void _updateActionFunc({
    required String appStoreLink,
    required bool allowDismissal,
    required BuildContext context,
    LaunchMode launchMode = LaunchMode.platformDefault,
  }) {
    launchAppStore(
      appStoreLink,
      launchMode: launchMode,
    );
    if (allowDismissal) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  /// Shows the user a platform-specific alert about the app update. The user
  /// can dismiss the alert or proceed to the app store.
  ///
  /// To change the appearance and behavior of the update dialog, you can
  /// optionally provide [dialogTitle], [dialogText], [updateButtonText],
  /// [dismissButtonText], and [dismissAction] parameters.
  void showUpdateDialog({
    required BuildContext context,
    required VersionStatus versionStatus,
    String dialogTitle = 'Update Available',
    String? dialogText,
    String updateButtonText = 'Update',
    bool allowDismissal = true,
    String dismissButtonText = 'Maybe Later',
    VoidCallback? dismissAction,
    LaunchModeVersion launchModeVersion = LaunchModeVersion.normal,
  }) async {
    final dialogTitleWidget = Text(dialogTitle);
    final dialogTextWidget = Text(
      dialogText ??
          'You can now update this app from ${versionStatus.localVersion} to ${versionStatus.storeVersion}',
    );

    final launchMode = launchModeVersion == LaunchModeVersion.external
        ? LaunchMode.externalApplication
        : LaunchMode.platformDefault;

    final updateButtonTextWidget = Text(updateButtonText);

    List<Widget> actions = [
      Platform.isAndroid
          ? TextButton(
              onPressed: () => _updateActionFunc(
                allowDismissal: allowDismissal,
                context: context,
                appStoreLink: versionStatus.appStoreLink,
                launchMode: launchMode,
              ),
              child: updateButtonTextWidget,
            )
          : CupertinoDialogAction(
              onPressed: () => _updateActionFunc(
                allowDismissal: allowDismissal,
                context: context,
                appStoreLink: versionStatus.appStoreLink,
                launchMode: launchMode,
              ),
              child: updateButtonTextWidget,
            ),
    ];

    if (allowDismissal) {
      final dismissButtonTextWidget = Text(dismissButtonText);
      dismissAction = dismissAction ??
          () => Navigator.of(context, rootNavigator: true).pop();
      actions.add(
        Platform.isAndroid
            ? TextButton(
                onPressed: dismissAction,
                child: dismissButtonTextWidget,
              )
            : CupertinoDialogAction(
                onPressed: dismissAction,
                child: dismissButtonTextWidget,
              ),
      );
    }

    await showDialog(
      context: context,
      barrierDismissible: allowDismissal,
      builder: (BuildContext context) {
        return WillPopScope(
            child: Platform.isAndroid
                ? AlertDialog(
                    title: dialogTitleWidget,
                    content: dialogTextWidget,
                    actions: actions,
                  )
                : CupertinoAlertDialog(
                    title: dialogTitleWidget,
                    content: dialogTextWidget,
                    actions: actions,
                  ),
            onWillPop: () => Future.value(allowDismissal));
      },
    );
  }

  /// Launches the Apple App Store or Google Play Store page for the app.
  Future<void> launchAppStore(
    String appStoreLink, {
    LaunchMode launchMode = LaunchMode.platformDefault,
  }) async {
    if (await canLaunchUrl(Uri.parse(appStoreLink))) {
      await launchUrl(
        Uri.parse(appStoreLink),
        mode: launchMode,
      );
    } else {
      throw 'Could not launch appStoreLink';
    }
  }

  /// Function for convert text
  /// _parseUnicodeToString
  String? _parseUnicodeToString(String? release) {
    try {
      if (release == null || release.isEmpty) return release;

      final re = RegExp(
        r'(%(?<asciiValue>[0-9A-Fa-f]{2}))'
        r'|(\\u(?<codePoint>[0-9A-Fa-f]{4}))'
        r'|.',
      );

      var matches = re.allMatches(release);
      var codePoints = <int>[];
      for (var match in matches) {
        var codePoint =
            match.namedGroup('asciiValue') ?? match.namedGroup('codePoint');
        if (codePoint != null) {
          codePoints.add(int.parse(codePoint, radix: 16));
        } else {
          codePoints += match.group(0)!.runes.toList();
        }
      }
      var decoded = String.fromCharCodes(codePoints);
      return decoded;
    } catch (e) {
      return release;
    }
  }
}

enum LaunchModeVersion { normal, external }
