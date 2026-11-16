import 'dart:convert';
import 'dart:io';

import 'package:commet/client/alert.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/error_utils.dart';
import 'package:commet/utils/links/link_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

import 'package:http/http.dart' as http;

class UpdateChecker {
  static bool foundUpdate = false;

  static const _latestReleaseApi =
      "https://api.github.com/repos/VibedByKaKi/commet/releases/tags/latest";

  static const _latestReleasePage =
      "https://github.com/VibedByKaKi/commet/releases/tag/latest";

  static String get labelUpdateAvailable => Intl.message("Update Available",
      name: "labelUpdateAvailable",
      desc: "Label for the the info popup when an update is available");

  static String descriptionUpdateAvailable(String version) => Intl.message(
      "There is a newer version of Halley available: ${version}",
      name: "descriptionUpdateAvailable",
      args: [version],
      desc:
          "describes the update, showing the version code for the available update");

  static Future<void> checkForUpdates() async {
    if (foundUpdate) return;

    if (!shouldCheckForUpdates) {
      return;
    }

    if (preferences.checkForUpdates.value != true) {
      return;
    }

    final response = await http.get(Uri.parse(_latestReleaseApi), headers: {
      "Accept": "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28",
    });

    Log.i("Got update data: ${response.body}");

    if (response.statusCode != 200) {
      Log.w("Update check failed with status ${response.statusCode}");
      return;
    }

    final fields = jsonDecode(response.body) as Map<String, dynamic>;
    final publishedAt = fields["published_at"] as String?;
    if (publishedAt == null) return;

    final remoteTime = DateTime.parse(publishedAt).toUtc();
    final localTime = BuildConfig.BUILD_DATE.toUtc();

    if (!remoteTime.isAfter(localTime)) {
      Log.i(
          "Found latest release, but it's not newer than this build. current: $localTime remote: $remoteTime");
      return;
    }

    foundUpdate = true;
    final tag = (fields["name"] as String?)?.trim().isNotEmpty == true
        ? fields["name"] as String
        : (fields["tag_name"] as String? ?? "latest");

    final htmlUrl = fields["html_url"] as String? ?? _latestReleasePage;
    final canAutoUpdate = false;

    clientManager!.alertManager.addAlert(Alert(AlertType.info,
        messageGetter: () => descriptionUpdateAvailable(tag),
        titleGetter: () => labelUpdateAvailable,
        action: (context) =>
            doUpdateAction(context, canAutoUpdate, releaseUrl: htmlUrl)));
  }

  static bool get shouldCheckForUpdates {
    if (PlatformUtils.isWeb) {
      return false;
    }

    if (BuildConfig.VERSION_TAG == "v0.0.0-artifact") {
      return false;
    }

    return true;
  }

  static doUpdateAction(BuildContext context, bool canAutoUpdate,
      {String releaseUrl = _latestReleasePage}) async {
    if (PlatformUtils.isWindows) {
      windowsUpdateAction(context, canAutoUpdate, releaseUrl: releaseUrl);
      return;
    }

    LinkUtils.open(Uri.parse(releaseUrl), context: context);
  }

  static windowsUpdateAction(BuildContext context, bool canAutoUpdate,
      {String releaseUrl = _latestReleasePage}) async {
    var exe = Platform.resolvedExecutable;

    var installPath = path.dirname(exe);

    var installerPath =
        path.join(installPath, "installer", "commet-installer.exe");

    Log.i("Installed at: $installerPath");

    if (await File(installerPath).exists() && canAutoUpdate) {
      var confirmation = await AdaptiveDialog.confirmation(context,
          prompt: "Would you like to run the update installer?");

      if (confirmation == true) {
        await ErrorUtils.tryRun(context, () async {
          Log.i("Found installer, doing automatic update");

          for (var client in clientManager!.clients) {
            await client.close();
          }

          Process.run(
              installerPath,
              [
                "--command",
                "update",
              ],
              runInShell: true);

          // TODO: not this
          await Future.delayed(Duration(seconds: 1));
        });

        exit(0);
      }

      if (confirmation == null) return;
    }

    LinkUtils.open(Uri.parse(releaseUrl), context: context);
  }
}
