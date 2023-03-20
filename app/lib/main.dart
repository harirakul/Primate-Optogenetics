import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:convert';
import 'package:syncfusion_flutter_charts/charts.dart';

final flutterReactiveBle = FlutterReactiveBle();
String deviceId = "D0:94:42:C9:97:E5";
String connectionStatus = "Connect";
//String deviceId = "C7:23:46:15:6A:50";
List foundDevices = [];
List foundDeviceIds = [];
List connectionStatuses = [];
var connectionStream;
String adcVal = "-";
List<ADCData> chartData = [];
bool readADC = false;
String readMessage = "Read";

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
      home: MyHomePage(title: 'Primate Optogenetics'),
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
                      //print(error);
                      //code for handling error
                    });
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40)),
                  child: const Text("SCAN")),
            ),
            Expanded(
              child: Scrollbar(
                thickness: 8,
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
                                  ElevatedButton.icon(
                                      icon: const Icon(Icons.bluetooth),
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
                                            switch (connectionState
                                                .connectionState) {
                                              case DeviceConnectionState
                                                  .connecting:
                                                print(
                                                    "-- Connecting to device --");
                                                break;

                                              case DeviceConnectionState
                                                  .connected:
                                                print(" -- Connected --");
                                                deviceId =
                                                    foundDevices[index].id;
                                                setState(() {
                                                  connectionStatuses[index] =
                                                      "Disconnect";
                                                  connectionStatus =
                                                      "Disconnect";
                                                });
                                                final characteristic =
                                                    QualifiedCharacteristic(
                                                        serviceId: Uuid.parse(
                                                            "6e400001-b5a3-f393-e0a9-e50e24dcca9e"),
                                                        characteristicId:
                                                            Uuid.parse(
                                                                "6e400003-b5a3-f393-e0a9-e50e24dcca9e"),
                                                        deviceId: deviceId);
                                                flutterReactiveBle
                                                    .subscribeToCharacteristic(
                                                        characteristic)
                                                    .listen((data) {
                                                  //print(data);
                                                  List<String> split = utf8
                                                      .decode(data)
                                                      .split(' ');

                                                  setState(() {
                                                    if (readADC) {
                                                      adcVal =
                                                          utf8.decode(data);
                                                      chartData.add(ADCData(
                                                          DateTime.now(),
                                                          double.parse(split
                                                              .elementAt(1))));
                                                    }
                                                  });
                                                  // code to handle incoming data
                                                }, onError: (dynamic error) {
                                                  // code to handle errors
                                                });
                                                break;

                                              case DeviceConnectionState
                                                  .disconnecting:
                                                print("-- disconnecting --");
                                                connectionStatus = "Connect";
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
                                            print(error);
                                          });
                                        } else {
                                          // Disconnect from the device
                                          connectionStream?.cancel();
                                          setState(() {
                                            connectionStatuses[index] =
                                                "Connect";
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
                                      label: Text(connectionStatuses[index])),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Container(
              child: SfCartesianChart(
                  title: ChartTitle(
                      text: 'Sensor Values',
                      // Aligns the chart title to left
                      textStyle: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  primaryXAxis: DateTimeAxis(
                      title: AxisTitle(
                    text: 'Time',
                  )),
                  series: <ChartSeries>[
                    // Renders line chart
                    LineSeries<ADCData, DateTime>(
                        dataSource: chartData,
                        xValueMapper: (ADCData adc, _) => adc.time,
                        yValueMapper: (ADCData adc, _) => adc.value)
                  ]),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                      child: Card(
                          child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "ADC Value:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                adcVal,
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if (readADC) {
                                readMessage = "Read";
                                readADC = false;
                              } else {
                                readADC = true;
                                readMessage = "Stop";
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: readMessage == "Stop"
                                  ? Colors.red
                                  : Colors.blue),
                          child: Text(readMessage),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              chartData = [];
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ))),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  const Expanded(
                    child: Text(''),
                  ),
                  const Expanded(
                    child: Text(
                      'LED Switch',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  Expanded(
                    child: Transform.scale(
                      scale: 2,
                      child: Switch(
                        value: lightStatus,
                        onChanged: (bool value) {
                          print(connectionStatus);
                          if (connectionStatus == "Disconnect") {
                            updateLED(value);
                            setState(() {
                              lightStatus = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(''),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ADCData {
  ADCData(this.time, this.value);
  final DateTime time;
  final double value;
}
