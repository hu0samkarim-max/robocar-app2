import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'bluetooth_service.dart';
import 'bt_picker_dialog.dart';
import 'battery_card.dart';
import 'mode_card.dart';
import 'manual_control_card.dart';
import 'autonomous_card.dart';
import 'parking_card.dart';
import 'sensor_card.dart';
import 'log_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _bt   = BluetoothService();
  CarMode _mode = CarMode.manual;

  @override
  void initState() {
    super.initState();
    _bt.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _bt.removeListener(_rebuild);
    _bt.dispose();
    super.dispose();
  }

  // ── Bluetooth connect/disconnect ─────────────────────────────────────────
  Future<void> _toggleBt() async {
    if (_bt.state == BtState.connected) {
      await _bt.disconnect();
      return;
    }
    final device = await showDialog(
      context: context,
      builder: (_) => BtPickerDialog(bt: _bt),
    );
    if (device != null) await _bt.connect(device);
  }

  // ── Mode change ──────────────────────────────────────────────────────────
  void _onModeChanged(CarMode m) {
    setState(() => _mode = m);
    const cmds = {
      CarMode.manual:     'MODE:M',
      CarMode.autonomous: 'MODE:A',
      CarMode.autoParking:'MODE:P',
    };
    _bt.send(cmds[m]!);
  }

  // ── Command from d-pad ────────────────────────────────────────────────────
  void _onCommand(String cmd) => _bt.send(cmd);

  @override
  Widget build(BuildContext context) {
    final connected = _bt.state == BtState.connected;
    final connecting = _bt.state == BtState.connecting;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            _TopBar(
              connected: connected,
              connecting: connecting,
              deviceName: _bt.deviceName,
              onBtTap: _toggleBt,
            ),
            // ── Scrollable content ───────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                children: [
                  BatteryCard(
                    pct: _bt.batteryPct,
                    volts: _bt.batteryVolts,
                    connected: connected,
                  ),
                  const SizedBox(height: 10),
                  ModeCard(current: _mode, onChanged: _onModeChanged),
                  const SizedBox(height: 10),
                  // Mode-specific panel
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _modePanel(connected),
                  ),
                  const SizedBox(height: 10),
                  SensorCard(
                    left:  _bt.sensorLeft,
                    front: _bt.sensorFront,
                    right: _bt.sensorRight,
                    connected: connected,
                  ),
                  const SizedBox(height: 10),
                  LogCard(logs: _bt.logs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modePanel(bool connected) {
    switch (_mode) {
      case CarMode.manual:
        return ManualControlCard(
          key: const ValueKey('manual'),
          connected: connected,
          onCommand: _onCommand,
        );
      case CarMode.autonomous:
        return AutonomousCard(
          key: const ValueKey('auto'),
          active: connected,
        );
      case CarMode.autoParking:
        return ParkingCard(
          key: const ValueKey('park'),
          connected: connected,
          bt: _bt,
        );
    }
  }
}

// ── Top app bar ──────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool   connected;
  final bool   connecting;
  final String deviceName;
  final VoidCallback onBtTap;

  const _TopBar({
    required this.connected, required this.connecting,
    required this.deviceName, required this.onBtTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 0.5)),
      ),
      child: Row(children: [
        const Icon(Icons.smart_toy_outlined, color: AppTheme.blueLight, size: 18),
        const SizedBox(width: 8),
        const Text('RoboCar 01',
          style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary, letterSpacing: 0.5,
          )),
        const Spacer(),
        GestureDetector(
          onTap: onBtTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: connected ? AppTheme.greenBg
                   : connecting ? AppTheme.bgBlueDark
                   : AppTheme.redBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: connected ? AppTheme.greenBorder
                     : connecting ? AppTheme.blueDark
                     : AppTheme.redBorder,
                width: 0.5,
              ),
            ),
            child: Row(children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: connected ? AppTheme.green
                       : connecting ? AppTheme.blueLight
                       : AppTheme.red,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                connecting  ? 'Connecting...'
                : connected ? deviceName.isNotEmpty
                    ? deviceName : 'Connected'
                : 'Disconnected',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500,
                  color: connected ? AppTheme.green
                       : connecting ? AppTheme.blueLight
                       : AppTheme.red,
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
