import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

/// A sign-in code as a row of boxes, one digit in each. One text field sits
/// over the boxes and takes the typing, so the keyboard's code suggestion,
/// pasting and backspace all work as in a plain field; the boxes only show
/// what it holds. The box being typed into is outlined with a blinking caret.
class CodeBoxes extends StatefulWidget {
  const CodeBoxes({super.key, required this.controller, this.length = 6, this.onCompleted, this.autofocus = true});

  final TextEditingController controller;
  final int length;

  /// Called once every box is filled.
  final ValueChanged<String>? onCompleted;
  final bool autofocus;

  @override
  State<CodeBoxes> createState() => _CodeBoxesState();
}

class _CodeBoxesState extends State<CodeBoxes> with SingleTickerProviderStateMixin {
  final _focus = FocusNode();
  late final AnimationController _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(_changed);
  }

  @override
  void didUpdateWidget(CodeBoxes old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    _blink.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final n = widget.length;
    final active = _focus.hasFocus ? min(text.length, n - 1) : -1;
    // Digits read left to right in every language.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: 60,
        child: Stack(children: [
          Row(children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) SizedBox(width: n == 6 && i == 3 ? 14 : 8),
              Expanded(child: _box(i < text.length ? text[i] : null, i == active)),
            ],
          ]),
          // The field that takes the typing, invisible over the boxes.
          Positioned.fill(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(n)],
              showCursor: false,
              cursorColor: Colors.transparent,
              style: const TextStyle(color: Colors.transparent, fontSize: 1, height: 1),
              decoration: const InputDecoration.collapsed(hintText: ''),
              onChanged: (v) {
                if (v.length == n) widget.onCompleted?.call(v);
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _box(String? digit, bool active) {
    final filled = digit != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: filled ? K.brand100 : K.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? K.green : (filled ? K.brand200 : K.border), width: active ? 2 : 1.2),
        boxShadow: active ? [BoxShadow(color: K.green.withValues(alpha: 0.14), blurRadius: 12, spreadRadius: 1)] : const [],
      ),
      alignment: Alignment.center,
      child: filled
          ? Text(digit, style: const TextStyle(fontFamily: 'Manrope', fontSize: 26, fontWeight: FontWeight.w800, color: K.ink, height: 1).merge(T.tabular))
          : (active
              ? FadeTransition(
                  opacity: _blink.drive(CurveTween(curve: const _Blink())),
                  child: Container(width: 2, height: 26, decoration: BoxDecoration(color: K.green, borderRadius: BorderRadius.circular(1))),
                )
              : null),
    );
  }
}

/// On for the first half of each second, off for the second half.
class _Blink extends Curve {
  const _Blink();

  @override
  double transformInternal(double t) => t < 0.55 ? 1 : 0;
}
