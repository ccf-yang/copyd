import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../business/db/store.dart';
import '../../business/logic/composer.dart';
import '../theme/app_theme.dart';
import 'app_sheet.dart';
import 'app_toast.dart';

/// 把拼装文本按「空变量占位符」切分，占位符高亮显示。
List<InlineSpan> placeholderSpans(String text, String placeholder) {
  final List<InlineSpan> spans = <InlineSpan>[];
  if (text.isEmpty) return spans;
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

/// 带空变量高亮的富文本。
class PreviewText extends StatelessWidget {
  const PreviewText({
    super.key,
    required this.text,
    required this.placeholder,
    this.maxLines,
    this.baseStyle,
  });

  final String text;
  final String placeholder;
  final int? maxLines;
  final TextStyle? baseStyle;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final TextStyle style = baseStyle ??
        TextStyle(fontSize: 12.5, height: 1.55, color: p.ink2);
    return Text.rich(
      TextSpan(style: style, children: placeholderSpans(text, placeholder)),
      maxLines: maxLines,
      overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
    );
  }
}

/// 复制当前模板拼装后的文本（底部复制按钮 / 预览弹窗共用）。
Future<void> copyActiveTextToClipboard(BuildContext context) async {
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

/// 点击底部预览 → 半屏预览框；点外部关闭；内容过长可在框内滚动。
Future<void> showPreviewSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    heightFactor: 0.5,
    child: const _PreviewSheetBody(),
  );
}

class _PreviewSheetBody extends StatelessWidget {
  const _PreviewSheetBody();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Store.instance,
      builder: (BuildContext context, Widget? _) {
        final Store store = Store.instance;
        final AppPalette p = AppPalette.of(context);
        final String text = store.activeText;
        final List<String> empties = store.activeEmptyVariables;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SheetHandle(),
            Row(
              children: <Widget>[
                Text(
                  '内容预览',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: p.ink,
                  ),
                ),
                const Spacer(),
                Text(
                  '${textLength(text)} 字符',
                  style: TextStyle(fontSize: 12.5, color: p.muted),
                ),
              ],
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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: p.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.line2),
                ),
                child: text.isEmpty
                    ? Center(
                        child: Text(
                          '暂无内容',
                          style: TextStyle(fontSize: 13, color: p.muted2),
                        ),
                      )
                    : SingleChildScrollView(
                        child: PreviewText(
                          text: text,
                          placeholder: store.emptyPlaceholder,
                          baseStyle: TextStyle(
                            fontSize: 14.5,
                            height: 1.75,
                            color: p.ink2,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            _SheetCopyButton(onTap: () => copyActiveTextToClipboard(context)),
          ],
        );
      },
    );
  }
}

class _SheetCopyButton extends StatelessWidget {
  const _SheetCopyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.content_copy_rounded, color: Colors.white, size: 19),
                  SizedBox(width: 9),
                  Text(
                    '复制全部内容',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
