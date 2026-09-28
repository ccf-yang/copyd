import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../business/db/store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_sheet.dart';
import '../widgets/app_toast.dart';
import '../widgets/sheets.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);

    return ListenableBuilder(
      listenable: Store.instance,
      builder: (BuildContext context, Widget? _) {
        final Store store = Store.instance;

        return Scaffold(
          backgroundColor: p.bg,
          appBar: AppBar(
            title: const Text('设置'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: <Widget>[
              _groupLabel(p, '复制行为'),
              _SwitchRow(
                icon: Icons.auto_awesome_rounded,
                title: '复制后自动清空变量',
                subtitle: '下次使用时从空白开始',
                value: store.clearVarsAfterCopy,
                onChanged: store.setClearVarsAfterCopy,
              ),
              _ValueRow(
                icon: Icons.text_fields_rounded,
                title: '变量为空时替换为',
                subtitle: '避免漏填',
                value: store.emptyPlaceholder,
                onTap: () => _editPlaceholder(context),
              ),
              _groupLabel(p, '外观'),
              _ValueRow(
                icon: Icons.dark_mode_outlined,
                title: '深色模式',
                value: _themeLabel(store.themeMode),
                onTap: () => _pickTheme(context, store),
              ),
              _groupLabel(p, '数据'),
              _ValueRow(
                icon: Icons.cloud_done_outlined,
                title: '数据存储',
                subtitle: '所有模板保存在本机，重启不丢',
                value: '${store.templates.length} 个模板',
                onTap: null,
              ),
              _ValueRow(
                icon: Icons.content_paste_go_rounded,
                title: '导入模板',
                subtitle: '从剪贴板的 JSON 恢复模板与设置',
                onTap: () => showImportSheet(context),
              ),
              _ValueRow(
                icon: Icons.ios_share_rounded,
                title: '导出全部模板',
                subtitle: '以 JSON 复制到剪贴板',
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: store.exportJson()),
                  );
                  if (!context.mounted) return;
                  AppToast.show(context, '已导出到剪贴板', subtitle: 'JSON 格式');
                },
              ),
              _ValueRow(
                icon: Icons.delete_forever_outlined,
                title: '清空所有数据',
                danger: true,
                onTap: () async {
                  final bool ok = await showConfirmDialog(
                    context,
                    title: '清空所有数据？',
                    message: '${store.templates.length} 个模板将被永久删除，此操作不可撤销。',
                    confirmText: '清空',
                  );
                  if (ok) {
                    store.clearAll();
                    if (!context.mounted) return;
                    AppToast.show(context, '已清空所有数据');
                  }
                },
              ),
              const SizedBox(height: 26),
              Center(
                child: Text(
                  'CopyD v1.0.0 · Made with Flutter',
                  style: TextStyle(fontSize: 12, color: p.muted2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _themeLabel(String mode) {
    switch (mode) {
      case 'light':
        return '浅色';
      case 'dark':
        return '深色';
      default:
        return '跟随系统';
    }
  }

  Widget _groupLabel(AppPalette p, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: p.muted,
        ),
      ),
    );
  }

  Future<void> _pickTheme(BuildContext context, Store store) async {
    final AppPalette p = AppPalette.of(context);
    await showAppSheet<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SheetHeader(title: '深色模式'),
          const SizedBox(height: 10),
          ...<Map<String, String>>[
            <String, String>{'key': 'system', 'label': '跟随系统'},
            <String, String>{'key': 'light', 'label': '浅色'},
            <String, String>{'key': 'dark', 'label': '深色'},
          ].map((Map<String, String> item) {
            final bool on = store.themeMode == item['key'];
            return InkWell(
              onTap: () {
                store.setThemeMode(item['key']!);
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item['label']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: p.ink,
                        ),
                      ),
                    ),
                    if (on)
                      const Icon(Icons.check_rounded, size: 19, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _editPlaceholder(BuildContext context) async {
    final TextEditingController controller =
        TextEditingController(text: Store.instance.emptyPlaceholder);
    final AppPalette p = AppPalette.of(context);
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('空变量占位符', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: SheetInput(controller: controller, hint: '[待填写]', autofocus: true),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('取消', style: TextStyle(color: p.muted, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              Store.instance.setEmptyPlaceholder(controller.text.trim());
              Navigator.of(ctx).pop();
            },
            child: const Text('保存', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return _RowShell(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return _RowShell(
      icon: icon,
      title: title,
      subtitle: subtitle,
      danger: danger,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (value != null)
            Text(
              value!,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: danger ? AppColors.danger : p.muted,
              ),
            ),
          if (onTap != null) ...<Widget>[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 20, color: p.muted2),
          ],
        ],
      ),
    );
  }
}

class _RowShell extends StatelessWidget {
  const _RowShell({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: danger ? p.dangerSoft : p.surface2,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: danger ? AppColors.danger : p.ink2,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: danger ? AppColors.danger : p.ink,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 12, color: p.muted),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

// ============================ 导入模板 ============================

Future<void> showImportSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    heightFactor: 0.5,
    child: const _ImportSheet(),
  );
}

class _ImportSheet extends StatefulWidget {
  const _ImportSheet();

  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<_ImportSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 剪贴板里已经有内容时自动填进来，省一步粘贴
    Clipboard.getData(Clipboard.kTextPlain).then((ClipboardData? data) {
      final String? text = data?.text;
      if (!mounted || text == null || text.trim().isEmpty) return;
      if (_controller.text.isNotEmpty) return;
      setState(() => _controller.text = text);
    }).catchError((Object _) {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _doImport({required bool replace}) {
    final String raw = _controller.text.trim();
    if (raw.isEmpty) {
      AppToast.show(context, '请先粘贴 JSON', success: false);
      return;
    }
    try {
      final int n = Store.instance.importJson(raw, replace: replace);
      Navigator.of(context).pop();
      AppToast.show(
        context,
        replace ? '已替换为 $n 个模板' : '已导入 $n 个模板',
        subtitle: replace ? '原有模板已清空' : '同 id 的模板已覆盖',
      );
    } on FormatException catch (e) {
      AppToast.show(context, '导入失败', subtitle: e.message, success: false);
    } catch (e) {
      AppToast.show(context, '导入失败', subtitle: '$e', success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SheetHandle(),
        Text(
          '导入模板',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '把「导出全部模板」得到的 JSON 粘到这里。\n'
          '合并 = 保留现有模板，同 id 的覆盖；替换 = 先清空再导入（含设置）。',
          style: TextStyle(fontSize: 12.5, height: 1.6, color: p.muted),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: p.isDark ? p.surface2 : const Color(0xFFFAFBFE),
              border: Border.all(color: p.line, width: 1.4),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: TextField(
              controller: _controller,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              keyboardType: TextInputType.multiline,
              onChanged: (String _) => setState(() {}),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                fontFamily: 'monospace',
                color: p.ink2,
              ),
              cursorColor: AppColors.primary,
              decoration: InputDecoration.collapsed(
                hintText: '{\n  "templates": [...]\n}',
                hintStyle: TextStyle(color: p.muted2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SheetPrimaryButton(
          label: '合并导入',
          icon: Icons.merge_rounded,
          onTap: () => _doImport(replace: false),
        ),
        const SizedBox(height: 10),
        SheetSecondaryButton(
          label: '替换全部（先清空）',
          icon: Icons.swap_horiz_rounded,
          danger: true,
          onTap: () => _doImport(replace: true),
        ),
      ],
    );
  }
}
