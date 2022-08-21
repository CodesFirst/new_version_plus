## 0.0.1
#### Version oiginal: 
* #117: Make compatible with new Play Store UI
* #75: Add `forceAppVersion` field to make testing easier.
* #77: Improve `canUpdate` logic so that greater local version won't prompt for an update.
* #50: Check for empty result from iOS App Store if the app does not exist in the store
* #45: Check if What's New text exists before accessing it to prevent crash.
* Optional field `releaseNotes` added to `VersionStatus`, which contains the release notes for a published app.
* Optional parameter `allowDismissal` added to `showUpdateDialog` function. When it is set to false, the plugin prevents the user from dismissing the update dialog. By default it is true.
* `NewVersion` now only has three fields `iOSId`, `androidId`, and `iOSAppStoreCountry`. The other fields have been turned into parameters for the individual functions.
* `VersionStatus` can no longer be directly instantiated by the user.
* Migrated to null-safety, so certain fields are now `final` or non-null, which may break your code.
* `canUpdate` now checks that the local version is *smaller* than the store version, not just that it is unequal.
* Add `iOSAppStoreCountry` parameter to allow app lookup in a different country's App Store
* Bump packages to latest version
* Migrate from `package_info` to `package_info_plus`
* Clean up example project
* Document all parameters in README
* Add more granular parameters, fix Android web view and navigation bugs.
* Fix HTTPS bug on iOS. Fix null return for android version statuses. Upgrade dependencies.
* Initial release. API includes `getVersionStatus` and `showAlertIfNecessary` methods. Support for iOS and Android.
#### Version Migrate
* Update plugin

## 0.0.1+1
* Fix pub dev

## 0.0.1+2
* Support old version flutter 2.5.0 it remove version 0.0.2

## 0.0.1+3
* Support old version flutter 2.5.0 it remove version 0.0.2

## 0.0.1+4
* Support old version flutter 2.5.0 it remove version 0.0.2

## 0.0.2
* Support last version of flutter
* Update plugin :)
* version stable