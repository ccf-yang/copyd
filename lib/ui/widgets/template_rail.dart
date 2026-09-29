import 'package:flutter/material.dart';

import '../../business/db/store.dart';
import '../../business/model/template.dart';
import '../theme/app_theme.dart';
import 'sheets.dart';

/// 左侧模板栏：手机端放进 Drawer，大屏端常驻并支持折叠。
class TemplateRail extends StatefulWidget {
  const TemplateRail({
    super.key,
    this.collapsed = false,
    this.onToggleCollapse,
    this.onSelectTemplate,
    this.onCreateTemplate,
    this.onOpenSettings,
    this.onBuildTemplate,
  });

  final bool collapsed;
  final VoidCallback? onToggleCollapse;
  final VoidCallback? onSelectTemplate;
  final VoidCallback? onCreateTemplate;
  final VoidCallback? onOpenSettings;
  final void Function(Template template)? onBuildTemplate;

  @override
  State<TemplateRail> createState() => _TemplateRailState();
}

class _TemplateRailState extends State<TemplateRail> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Store.instance,
      builder: (BuildContext context, Widget? _) {
        final Store store = Store.instance;
        final AppPalette p = AppPalette.of(context);
        final bool collapsed = widget.collapsed;

        final String q = _query.trim().toLowerCase();
        // 按创建顺序展示：编辑 / 使用模板不会改变列表顺序
        final List<Template> all = store.templates;
        final List<Template> list = q.isEmpty
            ? all
            : all
                .where((Template t) => t.name.toLowerCase().contains(q))
                .toList();

        return Container(
          color: p.isDark ? p.surface : const Color(0xFFFBFBFE),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _header(context, p, collapsed),
              if (!collapsed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: _searchBox(p),
                ),
              Expanded(
                child: list.isEmpty
                    ? _empty(p, collapsed)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: list.length,
                        itemBuilder: (BuildContext ctx, int i) {
                          final Template t = list[i];
                          return _TemplateTile(
                            template: t,
                            collapsed: collapsed,
                            active: t.id == store.active?.id,
                            onTap: () {
                              Store.instance.selectTemplate(t.id);
                              widget.onSelectTemplate?.call();
                            },
                            onMore: () => showTemplateActionsSheet(
                              context,
                              template: t,
                              onBuild: () => widget.onBuildTemplate?.call(t),
                            ),
                          );
                        },
                      ),
              ),
              _footer(context, p, collapsed),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, AppPalette p, bool collapsed) {
    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 8),
        child: Column(
          children: <Widget>[
            _iconBtn(
              icon: Icons.chevron_right_rounded,
              onTap: widget.onToggleCollapse,
              tooltip: '展开模板栏',
            ),
            const SizedBox(height: 4),
            _iconBtn(
              icon: Icons.add_rounded,
              onTap: widget.onCreateTemplate,
              tooltip: '新建模板',
              highlight: true,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 10, 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '我的模板',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: p.ink,
              ),
            ),
          ),
          _iconBtn(
            icon: Icons.menu_open_rounded,
            onTap: widget.onToggleCollapse,
            tooltip: '折叠模板栏',
          ),
        ],
      ),
    );
  }

  Widget _searchBox(AppPalette p) {
    return Container(
      decoration: BoxDecoration(
        color: p.isDark ? p.surface2 : const Color(0xFFEFF0F6),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: <Widget>[
          Icon(Icons.search_rounded, size: 17, color: p.muted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (String v) => setState(() => _query = v),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              style: TextStyle(fontSize: 14, color: p.ink),
              cursorColor: AppColors.primary,
              decoration: InputDecoration.collapsed(
                hintText: '搜索模板',
                hintStyle: TextStyle(color: p.muted, fontSize: 14),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _search.clear();
                setState(() => _query = '');
              },
              child: Icon(Icons.close_rounded, size: 16, color: p.muted),
            ),
        ],
      ),
    );
  }

  Widget _empty(AppPalette p, bool collapsed) {
    if (collapsed) return const SizedBox.shrink();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          _query.isEmpty ? '还没有模板' : '没有匹配的模板',
          style: TextStyle(fontSize: 13, color: p.muted),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context, AppPalette p, bool collapsed) {
    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 6),
        child: Column(
          children: <Widget>[
            _iconBtn(
              icon: Icons.settings_outlined,
              onTap: widget.onOpenSettings,
              tooltip: '设置',
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.line2)),
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 46,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onCreateTemplate,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('新建模板', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: Color(0xFFD3D7EA), width: 1.6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: widget.onOpenSettings,
            icon: Icon(Icons.settings_outlined, size: 17, color: p.muted),
            label: Text('设置', style: TextStyle(fontWeight: FontWeight.w700, color: p.muted)),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              alignment: Alignment.centerLeft,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.cloud_done_outlined, size: 13, color: p.muted2),
              const SizedBox(width: 6),
              Text(
                '所有修改已自动保存',
                style: TextStyle(fontSize: 11.5, color: p.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    VoidCallback? onTap,
    String? tooltip,
    bool highlight = false,
  }) {
    final Widget child = IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: highlight ? const Color(0xFFEEF0FF) : null,
        foregroundColor: highlight ? AppColors.primary : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
    return child;
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.active,
    required this.collapsed,
    required this.onTap,
    required this.onMore,
  });

  final Template template;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final List<Color> seed = AppColors.seedFor(template.colorSeed);
    final int varCount = template.variables.length;
    final int fixedCount = template.fixedSegments.length;

    final Widget avatar = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: seed,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        template.initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onMore,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 12, vertical: 10),
            decoration: BoxDecoration(
              color: active ? p.surface : Colors.transparent,
              border: Border.all(
                color: active ? p.varBorder : Colors.transparent,
                width: 1.4,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: active
                  ? <BoxShadow>[
                      BoxShadow(
                        color: const Color(0x334F5BFF),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                        spreadRadius: -14,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: <Widget>[
                avatar,
                if (!collapsed) ...<Widget>[
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          template.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: active ? AppColors.primary : p.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$varCount 变量 · $fixedCount 固定段',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: p.muted),
                        ),
                      ],
                    ),
                  ),
                  if (active)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                    )
                  else
                    IconButton(
                      onPressed: onMore,
                      icon: Icon(Icons.more_horiz_rounded, size: 18, color: p.muted),
                      visualDensity: VisualDensity.compact,
                      tooltip: '模板操作',
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
