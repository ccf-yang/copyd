import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../business/db/store.dart';
import '../../business/model/segment.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';
import 'mini_button.dart';

/// 固定文本块：使用态下半区的只读内容，支持复制 / 编辑 / 删除。
/// 使用态不参与拖拽（需要调序请进搭建模式）。
class FixedBlock extends StatelessWidget {
  const FixedBlock({
    super.key,
    required this.segment,
    this.onEdit,
  });

  final Segment segment;

  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final String text = segment.text;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.line),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: p.isDark ? Colors.black26 : const Color(0x0D101828),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text(
              text.isEmpty ? '（空文本）' : text,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.6,
                color: text.isEmpty ? p.muted2 : p.ink2,
              ),
            ),
          ),
          const SizedBox(width: 6),
          MiniButton(
            icon: Icons.content_copy_rounded,
            tooltip: '复制这段',
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (!context.mounted) return;
              AppToast.show(context, '已复制这段内容');
            },
          ),
          const SizedBox(width: 3),
          MiniButton(
            icon: Icons.edit_rounded,
            tooltip: '编辑',
            onTap: onEdit ?? () {},
          ),
          const SizedBox(width: 3),
          MiniButton(
            icon: Icons.delete_outline_rounded,
            tone: MiniTone.danger,
            tooltip: '删除',
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final AppPalette p = AppPalette.of(context);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('删除这段固定文本？', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text(
          segment.text,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: p.ink2, height: 1.6),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('取消', style: TextStyle(color: p.muted, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok == true) {
      Store.instance.removeSegment(segment.id);
    }
  }
}
