import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  var position, socket, ip, port, lastIp, lastPort;
  final buttontext = new TextStyle(fontSize: 24.0);
  final coordtext = new TextStyle(fontSize: 24.0);
  bool isConnected = false;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    initPlatformState();
    // connectToServer();
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
    socket = io('http://' + ip + ':' + port, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    // Connect to websocket
    socket.connect();

    // Handle socket events
    socket.on('connect', (_) {
      print('Connect: ${socket.id}');
      setState(() {
        isConnected = true;
      });
      Fluttertoast.showToast(
          msg: "Conectado exitosamente a " + 'http://' + ip + ':' + port + ".",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          fontSize: 16);
    });

    socket.on('connect_error', (_) {
      if (!isConnected) {
        Fluttertoast.showToast(
            msg: "No se pudo conectar al servidor.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            fontSize: 16);
      }
    });

    socket.on('connect_timeout', (_) {
      Fluttertoast.showToast(
          msg: "No se pudo conectar al servidor.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          fontSize: 16);
    });

    socket.on('disconnect', (_) {
      print('Connection lost.');
      setState(() {
        isConnected = false;
      });
      Fluttertoast.showToast(
          msg: "Servidor desconectado.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          fontSize: 16);
    });
  }

  void _getCurrentLocation() async {
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _locationMessage =
          "Latitud: ${position.latitude}\nLongitud: ${position.longitude}";
    });
    _sendLocation();
  }

  void _sendLocation() {
    // await _getPermission();
    print("Mensaje enviado");
    print(position);
    String msg =
        "Latitud: ${position.latitude}\nLongitud: ${position.longitude}";
    String link =
        "https://www.google.com/maps/place/${position.latitude},${position.longitude}";
    print(msg);

    if (isConnected) {
      socket.emit('stream', msg + '\n' + link);

      Fluttertoast.showToast(
          msg: "Su ubicación ha sido enviada.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          fontSize: 16);
    }
  }

  Widget disconnectButton() {
    return TextButton(
      onPressed: () {
        socket.disconnect();
      },
      child: Text(
        "Desconectar",
        style: buttontext,
      ),
      style: TextButton.styleFrom(
          primary: Colors.white, backgroundColor: Colors.redAccent),
    );
  }

  Widget connectButton() {
    return TextButton(
      onPressed: () {
        final isValid = formKey.currentState!.validate();
        if (isValid) {
          formKey.currentState!.save();
          connectToServer();
        }
      },
      child: Text(
        "Conectar",
        style: buttontext,
      ),
      style: TextButton.styleFrom(
          primary: Colors.white,
          backgroundColor: Theme.of(context).primaryColor),
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Flexible(
              child: Container(
                // margin: EdgeInsets.only(bottom: 63),
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
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: new InputDecoration(
                        labelText: "Dirección IP",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 20.0, color: Colors.black),
                      // onSaved: ,
                      onSaved: (String? value) {
                        setState(() => ip = value);
                      },
                      validator: (value) {
                        RegExp regex = RegExp(
                            r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){4}$');
                        bool valid = regex.hasMatch(value!);

                        if (!valid) {
                          return "La dirección IP no es válida.";
                        } else {
                          return null;
                        }
                      },
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9]*\.?[0-9]*'))
                      ],
                      enabled: !isConnected,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                      child: TextFormField(
                        decoration: new InputDecoration(
                          labelText: "Número de Puerto",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 20.0, color: Colors.black),
                        // onSaved: ,
                        onSaved: (String? value) {
                          setState(() => port = value);
                        },
                        validator: (value) {
                          if (value!.length < 1 || int.parse(value) > 65535) {
                            return "Ingrese un número de puerto válido.";
                          } else {
                            return null;
                          }
                        },
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        enabled: !isConnected,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  isConnected ? disconnectButton() : connectButton(),
                  TextButton(
                    onPressed: !isConnected
                        ? null
                        : () {
                            final isValid = formKey.currentState!.validate();
                            if (isValid) {
                              formKey.currentState!.save();
                              _getCurrentLocation();
                            }
                          },
                    child: Text(
                      "Enviar\nubicación",
                      style: buttontext,
                      textAlign: TextAlign.center,
                    ),
                    style: TextButton.styleFrom(
                        primary: Colors.white,
                        backgroundColor: !isConnected
                            ? Theme.of(context).disabledColor
                            : Theme.of(context).primaryColor),
                  ),
                ],
              ),
            ),
            Text(
              _locationMessage,
              style: coordtext,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
