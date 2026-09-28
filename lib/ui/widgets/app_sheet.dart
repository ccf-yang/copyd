import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 统一的底部弹窗容器（圆角 26、顶部把手、键盘避让）。
/// [heightFactor] 不为空时，弹窗固定为屏幕高度的该比例（内容自行滚动）；
/// 为空则高度随内容自适应并整体可滚。
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required Widget child,
  bool dismissible = true,
  double? heightFactor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: Colors.transparent,
    barrierColor: AppPalette.of(context).overlay,
    builder: (BuildContext ctx) {
      final AppPalette p = AppPalette.of(ctx);
      final double? fixedHeight =
          heightFactor == null ? null : MediaQuery.sizeOf(ctx).height * heightFactor;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Container(
          height: fixedHeight,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
          ),
          child: SafeArea(
            top: false,
            child: fixedHeight == null
                ? SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                    child: child,
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                    child: child,
                  ),
          ),
        ),
      );
    },
  );
}

/// 弹窗顶部的小把手。
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Center(
      child: Container(
        width: 40,
        height: 5,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: p.line,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

/// 弹窗标题 + 说明。
class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title, this.description});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SheetHandle(),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: p.ink,
          ),
        ),
        if (description != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            description!,
            style: TextStyle(fontSize: 12.5, height: 1.6, color: p.muted),
          ),
        ],
      ],
    );
  }
}

/// 弹窗底部的「取消 / 确定」双按钮。
class SheetActions extends StatelessWidget {
  const SheetActions({
    super.key,
    required this.onCancel,
    required this.onConfirm,
    this.cancelText = '取消',
    this.confirmText = '确定',
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String cancelText;
  final String confirmText;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: SizedBox(
              height: 52,
              child: Material(
                color: p.surface2,
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: InkWell(
                  onTap: onCancel,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Center(
                    child: Text(
                      cancelText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: p.ink2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 52,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: InkWell(
                    onTap: onConfirm,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: Center(
                      child: Text(
                        confirmText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 弹窗内的输入框外观。
class SheetField extends StatelessWidget {
  const SheetField({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: p.muted,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

/// 弹窗内的单个主按钮（如「完成」）。
class SheetPrimaryButton extends StatelessWidget {
  const SheetPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, color: Colors.white, size: 19),
                    const SizedBox(width: 9),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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

/// 弹窗内的次级按钮（描边）。
class SheetSecondaryButton extends StatelessWidget {
  const SheetSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final Color fg = danger ? AppColors.danger : p.ink2;
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(color: danger ? AppColors.danger : p.line, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// 统一样式的输入框。
class SheetInput extends StatelessWidget {
  const SheetInput({
    super.key,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return TextField(
      controller: controller,
      maxLines: maxLines,
      autofocus: autofocus,
      onTapOutside: (_) =>
          FocusManager.instance.primaryFocus?.unfocus(),
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: p.muted2, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: p.isDark ? p.surface2 : const Color(0xFFFAFBFE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC3C8FF), width: 1.5),
        ),
      ),
    );
  }
}
