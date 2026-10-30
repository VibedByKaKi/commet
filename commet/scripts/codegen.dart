// ignore_for_file: avoid_print

import 'dart:io';

Future<ProcessResult> getDependencies() async {
  var process = Process.runSync(
    "flutter",
    [
      "pub",
      "get",
    ],
    runInShell: true,
  );

  print(process.stdout);
  print(process.stderr);
  return process;
}

Future<ProcessResult> intlUtilsGenerate() async {
  var process = await Process.run(
    "flutter",
    [
      "pub",
      "run",
      "intl_utils:generate",
    ],
    runInShell: true,
  );

  print(process.stdout);
  print(process.stderr);
  return process;
}

Future<List<File>> generateFileLists() async {
  var dir = Directory("lib/generated/l10n");
  if (!dir.existsSync()) {
    dir.create(recursive: true);
  }

  var lib = Directory("lib");
  var files = lib.listSync(recursive: true);
  String fileList = "";

  //Write list of sources for l10n generation
  for (var file in files) {
    //skip generated files
    if (file.path.endsWith(".g.dart") ||
        file.path.contains("generated") ||
        file.path.contains("widgetbook")) {
      continue;
    }

    //skip non dart files
    if (!file.path.endsWith(".dart")) {
      continue;
    }

    fileList += "${file.absolute.path}\n";
  }

  var sourcesFile = File("lib/generated/l10n/sources_list_file.txt");

  await sourcesFile.create(recursive: true);
  sourcesFile.writeAsStringSync(fileList);

  lib = Directory("assets/l10n");
  files = lib.listSync(recursive: true);
  fileList = "";

  for (var file in files) {
    //skip non arb files
    if (!file.path.endsWith(".arb")) {
      continue;
    }

    fileList += "${file.absolute.path}\n";
  }

  var arbFile = File("lib/generated/l10n/arb_list_file.txt");

  await arbFile.create(recursive: true);
  arbFile.writeAsStringSync(fileList);

  return [sourcesFile, arbFile];
}

Future<ProcessResult> generateFromArb(List<File> files) async {
  var process = await Process.run(
    "flutter",
    [
      "pub",
      "run",
      "intl_translation:generate_from_arb",
      "--sources-list-file",
      files[0].absolute.path,
      "--translations-list-file",
      files[1].absolute.path,
      "--output-dir=lib/generated/l10n"
    ],
    runInShell: true,
  );

  print(process.stdout);
  print(process.stderr);
  return process;
}

Future<ProcessResult> buildRunner() async {
  var process = await Process.run(
    "flutter",
    [
      "pub",
      "run",
      "build_runner",
      "build",
      "--delete-conflicting-outputs",
    ],
    runInShell: true,
  );

  print(process.stdout);
  print(process.stderr);
  return process;
}

void main() async {
  var result = await getDependencies();
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }

  result = await intlUtilsGenerate();
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }

  // Upstream dropped flutter_intl.output_dir; integration tests still import
  // integration_test/generated/l10n.dart (+ l10n_*.dart siblings).
  final intlDir = Directory('lib/generated/intl');
  if (!intlDir.existsSync()) {
    print('ERROR: lib/generated/intl missing after intl_utils:generate');
    exit(1);
  }
  final destDir = Directory('integration_test/generated')
    ..createSync(recursive: true);
  var mirrored = 0;
  for (final entity in intlDir.listSync()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (!name.startsWith('l10n') || !name.endsWith('.dart')) continue;
    entity.copySync('${destDir.path}/$name');
    mirrored++;
    print('Mirrored ${entity.path} -> ${destDir.path}/$name');
  }
  if (mirrored == 0 || !File('${destDir.path}/l10n.dart').existsSync()) {
    print('ERROR: failed to mirror intl_utils l10n bindings for integration_test');
    exit(1);
  }

  var files = await generateFileLists();
  result = await generateFromArb(files);
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }

  result = await buildRunner();
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }
}
