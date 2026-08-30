// lib/features/remote_input/presentation/remote_input_screen.dart
// Premium touch trackpad and remote keyboard screen (Zorin Connect / KDE Connect style).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../application/remote_input_service.dart';
import '../../../data/discovery/mdns_service.dart';

class RemoteInputScreen extends ConsumerStatefulWidget {
  const RemoteInputScreen({
    super.key,
    required this.peer,
  });

  final DiscoveredPeer peer;

  @override
  ConsumerState<RemoteInputScreen> createState() => _RemoteInputScreenState();
}

class _RemoteInputScreenState extends ConsumerState<RemoteInputScreen> {
  final TextEditingController _textInputCtrl = TextEditingController();
  final FocusNode _keyboardFocusNode = FocusNode();
  bool _isKeyboardOpen = false;
  double _sensitivity = 1.35;

  @override
  void dispose() {
    _textInputCtrl.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _sendMove(double dx, double dy) {
    RemoteInputService.instance.sendMouseMove(
      targetAddress: widget.peer.address,
      dx: dx * _sensitivity,
      dy: dy * _sensitivity,
    );
  }

  void _sendClick(String button) {
    HapticFeedback.lightImpact();
    RemoteInputService.instance.sendMouseClick(
      targetAddress: widget.peer.address,
      button: button,
    );
  }

  void _sendScroll(double dy) {
    RemoteInputService.instance.sendMouseScroll(
      targetAddress: widget.peer.address,
      dy: dy,
    );
  }

  void _sendKey(String key) {
    HapticFeedback.lightImpact();
    RemoteInputService.instance.sendKeyInput(
      targetAddress: widget.peer.address,
      key: key,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Remote Trackpad', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text(
              'Controlling ${widget.peer.displayName}',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isKeyboardOpen ? Icons.keyboard_hide_rounded : Icons.keyboard_rounded),
            tooltip: 'Remote Keyboard',
            onPressed: () {
              setState(() => _isKeyboardOpen = !_isKeyboardOpen);
              if (_isKeyboardOpen) {
                _keyboardFocusNode.requestFocus();
              } else {
                _keyboardFocusNode.unfocus();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Sensitivity',
            onPressed: _showSensitivityDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Soft keyboard input bar if active
            if (_isKeyboardOpen) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
                color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textInputCtrl,
                        focusNode: _keyboardFocusNode,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Type to send to ${widget.peer.displayName}…',
                          hintStyle: const TextStyle(fontSize: 13),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                          ),
                        ),
                        onChanged: (text) {
                          if (text.isNotEmpty) {
                            RemoteInputService.instance.sendKeyInput(
                              targetAddress: widget.peer.address,
                              text: text,
                            );
                            _textInputCtrl.clear();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    _KeyBtn(label: '⌫', onTap: () => _sendKey('BACKSPACE')),
                    const SizedBox(width: 4),
                    _KeyBtn(label: '↵', onTap: () => _sendKey('ENTER')),
                    const SizedBox(width: 4),
                    _KeyBtn(label: 'Tab', onTap: () => _sendKey('TAB')),
                    const SizedBox(width: 4),
                    _KeyBtn(label: 'Esc', onTap: () => _sendKey('ESCAPE')),
                  ],
                ),
              ),
            ],

            // Main Trackpad Area + Right-side Scroll Wheel
            Expanded(
              child: Row(
                children: [
                  // Trackpad
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cs.outline.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) => _sendMove(details.delta.dx, details.delta.dy),
                        onTap: () => _sendClick('left'),
                        onDoubleTap: () => _sendClick('double'),
                        onLongPress: () => _sendClick('right'),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app_outlined, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                              const SizedBox(height: 8),
                              Text(
                                'Trackpad',
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '1-finger drag: move  •  Tap: click  •  Hold: right click',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Side Scroll Strip
                  Container(
                    width: 44,
                    margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm, right: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cs.outline.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (details) => _sendScroll(details.delta.dy),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Icon(Icons.keyboard_arrow_up_rounded, color: cs.onSurfaceVariant),
                            RotatedBox(
                              quarterTurns: 3,
                              child: Text(
                                'SCROLL',
                                style: tt.labelSmall?.copyWith(
                                  letterSpacing: 2,
                                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down_rounded, color: cs.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Left and Right Click Bottom Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 54,
                      child: FilledButton.tonal(
                        onPressed: () => _sendClick('left'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Left Click', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () => _sendClick('right'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Right Click', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSensitivityDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Trackpad Sensitivity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: _sensitivity,
                min: 0.5,
                max: 3.0,
                divisions: 10,
                label: _sensitivity.toStringAsFixed(1),
                onChanged: (val) {
                  setDlgState(() => _sensitivity = val);
                  setState(() => _sensitivity = val);
                },
              ),
              Text('${_sensitivity.toStringAsFixed(1)}x speed'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
          ],
        ),
      ),
    );
  }
}

class _KeyBtn extends StatelessWidget {
  const _KeyBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
      ),
    );
  }
}
