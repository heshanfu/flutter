import 'dart:async';
import 'package:flutter/material.dart';
import './uwave.dart';
import './server_list.dart';
import './listen.dart';

void main() => runApp(new UwaveApp());

class UwaveApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'üWave',
      theme: new ThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFF9D2053),
        accentColor: Color(0xFFB20062),
      ),
      home: new UwaveServerList(
        title: 'Public üWave Servers',
        onJoin: (context, server) =>  _listen(context, server),
      ),
    );
  }

  void _listen(BuildContext context, UwaveServer server) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UwaveListen(server: server)),
    );
  }
}
