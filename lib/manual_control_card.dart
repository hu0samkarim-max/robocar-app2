import 'package:flutter/material.dart';
import 'app_theme.dart';

class ManualControlCard extends StatefulWidget {
  final bool connected;

  /// Called with command string, e.g. "F4", "B3", "L2", "R5", "S0"
  final ValueChanged<String> onCommand;

  const ManualControlCard({
    super.key,
    required this.connected,
    required this.onCommand,
  });

  @override
  State<ManualControlCard> createState() => _ManualControlCardState();
}

class _ManualControlCardState extends State<ManualControlCard> {
  int    _speed   = 4;   // 1-9
  String _active  = '';  // 'F','B','L','R',''

  void _press(String dir) {
    if (!widget.connected) return;
    if (_active == dir) return;
    setState(() => _active = dir);
    widget.onCommand('$dir$_speed');
  }

  void _release() {
    if (_active.isEmpty) return;
    setState(() => _active = '');
    widget.onCommand('S0');
  }

  void _changeSpeed(int delta) {
    setState(() {
      _speed = (_speed + delta).clamp(1, 9);
    });
    if (widget.connected) widget.onCommand('SPD:$_speed');
  }

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
          const Text('DRIVE CONTROL',
              style: TextStyle(fontSize: 10, color: AppTheme.textDim,
                  letterSpacing: 1.2, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // D-pad
              SizedBox(
                width: 160,
                height: 160,
                child: GridView.count(
                  crossAxisCount: 3,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  children: [
                    const SizedBox(),
                    _DpadBtn(icon: Icons.keyboard_arrow_up,    dir: 'F', active: _active, onPress: _press, onRelease: _release),
                    const SizedBox(),
                    _DpadBtn(icon: Icons.keyboard_arrow_left,  dir: 'L', active: _active, onPress: _press, onRelease: _release),
                    // Center indicator
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.bgDeep,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor, width: 0.5),
                      ),
                      child: Center(
                        child: Text(
                          _active.isEmpty ? '■' : {'F':'↑','B':'↓','L':'←','R':'→'}[_active]!,
                          style: TextStyle(
                            fontSize: 16,
                            color: _active.isEmpty
                                ? AppTheme.textDim
                                : AppTheme.blueLight,
                          ),
                        ),
                      ),
                    ),
                    _DpadBtn(icon: Icons.keyboard_arrow_right, dir: 'R', active: _active, onPress: _press, onRelease: _release),
                    const SizedBox(),
                    _DpadBtn(icon: Icons.keyboard_arrow_down,  dir: 'B', active: _active, onPress: _press, onRelease: _release),
                    const SizedBox(),
                  ],
                ),
              ),
              // Speed panel
              _SpeedPanel(
                speed: _speed,
                onUp:   () => _changeSpeed(1),
                onDown: () => _changeSpeed(-1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── D-pad button ─────────────────────────────────────────────────────────────
class _DpadBtn extends StatelessWidget {
  final IconData icon;
  final String   dir;
  final String   active;
  final ValueChanged<String> onPress;
  final VoidCallback onRelease;

  const _DpadBtn({
    required this.icon, required this.dir, required this.active,
    required this.onPress, required this.onRelease,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = active == dir;
    return GestureDetector(
      onTapDown:     (_) => onPress(dir),
      onTapUp:       (_) => onRelease(),
      onTapCancel:       () => onRelease(),
      onLongPressStart: (_) => onPress(dir),
      onLongPressEnd:   (_) => onRelease(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.blueDark : AppTheme.bgBlue,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderBlue, width: 0.5),
        ),
        child: Center(
          child: Icon(icon, color: AppTheme.blueLight, size: 22),
        ),
      ),
    );
  }
}

// ── Speed panel ───────────────────────────────────────────────────────────────
class _SpeedPanel extends StatelessWidget {
  final int speed;
  final VoidCallback onUp;
  final VoidCallback onDown;

  const _SpeedPanel({required this.speed, required this.onUp, required this.onDown});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Speed', style: TextStyle(fontSize: 11, color: AppTheme.textDim)),
        const SizedBox(height: 6),
        _SpeedBtn(icon: Icons.add, onTap: onUp),
        const SizedBox(height: 6),
        // Vertical track
        SizedBox(
          width: 6, height: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: RotatedBox(
              quarterTurns: 2,
              child: LinearProgressIndicator(
                value: speed / 9,
                minHeight: 6,
                backgroundColor: AppTheme.borderColor,
                valueColor: const AlwaysStoppedAnimation(AppTheme.blue),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        _SpeedBtn(icon: Icons.remove, onTap: onDown),
        const SizedBox(height: 6),
        Text('$speed',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary)),
      ],
    );
  }
}

class _SpeedBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SpeedBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppTheme.bgBlue,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderBlue, width: 0.5),
        ),
        child: Icon(icon, color: AppTheme.blueLight, size: 18),
      ),
    );
  }
}
