import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../business/db/store.dart';
import '../../business/model/segment.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';
import 'mini_button.dart';

/// 变量卡：使用态上半区的主角，点文字就地编辑。
class VariableCard extends StatefulWidget {
  const VariableCard({super.key, required this.segment});

  final Segment segment;

  @override
  State<VariableCard> createState() => _VariableCardState();
}

class _VariableCardState extends State<VariableCard> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.segment.value);
    _focus = FocusNode();
  }

  @override
  void didUpdateWidget(covariant VariableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segment.id != widget.segment.id) {
      _controller.text = widget.segment.value;
    } else if (!_focus.hasFocus && _controller.text != widget.segment.value) {
      _controller.text = widget.segment.value;
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
    final Segment seg = widget.segment;

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
            Container(width: 3, decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
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
                          Row(
                            children: <Widget>[
                              Icon(Icons.data_object_rounded, size: 12, color: p.isDark ? const Color(0xFF8C93E8) : const Color(0xFF6F79E8)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  seg.name.isEmpty ? '未命名变量' : seg.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: p.isDark ? const Color(0xFF8C93E8) : const Color(0xFF6F79E8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextField(
                            controller: _controller,
                            focusNode: _focus,
                            onChanged: (String v) => Store.instance.setValue(seg.id, v),
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
                      icon: Icons.content_copy_rounded,
                      tooltip: '复制变量值',
                      onTap: () async {
                        if (seg.value.trim().isEmpty) {
                          AppToast.show(context, '变量为空', subtitle: seg.name, success: false);
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
                      onTap: () => Store.instance.clearValue(seg.id),
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
