import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

final flutterReactiveBle = FlutterReactiveBle();
String deviceId = "D0:94:42:C9:97:E5";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

  Future updateLED(bool lightStatus) async {
    List<DiscoveredService> services =
        await flutterReactiveBle.discoverServices(deviceId);
    DiscoveredService LEDservice = services.elementAt(2);
    QualifiedCharacteristic characteristic = QualifiedCharacteristic(
        characteristicId: LEDservice.characteristicIds.elementAt(1),
        serviceId: LEDservice.serviceId,
        deviceId: deviceId);

    // for (DiscoveredService s in services) {
    //   print("New service");
    //   print(s);
    //   print("");
    //   print(s.characteristics);
    //   print("-------------");
    //   print("");
    // }
    // Using 26

    await flutterReactiveBle.writeCharacteristicWithoutResponse(characteristic,
        value: [lightStatus ? 1 : 0]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                  updateLED(value);
                  setState(() {
                    lightStatus = value;
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
            id: deviceId,
            servicesWithCharacteristicsToDiscover: {},
            connectionTimeout: const Duration(seconds: 2),
          )
              .listen((connectionState) {
            // Handle connection state updates
            print(connectionState.connectionState);
          }, onError: (Object error) {
            // Handle a possible error
          });
        },
        tooltip: 'Increment',
        child: const Icon(Icons.bluetooth),
      ),
    );
  }
}
