import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_ble/bluetooth.dart';
import 'package:sprintf/sprintf.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  //向き指定
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, //縦固定
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
      home: const MyHomePage(title: 'BME280 テストアプリ'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // センサー値とLED制御変数
  int _ledState = 0x00;
  String swstate = "NaN";
  String tmpData = "NaN";
  String humData = "NaN";
  String pressData = "NaN";

  final BleDevice ble = BleDevice(
      deviceName: 'tinygo ble peripheral',
      srvUuid: 'a0b40001-926d-4d61-98df-8c5c62ee53b3',
      txUUID: 'a0b40002-926d-4d61-98df-8c5c62ee53b3',
      rxUUID: 'a0b40003-926d-4d61-98df-8c5c62ee53b3');

  @override
  void initState() {
    super.initState();
    ble.conectDevice();
  }

  @override
  void dispose() {
    super.dispose();
  }
  final PageController controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          // LED Control
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Card(
              /*width: double.infinity,
            height: 120,*/
                color: Colors.grey[200],
                child: Column(
                  children: <Widget>[
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'LED Control',
                          style: TextStyle(color: Colors.red, fontSize: 30),
                        ),
                      ],
                    ),
                    Row(
                      // 中央寄せ
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        //LED1
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                if ((_ledState & 0x01) == 0x00) {
                                  _ledState |= 0x01;
                                } else {
                                  _ledState &= 0xfe;
                                }
                                ble.wData([_ledState]);
                              });
                            },
                            child: const Text(
                              'LED1',
                              style:
                              TextStyle(color: Colors.white, fontSize: 30),
                            ),
                          ),
                        ),
                        //LED2
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                if ((_ledState & 0x02) == 0x00) {
                                  _ledState |= 0x02;
                                } else {
                                  _ledState &= 0xfd;
                                }
                                ble.wData([_ledState]);
                              });
                            },
                            child: const Text(
                              'LED2',
                              style:
                              TextStyle(color: Colors.white, fontSize: 30),
                            ),
                          ),
                        ),
                        //LED3
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                if ((_ledState & 0x04) == 0x00) {
                                  _ledState |= 0x04;
                                } else {
                                  _ledState &= 0xfb;
                                }
                                ble.wData([_ledState]);
                              });
                            },
                            child: const Text(
                              'LED3',
                              style:
                              TextStyle(color: Colors.white, fontSize: 30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )),
          ),
          // スイッチ
          StreamBuilder(
              stream: ble.s.stream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var data = snapshot.data as List<int>;
                  if (data[12] == 0x00) {
                    swstate = "OFF";
                  } else {
                    swstate = "ON";
                  }
                }
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Card(
                    color: Colors.grey[200],
                    child: Column(
                      children: <Widget>[
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.all(2.0),
                              child: Text(
                                'スイッチ',
                                style:
                                TextStyle(color: Colors.red, fontSize: 22),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Text(
                                '$swstate',
                                style: Theme.of(context).textTheme.headline5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          /* センサー値表示部分(Stream仕様) */
          SizedBox(
            height: 300,
            child: PageView(
              controller: controller,
              children: [
                // 気温
                StreamBuilder(
                    stream: ble.s.stream,
                    builder: (context, snapshot) {
                      double temp = 0.0;
                      if (snapshot.hasData) {
                        var data = snapshot.data as List<int>;
                        temp = (((data[3].toUnsigned(32) << 24) +
                            (data[2].toUnsigned(32) << 16) +
                            (data[1].toUnsigned(32) << 8) +
                            data[0].toUnsigned(32))
                            .toInt()) /
                            1000;
                        tmpData = sprintf("%5.2f ℃", [temp]);
                      }
                      return SfRadialGauge(
                          title: const GaugeTitle(
                              text: '温度',
                              textStyle: TextStyle(
                                  fontSize: 20.0, fontWeight: FontWeight.bold)),
                          axes: <RadialAxis>[
                            RadialAxis(minimum: 0, maximum: 60, ranges: <GaugeRange>[
                              GaugeRange(
                                  startValue: 0,
                                  endValue: 10,
                                  color: Colors.blue,
                                  startWidth: 5,
                                  endWidth: 5),
                              GaugeRange(
                                  startValue: 10,
                                  endValue: 30,
                                  color: Colors.green,
                                  startWidth: 5,
                                  endWidth: 5),
                              GaugeRange(
                                  startValue: 30,
                                  endValue: 60,
                                  color: Colors.red,
                                  startWidth: 5,
                                  endWidth: 5)
                            ], pointers: <GaugePointer>[
                              NeedlePointer(value: temp)
                            ], annotations: <GaugeAnnotation>[
                              GaugeAnnotation(
                                  widget: Text(tmpData,
                                      style: const TextStyle(
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold)),
                                  angle: 90,
                                  positionFactor: 0.5)
                            ])
                          ]);
                    }),
                // 湿度
                StreamBuilder(
                    stream: ble.s.stream,
                    builder: (context, snapshot) {
                      double hum = 0.0;
                      if (snapshot.hasData) {
                        var data = snapshot.data as List<int>;
                        hum = (((data[7].toUnsigned(32) << 24) +
                            (data[6].toUnsigned(32) << 16) +
                            (data[5].toUnsigned(32) << 8) +
                            data[4].toUnsigned(32))
                            .toInt()) /
                            100;
                        humData = sprintf("%5.2f %", [hum]);
                      }
                      return SfRadialGauge(
                          title: const GaugeTitle(
                              text: '湿度',
                              textStyle: TextStyle(
                                  fontSize: 20.0, fontWeight: FontWeight.bold)),
                          axes: <RadialAxis>[
                            RadialAxis(minimum: 0, maximum: 100, ranges: <GaugeRange>[
                              GaugeRange(
                                  startValue: 0,
                                  endValue: 20,
                                  color: Colors.green,
                                  startWidth: 10,
                                  endWidth: 10),
                              GaugeRange(
                                  startValue: 20,
                                  endValue: 60,
                                  color: Colors.orange,
                                  startWidth: 10,
                                  endWidth: 10),
                              GaugeRange(
                                  startValue: 60,
                                  endValue: 100,
                                  color: Colors.red,
                                  startWidth: 10,
                                  endWidth: 10)
                            ], pointers: <GaugePointer>[
                              NeedlePointer(value: hum)
                            ], annotations: <GaugeAnnotation>[
                              GaugeAnnotation(
                                  widget: Container(
                                      child: Text(humData,
                                          style: const TextStyle(
                                              fontSize: 25,
                                              fontWeight: FontWeight.bold))),
                                  angle: 90,
                                  positionFactor: 0.5)
                            ])
                          ]);

                    }),
                // 気圧
                StreamBuilder(
                    stream: ble.s.stream,
                    builder: (context, snapshot) {
                      double press = 0.0;
                      if (snapshot.hasData) {
                        var data = snapshot.data as List<int>;
                        press = (((data[11].toUnsigned(32) << 24) +
                            (data[10].toUnsigned(32) << 16) +
                            (data[9].toUnsigned(32) << 8) +
                            data[8].toUnsigned(32))
                            .toInt()) /
                            100000;
                        pressData = sprintf("%5.2f hPa", [press]);
                      }
                      return SfRadialGauge(
                          title: const GaugeTitle(
                              text: '気圧',
                              textStyle: TextStyle(
                                  fontSize: 20.0, fontWeight: FontWeight.bold)),
                          axes: <RadialAxis>[
                            RadialAxis(minimum: 900, maximum: 1200, ranges: <GaugeRange>[
                              GaugeRange(
                                  startValue: 900,
                                  endValue: 1000,
                                  color: Colors.blue,
                                  startWidth: 10,
                                  endWidth: 10),
                              GaugeRange(
                                  startValue: 1000,
                                  endValue: 1100,
                                  color: Colors.green,
                                  startWidth: 10,
                                  endWidth: 10),
                              GaugeRange(
                                  startValue: 1100,
                                  endValue: 1200,
                                  color: Colors.red,
                                  startWidth: 10,
                                  endWidth: 10)
                            ], pointers: <GaugePointer>[
                              NeedlePointer(value: press)
                            ], annotations: <GaugeAnnotation>[
                              GaugeAnnotation(
                                  widget: Text(pressData,
                                      style: const TextStyle(
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold)),
                                  angle: 90,
                                  positionFactor: 0.5)
                            ])
                          ]);
                    }),
              ],
            ),
          ),
        ],
      )
    );
  }
}
