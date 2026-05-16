import 'dart:async';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'bluetooth_service.dart';

class ParkingCard extends StatefulWidget {
  final bool connected;
  final BluetoothService bt;

  const ParkingCard({super.key, required this.connected, required this.bt});

  @override
  State<ParkingCard> createState() => _ParkingCardState();
}

class _ParkingCardState extends State<ParkingCard> {
  int _phase = -1; // -1 = idle, 0-3 active
  Timer? _timer;
  bool _running = false;

  static const _phases = [
    (icon: Icons.radar_outlined,         label: 'Scan'),
    (icon: Icons.arrow_forward_outlined, label: 'Approach'),
    (icon: Icons.rotate_right_outlined,  label: 'Maneuver'),
    (icon: Icons.check_circle_outline,   label: 'Done'),
  ];

  static const _msgs = [
    'Scanning for slot...',
    'Approaching slot...',
    'Executing maneuver...',
    'Parking complete ✓',
  ];

  void _start() {
    if (_running || !widget.connected) return;
    setState(() { _phase = 0; _running = true; });
    widget.bt.send('MODE:P');
    _step();
  }

  void _step() {
    if (_phase >= _phases.length) {
      setState(() => _running = false);
      return;
    }
    widget.bt.addExternalLog('info', _msgs[_phase]);
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _phase++);
      _step();
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PARKING SEQUENCE',
              style: TextStyle(fontSize: 10, color: AppTheme.textDim,
                  letterSpacing: 1.2, fontWeight: FontWeight.w500)),
          const SizedBox(height: 14),
          // Phase stepper
          Row(
            children: List.generate(_phases.length * 2 - 1, (i) {
              if (i.isOdd) {
                // Connector line
                final phaseIdx = i ~/ 2;
                final done = _phase > phaseIdx + 1;
                return Expanded(
                  child: Container(
                    height: 1.5,
                    color: done ? AppTheme.green : AppTheme.borderColor,
                    margin: const EdgeInsets.only(bottom: 20),
                  ),
                );
              }
              final phaseIdx = i ~/ 2;
              final isDone   = _phase > phaseIdx;
              final isActive = _phase == phaseIdx;
              return _PhaseDot(
                icon:   _phases[phaseIdx].icon,
                label:  _phases[phaseIdx].label,
                active: isActive,
                done:   isDone,
              );
            }),
          ),
          const SizedBox(height: 14),
          // Start button
          GestureDetector(
            onTap: _start,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _running ? AppTheme.bgBlueDark : AppTheme.bgBlue,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderBlue, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_running ? Icons.hourglass_top : Icons.play_arrow,
                    color: AppTheme.blueLight, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _running ? 'Parking in progress...' : 'Start Parking Sequence',
                    style: const TextStyle(
                      fontSize: 12, color: AppTheme.blueLight,
                      fontWeight: FontWeight.w500),
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

class _PhaseDot extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     active;
  final bool     done;

  const _PhaseDot({
    required this.icon, required this.label,
    required this.active, required this.done,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, border, fg;
    if (done) {
      bg = AppTheme.greenBg; border = AppTheme.greenBorder; fg = AppTheme.green;
    } else if (active) {
      bg = AppTheme.bgBlueDark; border = AppTheme.blueDark; fg = AppTheme.blueLight;
    } else {
      bg = AppTheme.bgDeep; border = AppTheme.borderColor; fg = AppTheme.textDim;
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: bg, shape: BoxShape.circle,
            border: Border.all(color: border, width: 1.5),
          ),
          child: Icon(icon, size: 14, color: fg),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 9, color: fg)),
      ],
    );
  }
}
