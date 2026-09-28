import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../business/db/store.dart';
import '../../business/model/segment.dart';
import '../../business/model/template.dart';
import '../theme/app_theme.dart';
import 'app_sheet.dart';
import 'app_toast.dart';

// ============================ 固定文本 ============================

const List<String> _fixedSuggestions = <String>[
  '亲爱的用户，',
  '您好，',
  '请保持手机畅通。',
  '谢谢！',
  '—— 客服中心',
];

Future<void> showAddFixedSheet(BuildContext context, {Segment? existing}) async {
  await showAppSheet<void>(
    context: context,
    child: _FixedTextSheet(existing: existing),
  );
}

class _FixedTextSheet extends StatefulWidget {
  const _FixedTextSheet({this.existing});

  final Segment? existing;

  @override
  State<_FixedTextSheet> createState() => _FixedTextSheetState();
}

class _FixedTextSheetState extends State<_FixedTextSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existing?.text ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final bool editing = widget.existing != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SheetHeader(
          title: editing ? '编辑固定文本' : '添加固定文本',
          description: '固定文本每次都原样保留，不会出现在上方变量区。',
        ),
        const SizedBox(height: 18),
        SheetField(
          label: '内容',
          child: SheetInput(
            controller: _controller,
            hint: '输入固定不变的文案…',
            maxLines: 5,
            autofocus: true,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Icon(Icons.content_paste_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
                final String? text = data?.text;
                if (text != null && text.isNotEmpty) {
                  _controller.text = text;
                  _controller.selection = TextSelection.collapsed(offset: text.length);
                }
              },
              child: const Text(
                '从剪贴板粘贴',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '常用短语',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: p.muted,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: _fixedSuggestions.map((String s) {
            return GestureDetector(
              onTap: () {
                final int offset = _controller.selection.baseOffset < 0
                    ? _controller.text.length
                    : _controller.selection.baseOffset;
                final String text = _controller.text;
                final String next = text.substring(0, offset) + s + text.substring(offset);
                _controller.text = next;
                _controller.selection = TextSelection.collapsed(offset: offset + s.length);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: p.surface2,
                  border: Border.all(color: p.line),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  s,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.ink2),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        SheetActions(
          confirmText: editing ? '保存' : '确定添加',
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: () {
            final String text = _controller.text;
            if (text.trim().isEmpty) {
              AppToast.show(context, '内容不能为空', success: false);
              return;
            }
            if (editing) {
              Store.instance.updateSegment(widget.existing!.id, text: text);
            } else {
              Store.instance.addFixed(text);
            }
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

// ============================ 变量 ============================

const List<String> _varNameSuggestions = <String>[
  '收件人',
  '订单号',
  '日期',
  '金额',
  '地址',
  '手机号',
];

Future<void> showAddVariableSheet(BuildContext context, {Segment? existing}) async {
  await showAppSheet<void>(
    context: context,
    child: _VariableSheet(existing: existing),
  );
}

class _VariableSheet extends StatefulWidget {
  const _VariableSheet({this.existing});

  final Segment? existing;

  @override
  State<_VariableSheet> createState() => _VariableSheetState();
}

class _VariableSheetState extends State<_VariableSheet> {
  late final TextEditingController _name;
  late final TextEditingController _value;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _value = TextEditingController(text: widget.existing?.value ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final bool editing = widget.existing != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SheetHeader(
          title: editing ? '编辑变量' : '添加变量',
          description: '变量是每次复制前都要替换的部分，会显示在主界面最上方。',
        ),
        const SizedBox(height: 18),
        SheetField(
          label: '变量名称',
          child: SheetInput(
            controller: _name,
            hint: '例如：收件人',
            autofocus: true,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: _varNameSuggestions.map((String s) {
            final bool on = _name.text == s;
            return GestureDetector(
              onTap: () => setState(() => _name.text = s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: on ? p.primarySoft : p.surface2,
                  border: Border.all(color: on ? p.varBorder : p.line),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  s,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: on ? AppColors.primary : p.ink2,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        SheetField(
          label: editing ? '当前值（可选）' : '默认值（可选）',
          child: SheetInput(
            controller: _value,
            hint: '留空则使用时再填',
          ),
        ),
        const SizedBox(height: 22),
        SheetActions(
          confirmText: editing ? '保存' : '确定添加',
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: () {
            final String name = _name.text.trim();
            if (name.isEmpty) {
              AppToast.show(context, '请填写变量名称', success: false);
              return;
            }
            final String value = _value.text;
            if (editing) {
              Store.instance.updateSegment(widget.existing!.id, name: name);
              Store.instance.setValue(widget.existing!.id, value);
            } else {
              Store.instance.addVariable(name, defaultValue: value);
            }
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

// ============================ 变量值：大输入框 ============================

/// 半屏大输入框：文字自动换行，内容多了可滚动，实时写回 Store。
Future<void> showVariableValueSheet(
  BuildContext context, {
  required Segment segment,
}) {
  return showAppSheet<void>(
    context: context,
    heightFactor: 0.5,
    child: _VariableValueSheet(segment: segment),
  );
}

class _VariableValueSheet extends StatefulWidget {
  const _VariableValueSheet({required this.segment});

  final Segment segment;

  @override
  State<_VariableValueSheet> createState() => _VariableValueSheetState();
}

class _VariableValueSheetState extends State<_VariableValueSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final String v = widget.segment.value;
    _controller = TextEditingController(text: v)
      ..selection = TextSelection.collapsed(offset: v.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final String name =
        widget.segment.name.isEmpty ? '未命名变量' : widget.segment.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SheetHandle(),
        Row(
          children: <Widget>[
            Icon(Icons.data_object_rounded, size: 15, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: p.ink,
                ),
              ),
            ),
            Text(
              '${_controller.text.runes.length} 字符',
              style: TextStyle(fontSize: 12.5, color: p.muted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: p.isDark ? p.surface2 : const Color(0xFFFAFBFE),
              border: Border.all(color: p.varBorder, width: 1.4),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: TextField(
              controller: _controller,
              autofocus: true,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              keyboardType: TextInputType.multiline,
              onChanged: (String v) {
                Store.instance.setValue(widget.segment.id, v);
                setState(() {}); // 刷新字数
              },
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: p.ink,
              ),
              cursorColor: AppColors.primary,
              decoration: InputDecoration.collapsed(
                hintText: '输入内容，可换行…',
                hintStyle: TextStyle(color: p.muted2, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SheetPrimaryButton(
          label: '完成',
          icon: Icons.check_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

// ============================ 片段操作 ============================

Future<void> showSegmentActionsSheet(
  BuildContext context, {
  required Segment segment,
}) async {
  final AppPalette p = AppPalette.of(context);
  final List<Segment> ordered =
      Store.instance.active?.sortedSegments ?? const <Segment>[];
  final int pos = ordered.indexWhere((Segment s) => s.id == segment.id);

  await showAppSheet<void>(
    context: context,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SheetHandle(),
        Row(
          children: <Widget>[
            _Tag(text: segment.isVariable ? '变量' : '固定', highlight: segment.isVariable),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                segment.isVariable ? segment.name : segment.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('选择要执行的操作', style: TextStyle(fontSize: 12.5, color: p.muted)),
        const SizedBox(height: 10),
        _ActionItem(
          icon: Icons.content_copy_rounded,
          label: segment.isVariable ? '复制变量值' : '复制这段内容',
          onTap: () async {
            final String text = segment.isVariable ? segment.value : segment.text;
            Navigator.of(context).pop();
            if (text.isEmpty) {
              AppToast.show(context, '内容为空', success: false);
              return;
            }
            await Clipboard.setData(ClipboardData(text: text));
            if (!context.mounted) return;
            AppToast.show(context, '已复制');
          },
        ),
        _ActionItem(
          icon: Icons.keyboard_arrow_up_rounded,
          label: '前移一个片段',
          onTap: () {
            Navigator.of(context).pop();
            if (pos > 0) Store.instance.moveSegment(segment.id, pos - 1);
          },
        ),
        _ActionItem(
          icon: Icons.keyboard_arrow_down_rounded,
          label: '后移一个片段',
          onTap: () {
            Navigator.of(context).pop();
            if (pos >= 0 && pos < ordered.length - 1) {
              Store.instance.moveSegment(segment.id, pos + 1);
            }
          },
        ),
        _ActionItem(
          icon: Icons.edit_rounded,
          label: segment.isVariable ? '编辑变量' : '编辑文字',
          onTap: () {
            Navigator.of(context).pop();
            if (segment.isVariable) {
              showAddVariableSheet(context, existing: segment);
            } else {
              showAddFixedSheet(context, existing: segment);
            }
          },
        ),
        if (segment.isVariable)
          _ActionItem(
            icon: Icons.backspace_outlined,
            label: '清空当前值',
            onTap: () {
              Navigator.of(context).pop();
              Store.instance.clearValue(segment.id);
            },
          ),
        _ActionItem(
          icon: Icons.delete_outline_rounded,
          label: '删除组件',
          danger: true,
          onTap: () async {
            final String content = segment.isVariable ? segment.name : segment.text;
            Navigator.of(context).pop();
            final bool ok = await showConfirmDialog(
              context,
              title: '删除这个组件？',
              message: content,
              confirmText: '删除',
            );
            if (ok) Store.instance.removeSegment(segment.id);
          },
        ),
      ],
    ),
  );
}

// ============================ 模板操作 ============================

Future<void> showTemplateActionsSheet(
  BuildContext context, {
  required Template template,
  VoidCallback? onBuild,
}) async {
  final AppPalette p = AppPalette.of(context);

  await showAppSheet<void>(
    context: context,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SheetHandle(),
        Text(
          '模板操作',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.ink),
        ),
        const SizedBox(height: 6),
        Text(
          '${template.name} · ${template.variables.length} 变量 · ${template.fixedSegments.length} 固定段',
          style: TextStyle(fontSize: 12.5, color: p.muted),
        ),
        const SizedBox(height: 12),
        _ActionItem(
          icon: Icons.drive_file_rename_outline_rounded,
          label: '重命名模板',
          onTap: () {
            Navigator.of(context).pop();
            showRenameTemplateDialog(context, template: template);
          },
        ),
        _ActionItem(
          icon: Icons.copy_all_rounded,
          label: '复制为新模板',
          onTap: () {
            Navigator.of(context).pop();
            Store.instance.duplicateTemplate(template.id);
            AppToast.show(context, '已复制为新模板');
          },
        ),
        _ActionItem(
          icon: Icons.tune_rounded,
          label: '进入搭建模式',
          onTap: () {
            Navigator.of(context).pop();
            Store.instance.selectTemplate(template.id);
            onBuild?.call();
          },
        ),
        _ActionItem(
          icon: Icons.delete_outline_rounded,
          label: '删除模板',
          danger: true,
          onTap: () async {
            Navigator.of(context).pop();
            final bool ok = await showConfirmDialog(
              context,
              title: '删除模板？',
              message: '「${template.name}」及其所有组件将被移除，此操作不可撤销。',
              confirmText: '删除',
            );
            if (ok) Store.instance.deleteTemplate(template.id);
          },
        ),
      ],
    ),
  );
}

Future<void> showRenameTemplateDialog(
  BuildContext context, {
  required Template template,
}) async {
  final TextEditingController controller = TextEditingController(text: template.name);
  final AppPalette p = AppPalette.of(context);

  await showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('重命名模板', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: SheetInput(controller: controller, hint: '模板名称', autofocus: true),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('取消', style: TextStyle(color: p.muted, fontWeight: FontWeight.w700)),
        ),
        TextButton(
          onPressed: () {
            Store.instance.renameTemplate(template.id, controller.text);
            Navigator.of(ctx).pop();
          },
          child: const Text('保存', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = '确定',
}) async {
  final AppPalette p = AppPalette.of(context);
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: Text(message, style: TextStyle(color: p.ink2, height: 1.6)),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('取消', style: TextStyle(color: p.muted, fontWeight: FontWeight.w700)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmText, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
  return ok ?? false;
}

// ============================ 小部件 ============================

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final Color fg = danger ? AppColors.danger : p.ink2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: danger ? p.dangerSoft : p.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: fg),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: danger ? AppColors.danger : p.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.highlight = false});

  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: highlight ? p.primarySoft : p.surface2,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: highlight ? AppColors.primary : p.muted,
        ),
      ),
    );
  }
}
