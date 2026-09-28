import 'package:flutter/material.dart';

import '../business/db/store.dart';
import 'theme/app_theme.dart';
import 'views/builder_view.dart';
import 'views/editor_view.dart';
import 'views/settings_view.dart';
import 'widgets/app_toast.dart';
import 'widgets/copy_bar.dart';
import 'widgets/sheets.dart';
import 'widgets/template_rail.dart';

/// 自适应外壳：手机 = 抽屉侧栏；宽屏 ≥720 = 常驻可折叠侧栏。
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _railCollapsed = false;
  int _mode = 0; // 0 = 使用态, 1 = 搭建态

  void _openBuilder() => setState(() => _mode = 1);
  void _closeBuilder() => setState(() => _mode = 0);

  void _createTemplate() {
    Store.instance.createTemplate();
    _openBuilder();
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext _) => const SettingsView()),
    );
  }

  Future<void> _saveAndClose() async {
    await Store.instance.save();
    if (!mounted) return;
    _closeBuilder();
    AppToast.show(context, '模板已保存');
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);

    return ListenableBuilder(
      listenable: Store.instance,
      builder: (BuildContext context, Widget? _) {
        // 点击任意空白处收起键盘；子级按钮/输入框的手势优先，不受影响
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 720;

            if (wide) {
              return Scaffold(
                backgroundColor: p.bg,
                body: SafeArea(
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: _railCollapsed ? 76 : 296,
                        child: _rail(wide: true),
                      ),
                      VerticalDivider(width: 1, thickness: 1, color: p.line),
                      Expanded(child: _main(wide: true)),
                    ],
                  ),
                ),
              );
            }

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: p.bg,
              drawer: Drawer(
                width: 300,
                backgroundColor: p.surface,
                shape: const RoundedRectangleBorder(),
                child: SafeArea(child: _rail(wide: false)),
              ),
              body: _main(wide: false),
            );
          },
          ),
        );
      },
    );
  }

  Widget _rail({required bool wide}) {
    return TemplateRail(
      collapsed: wide && _railCollapsed,
      onToggleCollapse:
          wide ? () => setState(() => _railCollapsed = !_railCollapsed) : null,
      onSelectTemplate:
          wide ? null : () => _scaffoldKey.currentState?.closeDrawer(),
      onCreateTemplate: () {
        if (!wide) _scaffoldKey.currentState?.closeDrawer();
        _createTemplate();
      },
      onOpenSettings: () {
        if (!wide) _scaffoldKey.currentState?.closeDrawer();
        _openSettings();
      },
      onBuildTemplate: (template) {
        if (!wide) _scaffoldKey.currentState?.closeDrawer();
        Store.instance.selectTemplate(template.id);
        _openBuilder();
      },
    );
  }

  Widget _main({required bool wide}) {
    final Store store = Store.instance;
    final AppPalette p = AppPalette.of(context);

    if (store.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: wide
              ? null
              : IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
          title: const Text('CopyD'),
        ),
        body: _EmptyState(onCreate: _createTemplate),
      );
    }

    final bool building = _mode == 1;
    final template = store.active!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: building
          ? AppBar(
              leadingWidth: 78,
              centerTitle: true,
              leading: TextButton(
                onPressed: _closeBuilder,
                child: Text(
                  '取消',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: p.muted,
                  ),
                ),
              ),
              title: const Text('编辑模板'),
              actions: <Widget>[
                TextButton(
                  onPressed: _saveAndClose,
                  child: const Text(
                    '保存',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            )
          : AppBar(
              leading: wide
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
              title: Text(template.name),
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded),
                  tooltip: '模板操作',
                  onPressed: () => showTemplateActionsSheet(
                    context,
                    template: template,
                    onBuild: _openBuilder,
                  ),
                ),
              ],
            ),
      body: IndexedStack(
        index: _mode,
        children: const <Widget>[EditorView(), BuilderView()],
      ),
      bottomNavigationBar: building ? null : const CopyBar(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[p.surface, p.primarySoft],
                ),
                border: Border.all(color: p.varBorder, width: 1.5),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.content_copy_rounded,
                size: 46,
                color: p.isDark ? const Color(0xFF8C93E8) : const Color(0xFFAAB0E8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '还没有模板',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '新建一个模板，把固定文案和变量组合起来，\n以后只需改变量、点复制。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.75, color: p.muted),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('新建模板', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
