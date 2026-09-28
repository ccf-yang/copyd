import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../business/db/store.dart';
import '../../business/logic/composer.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';

/// 底部固定栏：实时预览 + 主复制按钮。
class CopyBar extends StatelessWidget {
  const CopyBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Store.instance,
      builder: (BuildContext context, Widget? _) {
        final Store store = Store.instance;
        final AppPalette p = AppPalette.of(context);
        final String text = store.activeText;
        final List<String> empties = store.activeEmptyVariables;

        return Container(
          decoration: BoxDecoration(
            color: p.surface,
            border: Border(top: BorderSide(color: p.line2)),
          ),
          padding: EdgeInsets.fromLTRB(16, 12, 16, 14 + MediaQuery.paddingOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _Preview(text: text, placeholder: store.emptyPlaceholder),
              if (empties.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '还有 ${empties.length} 个变量未填写：${empties.join('、')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 11),
              _CopyButton(
                enabled: text.trim().isNotEmpty,
                onTap: () => _copy(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _copy(BuildContext context) async {
    final Store store = Store.instance;
    final String text = store.activeText;
    if (text.trim().isEmpty) {
      AppToast.show(context, '模板内容为空', subtitle: '先添加固定文本或变量', success: false);
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    final String? name = store.active?.name;
    AppToast.show(
      context,
      '已复制到剪贴板',
      subtitle: <String?>[
        if (name != null && name.isNotEmpty) name,
        '共 ${textLength(text)} 个字符',
      ].join(' · '),
    );
    store.afterCopied();
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.text, required this.placeholder});

  final String text;
  final String placeholder;

  List<InlineSpan> _spans() {
    final List<InlineSpan> spans = <InlineSpan>[];
    final List<String> parts = text.split(placeholder);
    for (int i = 0; i < parts.length; i++) {
      if (i > 0) {
        spans.add(
          TextSpan(
            text: placeholder,
            style: const TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.w800,
              backgroundColor: Color(0x1AF79009),
            ),
          ),
        );
      }
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i]));
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 9),
            child: Text(
              '预览',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: p.muted,
              ),
            ),
          ),
          Expanded(
            child: text.isEmpty
                ? Text(
                    '暂无内容',
                    style: TextStyle(fontSize: 12.5, color: p.muted2),
                  )
                : RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.55,
                        color: p.ink2,
                      ),
                      children: _spans(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.onTap, required this.enabled});

  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.button),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x804F5BFF),
                  blurRadius: 26,
                  offset: Offset(0, 12),
                  spreadRadius: -10,
                ),
              ],
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.content_copy_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 9),
                    Text(
                      '复制全部内容',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
