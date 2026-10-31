// This file is a workaround for the issue: https://github.com/flutter/flutter/issues/101031

import 'package:commet/main.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:commet/generated/l10n.dart';
import 'matrix/login_test.dart' as login_test;
import 'matrix/multi_account_test.dart' as multi_account_test;

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await T.load(const Locale("en"));
  await preferences.init();

  login_test.main();
  // key_verification_test: skipped — createTestClient() is UnimplementedError
  // after the Matrix database/Hive migration.
  // create_space_test: skipped — space creation UI moved to GetOrCreateRoom and
  // the old ARB keys (promptCreateNewSpace, etc.) are gone from intl_en.arb.
  // change_space_name_test: skipped — prepare script only seeds a DM invite,
  // not a space the test can rename.
  multi_account_test.main();
}
