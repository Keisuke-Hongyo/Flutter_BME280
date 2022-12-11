import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleDevice {
  /* 機器設定用 */
  final String deviceName;
  final String srvUuid;
  final String txUUID;
  final String rxUUID;

  /* コンストラクタ */
  BleDevice(
      {required this.deviceName,
      required this.srvUuid,
      required this.txUUID,
      required this.rxUUID});

  final FlutterReactiveBle ble = FlutterReactiveBle();
  late QualifiedCharacteristic qlChr1, qlChr2;

  Future<void> conectDevice() async {
    var device = await FlutterReactiveBle().scanForDevices(
        withServices: [],
        scanMode: ScanMode
            .lowLatency).firstWhere((device) => device.name == deviceName);

    ble.connectToDevice(
            id: device.id,
            servicesWithCharacteristicsToDiscover: {},
            connectionTimeout: const Duration(seconds: 2))
        .listen((state) async {

      /*ble.connectToAdvertisingDevice(
          id: device.id, prescanDuration: const Duration(seconds: 1),
          withServices: [srvUuid,characteristicUuid]).listen((state) async {
            print('State: ${state.toString()}');*/

      if (state.connectionState == DeviceConnectionState.connected) {
        await ble.discoverServices(device.id);
      }

      qlChr1 = QualifiedCharacteristic(
          serviceId: Uuid.parse(srvUuid),
          characteristicId: Uuid.parse(txUUID),
          deviceId: device.id);

      qlChr2 = QualifiedCharacteristic(
          serviceId: Uuid.parse(srvUuid),
          characteristicId: Uuid.parse(rxUUID),
          deviceId: device.id);
      }, onError: (dynamic error) {
      print(error.toString());
    });
  }

  Future<void> wData(List<int> value) async {
    await ble.writeCharacteristicWithoutResponse(qlChr1, value: value);
  }


  /* Stream<int> rData() async* {
    ble.subscribeToCharacteristic(qlChr2).listen((data) {
      // code to handle incoming data
    /*  print(((data[3].toUnsigned(32)<<24)
            + (data[2].toUnsigned(32)<<16)
            + (data[1].toUnsigned(32)<<8)
            + data[0].toUnsigned(32)).toInt());*/ /*
      temp = ((data[3].toUnsigned(32)<<24) + (data[2].toUnsigned(32)<<16)
            + (data[1].toUnsigned(32)<<8)  + data[0].toUnsigned(32)).toInt();
    }, onError: (dynamic error) {
      // code to handle errors
    });
    print(temp);
    yield temp;
  }*/
  */

  Future<List<int>> rcvData() async {
    List<int> data;
    data = await _rData();
    return data;
  }

  Future<List<int>> _rData() async {
    return await ble.readCharacteristic(qlChr2).then((value) => value);
  }

  Future<List<int>> isledState() async {
    return await ble.readCharacteristic(qlChr1).then((value) => value);
  }
}
