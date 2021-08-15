import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart';

import 'dart:async';



void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Encuéntrame',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String _locationMessage = "";
  var phone;
  final buttontext = new TextStyle(fontSize: 24.0);
  final coordtext = new TextStyle(fontSize: 24.0);
  var position;
  bool isConnected = false;
  var socket;
  
  
  @override
  void initState() {
    super.initState();
    initPlatformState();
    connectToServer();
  }

  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    await Permission.locationWhenInUse.request();
    // position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

    void connectToServer() {
      // Configure socket transports must be sepecified
      socket = io('http://192.168.0.7:8080', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });
     
      // Connect to websocket
      socket.connect();
     
      // Handle socket events
      socket.on('connect', (_) {
        print('connect: ${socket.id}');
        isConnected = true;
      });
   
  }

  void _getCurrentLocation() async {
    position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
        _locationMessage = "Latitud: ${position.latitude}\nLongitud: ${position.longitude}";
      });
      _sendLocation();

  }

  void _sendLocation() {
    // await _getPermission();
    print("Mensaje enviado");
    print(position);
    String msg = "Latitud: ${position.latitude}\nLongitud: ${position.longitude}";
    String link = "https://www.google.com/maps/place/${position.latitude},${position.longitude}";
    print(msg);


    if (isConnected) {
      print("connected");
      socket.emit('stream', msg + '\n' + link);
    }
          
    Fluttertoast.showToast(
      msg: "Su ubicación ha sido enviada.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      fontSize: 16
    );      
  }

  // Future _getPermission() async {
  //   await Permission.sms.request();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Encuéntrame"),
      ),
      body: Align(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(bottom: 63),
              child: SizedBox(
                width: 150,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Icon(
                    Icons.location_on,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                _getCurrentLocation();
              },
              child: Text(
                "Enviar mi ubicación",
                style: buttontext,
              ),
              style: TextButton.styleFrom(
                primary: Colors.white,
                backgroundColor: Colors.blueAccent
              ),
            ),
            SizedBox(height: 50),
            Text(
              _locationMessage,
              style:coordtext,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}