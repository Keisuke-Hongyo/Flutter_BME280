import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_ble/bluetooth.dart';
import 'package:sprintf/sprintf.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  //向き指定
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,//縦固定
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
  String tmpData="NaN";
  String humData="NaN";
  String pressData="NaN";

  final BleDevice ble = BleDevice(
      deviceName: 'tinygo ble peripheral',
      srvUuid: 'a0b40001-926d-4d61-98df-8c5c62ee53b3',
      txUUID: 'a0b40002-926d-4d61-98df-8c5c62ee53b3',
      rxUUID: 'a0b40003-926d-4d61-98df-8c5c62ee53b3');

  @override
  void initState() {
    List<int> data;
    List<double> bme280Data=[0.0,0.0,0.0];
    super.initState();
    ble.conectDevice();
    // 100msごとに受信処理
     Timer.periodic(
      // 第一引数：繰り返す間隔の時間を設定
      const Duration(milliseconds: 100),
      // 第二引数：その間隔ごとに動作させたい処理を書く
      (Timer timer) async{
       data = await ble.rcvData();
       bme280Data[0] = (((data[3].toUnsigned(32) << 24) +
           (data[2].toUnsigned(32) << 16) +
           (data[1].toUnsigned(32) << 8) +
           data[0].toUnsigned(32))
           .toInt()) /1000;

       bme280Data[1] = (((data[7].toUnsigned(32) << 24) +
           (data[6].toUnsigned(32) << 16) +
           (data[5].toUnsigned(32) << 8) +
           data[4].toUnsigned(32))
           .toInt()) /100;

       bme280Data[2] = (((data[11].toUnsigned(32) << 24) +
           (data[10].toUnsigned(32) << 16) +
           (data[9].toUnsigned(32) << 8) +
           data[8].toUnsigned(32))
           .toInt()) /100000;
       // 値更新
        setState(() {
          tmpData = sprintf("%5.2f ℃",[bme280Data[0]]);
          humData = sprintf("%5.2f %",[bme280Data[1]]);
          pressData = sprintf("%7.2f hPa",[bme280Data[2]]);
          if (data[12] == 0x00) {
            swstate = "OFF";
          } else {
            swstate = "ON";
          }
        });
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const <Widget>[
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
         /* センサー値表示部分 */
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Card(
              color: Colors.grey[200],
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children:  const <Widget>[
                      Padding(
                      padding: EdgeInsets.all(2.0),
                          child: Text('気温',
                            style: TextStyle(color: Colors.red, fontSize: 22),
                          ),
                        ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Text('$tmpData',
                          style: Theme.of(context).textTheme.headline5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Card(
              color: Colors.grey[200],
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children:  const <Widget>[
                      Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Text('湿度',
                          style: TextStyle(color: Colors.red, fontSize: 22),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Text('$humData',
                          style: Theme.of(context).textTheme.headline5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: Card(
              color: Colors.grey[200],
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children:  const <Widget>[
                      Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Text('気圧',
                          style: TextStyle(color: Colors.red, fontSize: 22),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Text('$pressData',
                          style: Theme.of(context).textTheme.headline5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: Card(
              color: Colors.grey[200],
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children:  const <Widget>[
                      Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Text('スイッチ',
                          style: TextStyle(color: Colors.red, fontSize: 22),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Text('$swstate',
                          style: Theme.of(context).textTheme.headline5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
