import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'AuthorizationStatus.dart';

const MethodChannel _channel = MethodChannel('request_nstracking');
final storage =  const FlutterSecureStorage();

void main() {
  runApp(MaterialApp(
      home: Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(
              body: PermissionHandlerWidget()),
      )));
}

class PermissionHandlerWidget extends StatefulWidget {

  @override
  _PermissionHandlerWidgetState createState() => _PermissionHandlerWidgetState();
}

class _PermissionHandlerWidgetState extends State<PermissionHandlerWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
          children: Permission.values
              .where((permission) {
            if (Platform.isIOS) {
               return permission == Permission.appTrackingTransparency;
            } else {
              return permission != Permission.unknown &&
                  permission != Permission.mediaLibrary &&
                  permission != Permission.photosAddOnly &&
                  permission != Permission.reminders &&
                  permission != Permission.bluetooth &&
                  permission != Permission.appTrackingTransparency &&
                  permission != Permission.criticalAlerts &&
                  permission != Permission.assistant;
            }
          })
              .map((permission) => PermissionWidget(permission))
              .toList()),
    );
  }
}

class PermissionWidget extends StatefulWidget {
  const PermissionWidget(this._permission, {super.key});

  final Permission _permission;


  @override
  _PermissionState createState() => _PermissionState(_permission);
}

class _PermissionState extends State<PermissionWidget> {
  final Permission _permission;
  _PermissionState(this._permission);

   AuthorizationStatus _permissionStatus = AuthorizationStatus.Denied;

  Color getPermissionColor() {
    switch (_permissionStatus) {
      case AuthorizationStatus.Denied:
        return Colors.red;
      case AuthorizationStatus.Authorized:
        return Colors.green;
      case AuthorizationStatus.Restricted:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        _permission.toString(),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: Text(
        _permissionStatus.toString(),
        style: TextStyle(color: getPermissionColor()),
      ),
      trailing: (_permission is PermissionWithService)
          ? IconButton(
          icon: const Icon(
            Icons.info,
            color: Colors.white,
          ),
          onPressed: () {
            checkServiceStatus(
                context, _permission);
          })
          : null,
      onTap: () async{
        //int status = int.parse(await storage.read(key: "permissionStatus")?? "-1");
        int status = _permissionStatus.value;
        if(status==AuthorizationStatus.Authorized.value){
          openAppSettings();
        }
        else if(status==AuthorizationStatus.Denied.value){
          requestTrackingPermission();
        }
      },
    );
  }

  void checkServiceStatus(BuildContext context, PermissionWithService permission) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text((await permission.serviceStatus).toString()),
    ));
  }

  Future<int?> requestTrackingPermission() async {
    try {
      final int? status = await _channel.invokeMethod('requestTrackingPermission');
      print("shaimaa: $status");
      setState(() {
          switch(status){
            case 0:
              _permissionStatus = AuthorizationStatus.NotDetermined;
            case 1:
              _permissionStatus = AuthorizationStatus.Restricted;
            case 2:
              _permissionStatus = AuthorizationStatus.Denied;
            case 3:
              _permissionStatus = AuthorizationStatus.Authorized;
          }
        });
     // await storage.write(key: "permissionStatus", value: "$status");
    } on PlatformException catch (e) {
      print("Failed to request tracking permission: '${e.message}'.");
      return null;
    }
    return null;
  }

  Future<int?> openAppSettings() async {
    try {
      final int? result = await _channel.invokeMethod('openAppSettings');
       print("openAppSettings: $result");
    } on PlatformException catch (e) {
      print("Failed to request tracking permission: '${e.message}'.");
      return null;
    }
    return null;
  }
}
