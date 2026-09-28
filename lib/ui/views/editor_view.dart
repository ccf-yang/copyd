import 'package:flutter/material.dart';

import '../../business/db/store.dart';
import '../../business/model/segment.dart';
import '../../business/model/template.dart';
import '../theme/app_theme.dart';
import '../widgets/fixed_block.dart';
import '../widgets/sheets.dart';
import '../widgets/variable_card.dart';

/// 主界面 · 使用态：上=变量，下=固定文本。
class EditorView extends StatelessWidget {
  const EditorView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Store.instance,
      builder: (BuildContext context, Widget? _) {
        final Store store = Store.instance;
        final Template? t = store.active;
        if (t == null) return const SizedBox.shrink();

        final List<Segment> vars = t.variables;
        final List<Segment> fixed = t.fixedSegments;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            _SectionHeader(
              label: '变量',
              count: vars.length,
              trailing: vars.isEmpty ? null : '全部清空',
              onTrailing: store.clearAllValues,
            ),
            if (vars.isEmpty)
              const _EmptyHint(
                icon: Icons.data_object_rounded,
                text: '还没有变量，点右上角「＋ 添加变量」',
              )
            else
              ...vars.map(
                (Segment s) => VariableCard(key: ValueKey<String>(s.id), segment: s),
              ),
            _SectionHeader(
              label: '固定文本',
              count: fixed.length,
              trailing: '＋ 添加',
              onTrailing: () => showAddFixedSheet(context),
              topGap: 22,
            ),
            if (fixed.isEmpty)
              _EmptyHint(
                icon: Icons.text_fields_rounded,
                text: '还没有固定文本',
                actionText: '添加固定文本',
                onAction: () => showAddFixedSheet(context),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: fixed.length,
                onReorder: (int oldIndex, int newIndex) =>
                    store.reorderByType(SegmentType.fixed, oldIndex, newIndex),
                itemBuilder: (BuildContext context, int i) {
                  final Segment s = fixed[i];
                  return FixedBlock(
                    key: ValueKey<String>(s.id),
                    segment: s,
                    onEdit: () => showAddFixedSheet(context, existing: s),
                    dragHandle: ReorderableDragStartListener(
                      index: i,
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        size: 16,
                        color: AppPalette.of(context).muted2,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 6),
            _AddButtons(
              onAddVar: () => showAddVariableSheet(context),
              onAddFixed: () => showAddFixedSheet(context),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    this.trailing,
    this.onTrailing,
    this.topGap = 0,
  });

  final String label;
  final int count;
  final String? trailing;
  final VoidCallback? onTrailing;
  final double topGap;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Padding(
      padding: EdgeInsets.only(top: topGap, left: 4, right: 4, bottom: 10),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: p.muted,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: p.primarySoft,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const Spacer(),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailing,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(
                  trailing!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.icon,
    required this.text,
    this.actionText,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: p.isDark ? p.surface : const Color(0xFFFBFBFE),
        border: Border.all(color: p.line, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 26, color: p.muted2),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: p.muted),
          ),
          if (actionText != null) ...<Widget>[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionText!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddButtons extends StatelessWidget {
  const _AddButtons({required this.onAddVar, required this.onAddFixed});

  final VoidCallback onAddVar;
  final VoidCallback onAddFixed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onAddVar,
              icon: const Icon(Icons.data_object_rounded, size: 17),
              label: const Text('添加变量', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(46),
                side: const BorderSide(color: Color(0xFFD3D7EA), width: 1.6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onAddFixed,
              icon: const Icon(Icons.text_fields_rounded, size: 17),
              label: const Text('添加固定文本', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPalette.of(context).ink2,
                minimumSize: const Size.fromHeight(46),
                side: BorderSide(color: AppPalette.of(context).line, width: 1.6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
