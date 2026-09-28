import 'package:flutter/material.dart';

import '../../business/db/store.dart';
import '../../business/model/segment.dart';
import '../../business/model/template.dart';
import '../theme/app_theme.dart';
import '../widgets/seg_chip.dart';
import '../widgets/sheets.dart';

/// 搭建态：上方画布拖拽编排句子，下方组件库（固定文本 / 变量）。
class BuilderView extends StatelessWidget {
  const BuilderView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Store.instance,
      builder: (BuildContext context, Widget? _) {
        final Template? t = Store.instance.active;
        if (t == null) return const SizedBox.shrink();

        return Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                children: <Widget>[
                  _NameField(template: t),
                  const SizedBox(height: 16),
                  _CanvasHeader(),
                  const SizedBox(height: 10),
                  _Canvas(template: t),
                ],
              ),
            ),
            _Tray(template: t),
          ],
        );
      },
    );
  }
}

class _NameField extends StatefulWidget {
  const _NameField({required this.template});

  final Template template;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.template.name);
  }

  @override
  void didUpdateWidget(covariant _NameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && _controller.text != widget.template.name) {
      _controller.text = widget.template.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.line, width: 1.4),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '模板名称',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: p.muted,
            ),
          ),
          TextField(
            controller: _controller,
            focusNode: _focus,
            onChanged: (String v) =>
                Store.instance.renameTemplate(widget.template.id, v),
            textInputAction: TextInputAction.done,
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: p.ink,
            ),
            cursorColor: AppColors.primary,
            decoration: InputDecoration.collapsed(
              hintText: '给模板起个名字',
              hintStyle: TextStyle(color: p.muted2, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CanvasHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: <Widget>[
          Text(
            '句子编排',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: p.muted,
            ),
          ),
          const Spacer(),
          Icon(Icons.touch_app_outlined, size: 13, color: p.muted2),
          const SizedBox(width: 5),
          Text(
            '长按拖动排序 · 点击可编辑',
            style: TextStyle(fontSize: 11.5, color: p.muted),
          ),
        ],
      ),
    );
  }
}

class _Canvas extends StatefulWidget {
  const _Canvas({required this.template});

  final Template template;

  @override
  State<_Canvas> createState() => _CanvasState();
}

class _CanvasState extends State<_Canvas> {
  int? _hoverIndex;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final List<Segment> segs = widget.template.sortedSegments;

    final List<Widget> children = <Widget>[];
    for (int i = 0; i < segs.length; i++) {
      children.add(_gap(context, i, segs));
      children.add(_draggableChip(segs[i]));
    }
    children.add(_gap(context, segs.length, segs));

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 170),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.isDark ? p.surface2 : const Color(0xFFF8F9FF),
        border: Border.all(color: p.varBorder, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: segs.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.layers_outlined, size: 14, color: p.muted),
                    const SizedBox(width: 7),
                    Text(
                      '从下方组件库添加固定文本或变量',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '示例：您好，{收件人}，您的包裹已发出。',
                  style: TextStyle(fontSize: 13, color: p.muted2),
                ),
              ],
            )
          : Wrap(
              spacing: 0,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: children,
            ),
    );
  }

  Widget _gap(BuildContext context, int index, List<Segment> segs) {
    final AppPalette p = AppPalette.of(context);
    final bool active = _hoverIndex == index;

    return DragTarget<Segment>(
      onWillAcceptWithDetails: (DragTargetDetails<Segment> details) {
        if (_hoverIndex != index) {
          setState(() => _hoverIndex = index);
        }
        return true;
      },
      onLeave: (Segment? _) {
        if (_hoverIndex == index) setState(() => _hoverIndex = null);
      },
      onAcceptWithDetails: (DragTargetDetails<Segment> details) {
        setState(() => _hoverIndex = null);
        final int from = segs.indexWhere((Segment s) => s.id == details.data.id);
        int to = index;
        if (from >= 0 && from < to) to -= 1;
        Store.instance.moveSegment(details.data.id, to);
      },
      builder: (
        BuildContext context,
        List<Segment?> candidate,
        List<dynamic> rejected,
      ) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: active && candidate.isNotEmpty ? 26 : 6,
          height: 34,
          decoration: active && candidate.isNotEmpty
              ? BoxDecoration(
                  color: p.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
        );
      },
    );
  }

  Widget _draggableChip(Segment segment) {
    final Widget chip = SegChip(
      segment: segment,
      onRemove: () => Store.instance.removeSegment(segment.id),
    );
    return LongPressDraggable<Segment>(
      data: segment,
      hapticFeedbackOnStart: true,
      feedback: Material(
        color: Colors.transparent,
        child: SegChip(segment: segment, dragging: true),
      ),
      childWhenDragging: Opacity(opacity: 0.32, child: chip),
      child: GestureDetector(
        onTap: () => showSegmentActionsSheet(context, segment: segment),
        child: chip,
      ),
    );
  }
}

class _Tray extends StatefulWidget {
  const _Tray({required this.template});

  final Template template;

  @override
  State<_Tray> createState() => _TrayState();
}

class _TrayState extends State<_Tray> {
  int _tab = 0; // 0 固定文本, 1 变量

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final List<Segment> items =
        _tab == 0 ? widget.template.fixedSegments : widget.template.variables;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.line)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: p.isDark ? Colors.black38 : const Color(0x1F0E1220),
            blurRadius: 34,
            offset: const Offset(0, -14),
            spreadRadius: -22,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 18 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: p.line,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 12),
          _segmented(p),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Text(
                '拖到上方句子中',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: p.muted,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (_tab == 0) {
                    showAddFixedSheet(context);
                  } else {
                    showAddVariableSheet(context);
                  }
                },
                child: Text(
                  _tab == 0 ? '＋ 新建固定文本' : '＋ 新建变量',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 86,
            child: items.isEmpty
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _tab == 0 ? '暂无固定文本' : '暂无变量',
                      style: TextStyle(fontSize: 12.5, color: p.muted2),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (BuildContext context, int i) {
                      return _trayCard(items[i]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _segmented(AppPalette p) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: <Widget>[
          _segButton(0, '固定文本 · ${widget.template.fixedSegments.length}', p),
          _segButton(1, '变量 · ${widget.template.variables.length}', p),
        ],
      ),
    );
  }

  Widget _segButton(int index, String label, AppPalette p) {
    final bool on = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: on ? p.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: on
                ? <BoxShadow>[
                    BoxShadow(
                      color: p.isDark ? Colors.black38 : const Color(0x1F101828),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: on ? p.ink : p.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _trayCard(Segment segment) {
    final AppPalette p = AppPalette.of(context);
    final bool isVar = segment.isVariable;
    final String title = isVar
        ? (segment.name.isEmpty ? '未命名变量' : segment.name)
        : (segment.text.isEmpty ? '（空文本）' : segment.text);
    final String? sub = isVar && segment.value.isNotEmpty ? '当前值：${segment.value}' : null;

    final Widget card = Container(
      width: 172,
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: isVar
            ? (p.isDark ? const Color(0xFF232848) : const Color(0xFFF1F2FF))
            : p.surface2,
        border: Border.all(color: isVar ? p.varBorder : p.line, width: 1.4),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                isVar ? Icons.data_object_rounded : Icons.text_fields_rounded,
                size: 13,
                color: isVar ? const Color(0xFF7A83E8) : p.muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isVar ? '变量' : '固定',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: isVar ? const Color(0xFF7A83E8) : p.muted,
                  ),
                ),
              ),
              Icon(Icons.drag_indicator_rounded, size: 14, color: p.muted2),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: isVar ? const Color(0xFF4A52D6) : p.ink2,
              ),
            ),
          ),
          if (sub != null)
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: p.muted),
            ),
        ],
      ),
    );

    return LongPressDraggable<Segment>(
      data: segment,
      hapticFeedbackOnStart: true,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 172,
          height: 86,
          child: Opacity(opacity: 0.96, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: GestureDetector(
        onTap: () => showSegmentActionsSheet(context, segment: segment),
        child: card,
      ),
    );
  }
}
