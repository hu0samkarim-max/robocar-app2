import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

enum BtState { disconnected, scanning, connecting, connected }

class BluetoothService extends ChangeNotifier {
  // ── Public state ─────────────────────────────────────────────────────────
  BtState state         = BtState.disconnected;
  String  deviceName    = '';
  int     batteryPct    = 0;
  double  batteryVolts  = 0.0;
  int     sensorLeft    = 0;
  int     sensorFront   = 0;
  int     sensorRight   = 0;
  final List<String> logs = [];

  // ── Private ───────────────────────────────────────────────────────────────
  BluetoothConnection? _conn;
  String _buffer = '';

  // ── Connection ────────────────────────────────────────────────────────────
  Future<List<BluetoothDevice>> scanDevices() async {
    await _requestPermissions();
    final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
    return bonded;
  }

  Future<void> connect(BluetoothDevice device) async {
    if (state == BtState.connected) await disconnect();
    state = BtState.connecting;
    notifyListeners();
    try {
      _conn = await BluetoothConnection.toAddress(device.address)
          .timeout(const Duration(seconds: 10));
      deviceName = device.name ?? device.address;
      state = BtState.connected;
      _addLog('ok', 'Connected — ${device.name}');
      _addLog('info', 'Waiting for data...');
      _conn!.input!.listen(_onData, onDone: () {
        _addLog('warn', 'Connection closed');
        _handleDisconnect();
      }, onError: (_) {
        _addLog('warn', 'Connection error');
        _handleDisconnect();
      });
      notifyListeners();
    } catch (e) {
      state = BtState.disconnected;
      _addLog('warn', 'Failed to connect: $e');
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _conn?.close();
    _conn = null;
    _handleDisconnect();
  }

  void _handleDisconnect() {
    state = BtState.disconnected;
    deviceName = '';
    notifyListeners();
  }

  // ── Send ──────────────────────────────────────────────────────────────────
  void send(String cmd) {
    if (state != BtState.connected || _conn == null) {
      _addLog('warn', 'Not connected');
      return;
    }
    try {
      _conn!.output.add(Uint8List.fromList('$cmd\n'.codeUnits));
      _addLog('info', 'TX → $cmd');
    } catch (_) {
      _addLog('warn', 'Send failed');
    }
  }

  // ── Receive ───────────────────────────────────────────────────────────────
  void _onData(Uint8List data) {
    _buffer += String.fromCharCodes(data);
    while (_buffer.contains('\n')) {
      final idx = _buffer.indexOf('\n');
      final line = _buffer.substring(0, idx).trim();
      _buffer = _buffer.substring(idx + 1);
      _parseLine(line);
    }
  }

  /// Protocol (Arduino → App):
  ///   BAT:<pct>,<volts>   e.g. BAT:78,7.6
  ///   SNS:<left>,<front>,<right>   e.g. SNS:80,45,75
  void _parseLine(String line) {
    if (line.startsWith('BAT:')) {
      final parts = line.substring(4).split(',');
      if (parts.length >= 2) {
        batteryPct   = int.tryParse(parts[0]) ?? batteryPct;
        batteryVolts = double.tryParse(parts[1]) ?? batteryVolts;
        _addLog('ok', 'RX ← $line');
        notifyListeners();
      }
    } else if (line.startsWith('SNS:')) {
      final parts = line.substring(4).split(',');
      if (parts.length >= 3) {
        sensorLeft  = int.tryParse(parts[0]) ?? sensorLeft;
        sensorFront = int.tryParse(parts[1]) ?? sensorFront;
        sensorRight = int.tryParse(parts[2]) ?? sensorRight;
        notifyListeners();
      }
    } else if (line.isNotEmpty) {
      _addLog('info', 'RX ← $line');
    }
  }

  // ── Logging ───────────────────────────────────────────────────────────────
  void _addLog(String type, String msg) {
    final prefix = type == 'ok' ? '✓' : type == 'warn' ? '⚠' : '›';
    logs.add('$prefix $msg');
    if (logs.length > 20) logs.removeAt(0);
    notifyListeners();
  }

  void addExternalLog(String type, String msg) => _addLog(type, msg);

  // ── Permissions ───────────────────────────────────────────────────────────
  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
  }
}
