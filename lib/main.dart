import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
  var position, socket, ip, port;
  final buttontext = new TextStyle(fontSize: 20.0);
  final coordtext = new TextStyle(fontSize: 22.0);
  bool isConnected = false;
  final formKey = GlobalKey<FormState>();
  var favorites = <String>{};
  

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _read();
    // connectToServer();
  }

  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    await Permission.locationWhenInUse.request();
    position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _locationMessage = "Latitud: ${position.latitude}\nLongitud: ${position.longitude}";
    });
  }

  _read() async {
        final prefs = await SharedPreferences.getInstance();
        final key = 'favorites';
        List<String>? value = prefs.getStringList(key);
        if (value != null) {
          favorites = value.toSet();
        }
      }
      
    _save() async {
      final prefs = await SharedPreferences.getInstance();
      final key = 'favorites';
      prefs.setStringList(key, favorites.toList());
      print('saved favorites');
    }

  void connectToServer() {
    // Configure socket transports must be sepecified
    socket = io('http://' + ip + ':' + port, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': false,
    });

    // Connect to websocket
    socket.connect();

    // Handle socket events
    socket.on('connect', (_) {
      print('Connect: ${socket.id}');
      setState(() {
        isConnected = true;
      });
      Fluttertoast.cancel();
      Fluttertoast.showToast(
          msg: "Conectado exitosamente a " + 'http://' + ip + ':' + port + ".",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          fontSize: 16);
    });

    socket.on('connect_error', (_) {
      print("attempting reconection");
      Fluttertoast.cancel();
      Fluttertoast.showToast(
          msg: "No se pudo conectar al servidor.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          fontSize: 16);
    });

    socket.on('connect_timeout', (_) {
      print("attempting reconection");
      Fluttertoast.cancel();
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
      Fluttertoast.cancel();
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
    return ElevatedButton(
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
    return ElevatedButton(
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
  
  void _pushFavorites() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setPageState) {
            final Iterable<ListTile> tiles = favorites.map(
              (String address) {
                List addressSplit = address.split(':');
                return ListTile(
                  title: Text(
                    'IP: ' + addressSplit[0] + '      Port: ' + addressSplit[1],
                    style: TextStyle(fontSize: 20.0),
                  ),
                  // Code I added //
                  trailing: Icon(Icons.delete),
                  onTap: () {
                    setState(() => favorites.remove(address));
                    setPageState(() => favorites.remove(address));
                    _save();
                  },
                  // End //
                );
              },
            );
            final List<Widget> divided = ListTile.divideTiles(
              context: context,
              tiles: tiles,
            ).toList();

            return Scaffold(
              appBar: AppBar(
                title: Text('Favoritos'),
              ),
              body: ListView(children: divided),
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Encuéntrame"),
        actions: [
          IconButton(onPressed: _pushFavorites, icon: Icon(Icons.star))
        ],
      ),
      body: Align(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(
                  // top: !isConnected ?  0 : 37,
                  bottom: 40
                ),
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
              Padding(
                padding: EdgeInsets.only(bottom: 30),
                child: Text(
                  _locationMessage,
                  style: coordtext,
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 60),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextButton(
                      onPressed: () {
                        final isValid =
                            formKey.currentState!.validate();
                        if (isValid) {
                          formKey.currentState!.save();
                          String newFav = ip + ':' + port;
                          if (!favorites.contains(newFav)) {
                            favorites.add(newFav);

                            final snackbar = SnackBar(
                              content: const Text('Añadido a favoritos.'),
                              action: SnackBarAction(
                                label: 'DESHACER',
                                onPressed: () {
                                  favorites.remove(newFav);
                                }
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(snackbar);
                            _save();
                          }
                        }

                      },
                      child: Text("Añadir a favoritos", style: TextStyle(fontSize: 15.0)),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(50, 30),
                        // backgroundColor: Colors.blue
                      )),
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
                padding: EdgeInsets.only(
                    left: 40, right: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: isConnected
                                ? disconnectButton()
                                : connectButton()),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: !isConnected
                                ? null
                                : () {
                                    final isValid =
                                        formKey.currentState!.validate();
                                    if (isValid) {
                                      formKey.currentState!.save();
                                      _getCurrentLocation();
                                    }
                                  },
                            child: Text(
                              "Enviar ubicación",
                              style: buttontext,
                              textAlign: TextAlign.center,
                            ),
                            style: TextButton.styleFrom(
                                primary: Colors.white,
                                backgroundColor: !isConnected
                                    ? Theme.of(context).disabledColor
                                    : Theme.of(context).primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
