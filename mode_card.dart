import 'package:flutter/material.dart';
import 'app_theme.dart';

enum CarMode { manual, autonomous, autoParking }

class ModeCard extends StatelessWidget {
  final CarMode current;
  final ValueChanged<CarMode> onChanged;

  const ModeCard({super.key, required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('OPERATING MODE',
              style: TextStyle(fontSize: 10, color: AppTheme.textDim,
                  letterSpacing: 1.2, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Row(children: [
            _ModeBtn(
              label: 'Manual',
              icon: Icons.sports_esports_outlined,
              active: current == CarMode.manual,
              onTap: () => onChanged(CarMode.manual),
            ),
            const SizedBox(width: 6),
            _ModeBtn(
              label: 'Autonomous',
              icon: Icons.directions_car_outlined,
              active: current == CarMode.autonomous,
              onTap: () => onChanged(CarMode.autonomous),
            ),
            const SizedBox(width: 6),
            _ModeBtn(
              label: 'Auto-Park',
              icon: Icons.local_parking_outlined,
              active: current == CarMode.autoParking,
              onTap: () => onChanged(CarMode.autoParking),
            ),
          ]),
        ],
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ModeBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTheme.bgBlueDark : AppTheme.bgDeep,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? AppTheme.blueDark : AppTheme.borderColor,
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                size: 20,
                color: active ? AppTheme.blueLight : AppTheme.textMuted),
              const SizedBox(height: 4),
              Text(label,
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w500,
                  color: active ? AppTheme.blueLight : AppTheme.textMuted,
                )),
            ],
          ),
        ),
      ),
    );
  }
}
