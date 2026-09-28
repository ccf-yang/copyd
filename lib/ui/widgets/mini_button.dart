import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum MiniTone { neutral, danger, success }

/// 卡片右侧的小圆角图标按钮（复制 / 清空 / 编辑 / 删除）。
class MiniButton extends StatelessWidget {
  const MiniButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tone = MiniTone.neutral,
    this.tooltip,
    this.size = 34,
  });

  final IconData icon;
  final VoidCallback onTap;
  final MiniTone tone;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    late final Color fg;
    late final Color bg;
    switch (tone) {
      case MiniTone.danger:
        fg = AppColors.danger;
        bg = p.dangerSoft;
        break;
      case MiniTone.success:
        fg = AppColors.success;
        bg = p.successSoft;
        break;
      case MiniTone.neutral:
        fg = p.isDark ? const Color(0xFFAEB4F0) : const Color(0xFF6B73C9);
        bg = p.isDark ? const Color(0xFF232742) : const Color(0xF2FFFFFF);
        break;
    }

    final Widget button = Material(
      color: bg,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 18, color: fg),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
