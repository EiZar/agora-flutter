import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import './call.dart';
import './audience.dart';
import './join_channel_video.dart';
import './screen_sharing.dart';
import 'package:http/http.dart' as http;
import 'package:toast/toast.dart';
import 'package:replay_kit_launcher/replay_kit_launcher.dart';

const CHANNEL = "native_communication.channel";
const KEY_NATIVE = "showNativeView";
const platform = const MethodChannel(CHANNEL);

class IndexPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => IndexState();

  String title;

  IndexPage({Key key, this.title}) : super(key: key) {
    platform.setMethodCallHandler(_handleMethod);
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case "message":
        debugPrint(call.arguments);
        return new Future.value("");
    }
  }
}

class IndexState extends State<IndexPage> {
  /// create a channelController to retrieve text value
//  final _channelController = TextEditingController(text: 'mychannel');

  static final _formKey = GlobalKey<FormState>();
  TextEditingController _channelController = new TextEditingController(text: 'mychannel');
  TextEditingController _userController = new TextEditingController(text: 'user');
  List<bool> isSelected;
  int selectedPage = 0;
  ClientRole _role = ClientRole.Broadcaster;
  String _token = "";
  bool _isBroadcaster = false;

  @override
  void initState() {
    super.initState();
    getToken();
    isSelected = [true, false];
//    platform.setMethodCallHandler(_handleMethod);
  }

  void launch() {
    // Please fill in the name of the Broadcast Extension in your project, which is the file name of the `.appex` product
    ReplayKitLauncher.launchReplayKitBroadcast('Agora-ScreenShare-Extension');
  }

  void finish() {
    // Please fill in the CFNotification name in your project
    ReplayKitLauncher.finishReplayKitBroadcast('ZGFinishBroadcastUploadExtensionProcessNotification');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.87,
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  15,
                                ),
                              ),
                              prefixIcon: Icon(Icons.laptop),
                              hintText: 'Channel Name',
                            ),
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'Channel name is required!';
                              } else {
                                return null;
                              }
                            },
                            controller: _channelController,
                          ),
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02),
                          TextFormField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  15,
                                ),
                              ),
                              prefixIcon: Icon(Icons.person),
                              hintText: 'User Name',
                            ),
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'User name is required!';
                              } else {
                                return null;
                              }
                            },
                            controller: _userController,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.65,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Transform.scale(
                      scale: 1.1,
                      child: SwitchListTile(
                          title: _isBroadcaster
                              ? Text('Broadcaster', style: TextStyle(fontSize: 18),)
                              : Text('Audience', style: TextStyle(fontSize: 18),),
                          value: _isBroadcaster,
                          activeColor: Color.fromRGBO(45, 156, 215, 1),
                          secondary: _isBroadcaster
                              ? Icon(
                            Icons.account_circle,
                            color: Color.fromRGBO(45, 156, 215, 1),
                          )
                              : Icon(Icons.account_circle),
                          onChanged: (value) {
                            setState(() {
                              _isBroadcaster = value;
                              print(_isBroadcaster);
                            });
                          }),
                    )
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.width * 0.16,
                    child: RaisedButton(
                      color: Colors.amber,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      onPressed: onJoin,
                      child: Text(
                        'Join',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.width * 0.16,
                    child: RaisedButton(
                      color: Colors.amber,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      onPressed: onNative,
                      child: Text('ShareScreen',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  // SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  // Container(
                  //   width: MediaQuery.of(context).size.width * 0.8,
                  //   height: MediaQuery.of(context).size.width * 0.16,
                  //   child: RaisedButton(
                  //     color: Colors.amber,
                  //     shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(15)),
                  //     onPressed: onAudience,
                  //     child: Text(
                  //       'Audience',
                  //       style: TextStyle(
                  //         color: Colors.white,
                  //         fontSize: 18,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          )
      ),
    );
  }

  Future<void> onJoin() async {
    // Toast.show("Toast Native click", context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
    // await getToken();
    // await for camera and mic permissions before pushing video page
    // await _handleCameraAndMic(Permission.camera);
    await _handleCameraAndMic(Permission.microphone);
    // push video page with given channel name
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallPage(
          channelName: _channelController.text,
          userName: _userController.text,
          token: _token,
          role: _role,
        ),
      ),
    );
//    if (_formKey.currentState.validate()) {
//
//    }
  }

  Future<void> onAudience() async {
    // Toast.show("Toast Native click", context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
    // await getToken();
    // await for camera and mic permissions before pushing video page
    await _handleCameraAndMic(Permission.camera);
    await _handleCameraAndMic(Permission.microphone);
    // push video page with given channel name
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Audience(
          channelName: _channelController.text,
          userName: _userController.text,
          token: _token,
          role: ClientRole.Audience,
        ),
      ),
    );
//    if (_formKey.currentState.validate()) {
//
//    }
  }

  Future<void> onNative() async {
    await _handleCameraAndMic(Permission.camera);
    await _handleCameraAndMic(Permission.microphone);
    if (_isBroadcaster) {
      // Toast.show("Toast Native click", context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
      if (Platform.isAndroid) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: ScreenSharing(token: _token),
                )));
      }
      if (Platform.isIOS) {
        final Map params = <String, dynamic> {
          'token': _token,
        };
        ReplayKitLauncher.launchReplayKitBroadcast('Agora-ScreenShare-Extension');
        String result = "testing";
        result = await platform.invokeMethod(KEY_NATIVE, params);
        print("result ********** " + result);
      }
    } else {
      print("start to get shared screen ****** ");
      // Toast.show("Toast Native click", context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
      // await getToken();
      // push video page with given channel name
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
            // Scaffold(
            //   appBar: AppBar(
            //     title: Text("mychannel"),
            //   ),
            //   body: JoinChannelVideo()
            // )
          Audience(
            channelName: _channelController.text,
            userName: _userController.text,
            token: _token,
            role: ClientRole.Audience,
          ),
        ),
      );
    }
    // await platform.invokeMethod(KEY_NATIVE, _token);
  }

  Future<String> getToken() async {
    final response = await http.get('https://asia-northeast1-game-platform-309903.cloudfunctions.net/get_token');
    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      _token = res['tokenwithid'];
      return _token;
    }else {
      return '0';
    }
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }
}

