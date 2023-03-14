import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

final flutterReactiveBle = FlutterReactiveBle();
String deviceId = "D0:94:42:C9:97:E5";
String connectionStatus = "Connect";
//String deviceId = "C7:23:46:15:6A:50";
List foundDevices = [];
List foundDeviceIds = [];
List connectionStatuses = [];
var connectionStream;

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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: () {
                    foundDevices.clear();
                    foundDeviceIds.clear();
                    connectionStatuses.clear();
                    flutterReactiveBle.scanForDevices(
                        withServices: [],
                        scanMode: ScanMode.lowLatency).listen((device) {
                      if (device.name != "" &&
                          !foundDeviceIds.contains(device.id)) {
                        setState(() {
                          foundDevices.add(device);
                          foundDeviceIds.add(device.id);
                          connectionStatuses.add("Connect");
                        });
                      }

                      //code for handling results
                    }, onError: (Object error) {
                      print(error);
                      //code for handling error
                    });
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40)),
                  child: const Text("SCAN")),
            ),
            Expanded(
              child: ListView.builder(
                  itemCount: foundDevices.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${foundDevices[index].name}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      Text("${foundDevices[index].id}"),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                    onPressed: () {
                                      if (connectionStatuses[index] ==
                                          "Connect") {
                                        connectionStream = flutterReactiveBle
                                            .connectToDevice(
                                          id: foundDevices[index].id,
                                          servicesWithCharacteristicsToDiscover: {},
                                          connectionTimeout:
                                              const Duration(seconds: 3),
                                        )
                                            .listen((connectionState) async {
                                          switch (
                                              connectionState.connectionState) {
                                            case DeviceConnectionState
                                                .connecting:
                                              print(
                                                  "-- Connecting to device --");
                                              break;

                                            case DeviceConnectionState
                                                .connected:
                                              print(" -- Connected --");
                                              deviceId = foundDevices[index].id;
                                              setState(() {
                                                connectionStatuses[index] =
                                                    "Disconnect";
                                              });
                                              break;

                                            case DeviceConnectionState
                                                .disconnecting:
                                              print("-- disconnecting --");
                                              break;

                                            case DeviceConnectionState
                                                .disconnected:
                                              print("-- disconnected --");
                                              setState(() {
                                                connectionStatuses[index] =
                                                    "Connect";
                                              });
                                              break;
                                          }
                                        }, onError: (Object error) {
                                          // Handle a possible error
                                        });
                                      } else {
                                        // Disconnect from the device
                                        connectionStream?.cancel();
                                        setState(() {
                                          connectionStatuses[index] = "Connect";
                                        });
                                      }
                                      print(foundDevices[index].id);
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            connectionStatuses[index] ==
                                                    "Disconnect"
                                                ? Colors.red
                                                : Colors.blue),
                                    child: Text(connectionStatuses[index])),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
            ),
            Expanded(
              child: Transform.scale(
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
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     flutterReactiveBle
      //         .connectToDevice(
      //       id: deviceId,
      //       servicesWithCharacteristicsToDiscover: {},
      //       connectionTimeout: const Duration(seconds: 5),
      //     )
      //         .listen((connectionState) {
      //       // Handle connection state updates
      //       print(connectionState.connectionState);
      //     }, onError: (Object error) {
      //       // Handle a possible error
      //     });
      //   },
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.bluetooth),
      // ),
    );
  }
}
