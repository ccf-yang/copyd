import 'package:flutter/material.dart';

import '../../business/model/segment.dart';
import '../theme/app_theme.dart';

/// 搭建画布上的一个句子片段。
class SegChip extends StatelessWidget {
  const SegChip({
    super.key,
    required this.segment,
    this.dragging = false,
    this.onRemove,
  });

  final Segment segment;
  final bool dragging;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final bool isVar = segment.isVariable;

    final Color bg = isVar
        ? (p.isDark ? const Color(0xFF232848) : const Color(0xFFEDEEFF))
        : p.surface;
    final Color border = isVar
        ? (p.isDark ? const Color(0xFF313763) : const Color(0xFFDCDEF9))
        : p.line;
    final Color fg = isVar
        ? (p.isDark ? const Color(0xFFB9BFFF) : const Color(0xFF4A52D6))
        : p.ink2;

    final String label = isVar
        ? '{${segment.name.isEmpty ? '未命名' : segment.name}}'
        : (segment.text.isEmpty ? '（空文本）' : segment.text);

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: EdgeInsets.fromLTRB(isVar ? 11 : 9, 8, onRemove == null ? 12 : 7, 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1.4),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        boxShadow: dragging
            ? const <BoxShadow>[
                BoxShadow(
                  color: Color(0x3310183C),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ]
            : <BoxShadow>[
                BoxShadow(
                  color: p.isDark ? Colors.black26 : const Color(0x0A101828),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!isVar)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Icon(Icons.drag_indicator_rounded, size: 14, color: p.muted2),
            ),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: fg),
            ),
          ),
          if (onRemove != null)
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.close_rounded, size: 13, color: p.muted),
              ),
            ),
        ],
      ),
    );
  }
}
