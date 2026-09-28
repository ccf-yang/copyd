import 'package:flutter/material.dart';

/// 居中悬浮提示（复制成功 / 参数校验）。
class AppToast {
  AppToast._();

  static OverlayEntry? _entry;

  static void show(
    BuildContext context,
    String title, {
    String? subtitle,
    bool success = true,
  }) {
    final OverlayState overlay = Overlay.of(context, rootOverlay: true);
    _entry?.remove();
    _entry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (BuildContext _) => _ToastView(
        title: title,
        subtitle: subtitle,
        success: success,
      ),
    );
    _entry = entry;
    overlay.insert(entry);

    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (_entry == entry) {
        entry.remove();
        _entry = null;
      }
    });
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({required this.title, this.subtitle, this.success = true});

  final String title;
  final String? subtitle;
  final bool success;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 180),
          child: Container(
            constraints: const BoxConstraints(minWidth: 180, maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
            decoration: BoxDecoration(
              color: const Color(0xEB161A2C),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 40,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.success
                          ? const <Color>[Color(0xFF12B76A), Color(0xFF31D98A)]
                          : const <Color>[Color(0xFFF04438), Color(0xFFF97066)],
                    ),
                  ),
                  child: Icon(
                    widget.success ? Icons.check_rounded : Icons.priority_high_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.subtitle != null) ...<Widget>[
                  const SizedBox(height: 5),
                  Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFC3C8DD),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 供设置页复用的一次性提示（不依赖 Store）。
void showToast(
  BuildContext context,
  String title, {
  String? subtitle,
  bool success = true,
}) =>
    AppToast.show(context, title, subtitle: subtitle, success: success);
