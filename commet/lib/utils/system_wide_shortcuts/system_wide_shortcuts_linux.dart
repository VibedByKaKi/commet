import 'package:commet/utils/system_wide_shortcuts/system_wide_shortcuts.dart';
import 'package:dbus/dbus.dart';

// for testing:
// gdbus call --session --dest chat.halley.halleyapp --object-path /chat/halley/halleyapp/Shortcuts --method chat.halley.halleyapp.Shortcuts.unmute
// gdbus call --session --dest chat.halley.halleyapp --object-path /chat/halley/halleyapp/Shortcuts --method chat.halley.halleyapp.Shortcuts.mute

class SystemWideShortcutsLinux {
  static Future<void> init() async {
    await initDbus();
  }

  static Future<void> initDbus() async {
    var client = DBusClient.session();
    await client.requestName('chat.halley.halleyapp');
    await client.registerObject(TestObject());
  }
}

class TestObject extends DBusObject {
  TestObject() : super(DBusObjectPath('/chat/halley/halleyapp/Shortcuts'));

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface == 'chat.halley.halleyapp.shortcuts' && name == 'Version') {
      return DBusGetPropertyResponse(DBusString('1.0'));
    } else {
      return DBusMethodErrorResponse.unknownProperty();
    }
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    print("Handling dbus message call!");
    print(methodCall.toString());
    if (methodCall.interface != "chat.halley.halleyapp.Shortcuts") {
      return DBusMethodErrorResponse.unknownInterface();
    }

    var shortcut = SystemWideShortcuts.shortcuts[methodCall.name];

    if (shortcut != null) {
      shortcut.callback();
    }

    return DBusMethodSuccessResponse();
  }
}
