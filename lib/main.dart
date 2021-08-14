import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:telephony/telephony.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';


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
  final formKey = GlobalKey<FormState>();
  final buttontext = new TextStyle(fontSize: 24.0);
  final coordtext = new TextStyle(fontSize: 24.0);
  final mycontroller = TextEditingController();
  var position;
  final Telephony telephony = Telephony.instance;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.

    await [Permission.sms, Permission.locationWhenInUse].request();
    // position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  void _getCurrentLocation() async {
    position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
        _locationMessage = "Latitud: ${position.latitude}\nLongitud: ${position.longitude}";
      });
      _sendsms(phone);

  }

  void _sendsms(String number) {
    // await _getPermission();
    print("Mensaje enviado");
    print(position);
    String msg = "Latitud: ${position.latitude}\nLongitud: ${position.longitude}";
    String link = "https://www.google.com/maps/place/${position.latitude},${position.longitude}";
    print(msg);
    telephony.sendSms(
      to: number,
      message: "Encuéntrame:" + "\n\n" + msg + "\n\n" + link,
    );
          
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
            new Container(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 50),
              child: Form(
                key: formKey,
                child: TextFormField(
                  decoration: new InputDecoration(
                    labelText: "Número telefónico",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.black             
                  ),
                  // onSaved: ,
                  onSaved: (String?value) {
                    setState(() => phone = value);
                  },
                  validator: (value) {
                    if (value != null && value.length < 1){
                      return "El número telefónico no puede estar vacío.";
                    } else if (value != null && value.length < 10) {
                      return "Inserte un número telefónico válido.";
                    } else {
                      return null;
                    }
                  },
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                final isValid = formKey.currentState!.validate();
                if (isValid){
                  formKey.currentState!.save();
                  _getCurrentLocation();
                }
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