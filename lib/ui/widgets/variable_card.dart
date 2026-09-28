import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../business/db/store.dart';
import '../../business/model/segment.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';
import 'mini_button.dart';
import 'sheets.dart';

/// 变量卡：使用态上半区的主角，点文字就地编辑。
///
/// - 长按「变量名」区域，或点右上角展开按钮 → 半屏大输入框（自动换行）
/// - 清空按钮会同时清掉 Store 与输入框（即使输入框仍有焦点）
class VariableCard extends StatefulWidget {
  const VariableCard({super.key, required this.segment});

  final Segment segment;

  @override
  State<VariableCard> createState() => _VariableCardState();
}

class _VariableCardState extends State<VariableCard> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  /// 记录最近一次「由本输入框输入」的值，用来区分外部改动（清空 / 大框编辑）。
  late String _lastEmitted;

  @override
  void initState() {
    super.initState();
    _lastEmitted = widget.segment.value;
    _controller = TextEditingController(text: widget.segment.value);
    _focus = FocusNode();
  }

  @override
  void didUpdateWidget(covariant VariableCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 切换模板 / 换了片段：整个重置
    if (oldWidget.segment.id != widget.segment.id) {
      _lastEmitted = widget.segment.value;
      _setText(widget.segment.value);
      return;
    }

    final String v = widget.segment.value;
    if (v != _lastEmitted) {
      // 外部改动（清空按钮、大框编辑、复制后自动清空）——即使输入框仍有焦点也要同步
      _lastEmitted = v;
      if (_controller.text != v) _setText(v);
    } else if (_controller.text != v) {
      _setText(v);
    }
  }

  void _setText(String v) {
    _controller.value = TextEditingValue(
      text: v,
      selection: TextSelection.collapsed(offset: v.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _clear() {
    // 先把本地状态和输入框清掉，避免等待 Store 通知期间还显示旧内容
    _lastEmitted = '';
    _controller.clear();
    Store.instance.clearValue(widget.segment.id);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final Segment seg = widget.segment;
    final String label = seg.name.isEmpty ? '未命名变量' : seg.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.varBg,
        border: Border.all(color: p.varBorder, width: 1.4),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              width: 3,
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 12, 10, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // 长按变量名 → 半屏大输入框
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onLongPress: () => showVariableValueSheet(
                              context,
                              segment: seg,
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.data_object_rounded,
                                  size: 12,
                                  color: p.isDark
                                      ? const Color(0xFF8C93E8)
                                      : const Color(0xFF6F79E8),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                      color: p.isDark
                                          ? const Color(0xFF8C93E8)
                                          : const Color(0xFF6F79E8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextField(
                            controller: _controller,
                            focusNode: _focus,
                            onChanged: (String v) {
                              _lastEmitted = v;
                              Store.instance.setValue(seg.id, v);
                            },
                            onTapOutside: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            textInputAction: TextInputAction.done,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: p.ink,
                            ),
                            cursorColor: AppColors.primary,
                            decoration: InputDecoration.collapsed(
                              hintText: '点击填写…',
                              hintStyle: TextStyle(
                                color: p.muted2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    MiniButton(
                      icon: Icons.open_in_full_rounded,
                      tooltip: '放大编辑',
                      onTap: () => showVariableValueSheet(context, segment: seg),
                    ),
                    const SizedBox(width: 3),
                    MiniButton(
                      icon: Icons.content_copy_rounded,
                      tooltip: '复制变量值',
                      onTap: () async {
                        if (seg.value.trim().isEmpty) {
                          AppToast.show(context, '变量为空',
                              subtitle: label, success: false);
                          return;
                        }
                        await Clipboard.setData(ClipboardData(text: seg.value));
                        if (!context.mounted) return;
                        AppToast.show(context, '已复制变量值', subtitle: seg.value);
                      },
                    ),
                    const SizedBox(width: 3),
                    MiniButton(
                      icon: Icons.cancel_outlined,
                      tone: MiniTone.danger,
                      tooltip: '清空',
                      onTap: _clear,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
