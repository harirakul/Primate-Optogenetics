import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

final flutterReactiveBle = FlutterReactiveBle();
var MACAddress = "D0:94:42:C9:97:E5";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Primate Optogenetics',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Nordic nRF 52 Bluetooth Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;
  final devices = <DiscoveredDevice>[];

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool lightStatus = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(
              height: 50,
              child: Text(
                'LED Status',
                style: TextStyle(fontSize: 24),
              ),
            ),
            Transform.scale(
              scale: 2,
              child: Switch(
                value: lightStatus,
                onChanged: (bool value) {
                  setState(() {
                    lightStatus = value;
                    print(value);
                    final characteristic = QualifiedCharacteristic(
                        serviceId: Uuid([1800]),
                        characteristicId: Uuid([1800]),
                        deviceId: MACAddress);
                    flutterReactiveBle.writeCharacteristicWithResponse(
                        characteristic,
                        value: [0x00]);
                  });
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          flutterReactiveBle
              .connectToDevice(
            id: MACAddress,
            servicesWithCharacteristicsToDiscover: {},
            connectionTimeout: const Duration(seconds: 2),
          )
              .listen((connectionState) {
            // Handle connection state updates
          }, onError: (Object error) {
            // Handle a possible error
          });
          // flutterReactiveBle.scanForDevices(
          //     withServices: [], scanMode: ScanMode.lowLatency).listen((device) {
          //   print(device);
          //   //code for handling results
          // }, onError: (error, stackTrace) {
          //   //code for handling error
          //   print(error);
          // });
        },
        tooltip: 'Increment',
        child: const Icon(Icons.bluetooth),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
