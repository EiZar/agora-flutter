import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtm/agora_rtm.dart';

import '../utils/settings.dart';
import '../Widgets/user_view.dart';

class CallPage extends StatefulWidget {
  /// non-modifiable channel and user name of the page
  final String channelName;
  final String userName;
  /// non-modifiable client role of the page
  final ClientRole role;
  final String token;

  /// Creates a call page with given channel and user name.
  const CallPage({Key key, this.channelName, this.userName, this.token, this.role}) : super(key: key);


  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  static final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;

  EncryptionMode em;
  bool _isLogin = false;
  bool _isInChannel = false;
  final _broadcaster = <String>[];
  final _audience = <String>[];
  final Map<int, String> _allUsers = {};

  RtcEngine _engine;
  AgoraRtmClient _client;
  AgoraRtmChannel _channel;

  final buttonStyle = TextStyle(color: Colors.white, fontSize: 15);
  int localUid;

  @override
  void dispose() {
    // clear users
    _users.clear();
    // destroy sdk
    _engine.leaveChannel();
    _engine.destroy();
    _channel.leave();
    _allUsers.clear();
    _broadcaster.clear();
    _audience.clear();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // initialize agora sdk
    initialize();
    _createClient();
  }

  @override
  Future<void> initialize() async {
    if (APP_ID.isEmpty) {
      setState(() {
        _infoStrings.add(
          'APP_ID missing, please provide your APP_ID in settings.dart',
        );
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }
    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
//    await _engine.enableEncryption(true, EncryptionConfig(em, "write"));
//    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
//    configuration.dimensions = VideoDimensions(1920, 1080);
//    await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.joinChannel(widget.token, widget.channelName, null, 0);
//      await _engine.joinChannel(null, widget.channelName, null, 0);
  }

  /// Create agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.createWithConfig(RtcEngineConfig(APP_ID));
    await _engine.disableVideo();
    await _engine.enableAudio();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(widget.role);
  }

  /// Add agora event handlers
  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(error: (code) {
      setState(() {
        final info = 'onError: $code';
        _infoStrings.add(info);
      });
    }, joinChannelSuccess: (channel, uid, elapsed) async {
      setState(() {
        final info = 'onJoinChannel: $channel, uid: $uid';
        _infoStrings.add(info);
        localUid = uid;
        _allUsers.putIfAbsent(uid, () => widget.userName);
      });
      if (widget.role == ClientRole.Broadcaster) {
        setState(() {
          _users.add(uid);
        });
      }
    },leaveChannel: (stats) {
      setState(() {
        _infoStrings.add('onLeaveChannel');
        _users.clear();
        _allUsers.remove(localUid);
      });
    }, userJoined: (uid, elapsed) {
      setState(() {
        final info = 'userJoined: $uid';
        _infoStrings.add(info);
        _users.add(uid);
      });
    }, userOffline: (uid, elapsed) {
      setState(() {
        final info = 'userOffline: $uid';
        _infoStrings.add(info);
        _users.remove(uid);
      });
    }, firstRemoteVideoFrame: (uid, width, height, elapsed) {
      setState(() {
        final info = 'firstRemoteVideo: $uid ${width}x $height';
        _infoStrings.add(info);
      });
    }));
  }

  void _createClient() async {
    _client = await AgoraRtmClient.createInstance(APP_ID);
    _client.onConnectionStateChanged = (int state, int reason) {
      if (state == 5) {
        _client.logout();
        print('Logout.');
        setState(() {
          _isLogin = false;
        });
      }
    };

    String userId = widget.userName;
//    String userId = "2882341273";
    await _client.login(widget.token, userId);
//    await _client.login(null, userId);
    // print('Login success: ' + userId);
    setState(() {
      _isLogin = true;
    });
    String channelName = widget.channelName;
    _channel = await _createChannel(channelName);
    await _channel.join();
    // print('RTM Join channel success.');
    setState(() {
      _isInChannel = true;
    });
    await _channel.sendMessage(AgoraRtmMessage.fromText('$localUid:join'));
    _client.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      print("Peer msg: " + peerId + ", msg: " + message.text);

      var userData = message.text.split(':');

      if (userData[1] == 'leave') {
        print('In here');
        setState(() {
          _allUsers.remove(int.parse(userData[0]));
        });
      } else {
        setState(() {
          _allUsers.putIfAbsent(int.parse(userData[0]), () => peerId);
        });
      }
    };
    _channel.onMessageReceived =
        (AgoraRtmMessage message, AgoraRtmMember member) {
      print(
          'Outside channel message received : ${message.text} from ${member.userId}');

      var userData = message.text.split(':');

      if (userData[1] == 'leave') {
        setState(() {
          _allUsers.remove(int.parse(userData[0]));
        });
      } else {
        print('Broadcasters list : $_users');
        print('All users lists: ${_allUsers.values}');
        setState(() {
          _allUsers.putIfAbsent(int.parse(userData[0]), () => member.userId);
        });
      }
    };
    for (var i = 0; i < _users.length; i++) {
      if (_allUsers.containsKey(_users[i])) {
        setState(() {
          _broadcaster.add(_allUsers[_users[i]]);
        });
      } else {
        setState(() {
          _audience.add('${_allUsers.values}');
        });
      }
    }
  }

  Future<AgoraRtmChannel> _createChannel(String name) async {
    AgoraRtmChannel channel = await _client.createChannel(name);
    channel.onMemberJoined = (AgoraRtmMember member) async {
      print('Member joined : ${member.userId}');
      // setState(() {

      // });
      await _client.sendMessageToPeer(
          member.userId, AgoraRtmMessage.fromText('$localUid:join'));
    };
    channel.onMemberLeft = (AgoraRtmMember member) async {
      var reversedMap = _allUsers.map((k, v) => MapEntry(v, k));
      print('Member left : ${member.userId}:leave');
      print('Member left : ${reversedMap[member.userId]}:leave');

      setState(() {
        _allUsers.remove(reversedMap[member.userId]);
      });
      await channel.sendMessage(
          AgoraRtmMessage.fromText('${reversedMap[member.userId]}:leave'));
    };
    channel.onMessageReceived =
        (AgoraRtmMessage message, AgoraRtmMember member) {
      print('Channel message received : ${message.text} from ${member.userId}');

      var userData = message.text.split(':');

      if (userData[1] == 'leave') {
        _allUsers.remove(int.parse(userData[0]));
      } else {
        _allUsers.putIfAbsent(int.parse(userData[0]), () => member.userId);
      }
    };
    return channel;
  }

  /// Toolbar layout
  Widget _toolbar() {
    if (widget.role == ClientRole.Audience) return Container();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _onToggleMute,
            child: Row(
              children: [
                Icon(
                  muted ? Icons.mic_off : Icons.mic,
                  color: muted ? Colors.white : Colors.blueAccent,
                  size: 20.0,
                ),
                SizedBox(
                  width: 5,
                ),
                muted
                    ? Text(
                  'Unmute',
                  style: buttonStyle,
                )
                    : Text(
                  'Mute',
                  style: buttonStyle.copyWith(color: Colors.black),
                )
              ],
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 2.0,
            fillColor: muted ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(15.0),
          ),
          RawMaterialButton(
            onPressed: () => _onCallEnd(context),
            child: Row(
              children: [
                Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(
                  width: 5,
                ),
                Text(
                  'Disconnect',
                  style: buttonStyle,
                )
              ],
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
          ),
        ],
      ),
    );
  }

  void _onCallEnd(BuildContext context) {
    Navigator.pop(context);
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agora Flutter'),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Broadcaster',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                  height: MediaQuery.of(context).size.height * 0.2,
                  width: double.infinity,
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _allUsers.containsKey(_users[index])
                          ? UserView(
                        userName: _allUsers[_users[index]],
                        role: ClientRole.Broadcaster,
                      )
                          : Container();
                    },
                  )),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.2,
              ),
              _toolbar()
            ],
          )),
    );
  }
}
