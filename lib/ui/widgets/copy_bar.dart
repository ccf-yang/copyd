import 'package:flutter/material.dart';

import '../../business/db/store.dart';
import '../theme/app_theme.dart';
import 'preview_text.dart';

/// 底部固定栏：可点击的实时预览 + 主复制按钮。
///
/// 点击预览区会弹出半屏预览框（点外部关闭，内容可滚动）。
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
        final bool empty = text.trim().isEmpty;

        return Container(
          decoration: BoxDecoration(
            color: p.surface,
            border: Border(top: BorderSide(color: p.line2)),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            14 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _Preview(
                text: text,
                placeholder: store.emptyPlaceholder,
                onTap: () => showPreviewSheet(context),
              ),
              if (empties.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    const Icon(Icons.warning_amber_rounded,
                        size: 14, color: AppColors.warning),
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
                enabled: !empty,
                onTap: () => copyActiveTextToClipboard(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.text,
    required this.placeholder,
    required this.onTap,
  });

  final String text;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Ink(
          decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: BorderRadius.circular(13),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    : PreviewText(
                        text: text,
                        placeholder: placeholder,
                        maxLines: 2,
                      ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.open_in_full_rounded,
                  size: 13,
                  color: p.muted2,
                ),
              ),
            ],
          ),
        ),
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
