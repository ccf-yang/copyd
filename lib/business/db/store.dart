import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/composer.dart';
import '../model/segment.dart';
import '../model/template.dart';

/// 全局数据仓库（单例）。
///
/// 职责：
/// - 持有模板列表与当前选中模板；
/// - 所有增删改：先改内存 → notifyListeners() → 防抖落盘；
/// - 冷启动 load()，异常降级为空列表，不崩溃。
class Store extends ChangeNotifier {
  Store._();

  static final Store instance = Store._();

  static const String prefsKey = 'copyd.data.v1';
  static const int schemaVersion = 1;

  final List<Template> _templates = <Template>[];
  String _activeId = '';
  bool _loaded = false;
  Timer? _saveTimer;

  // ---- 设置项 ----
  bool _clearVarsAfterCopy = true;
  String _emptyPlaceholder = kDefaultEmptyPlaceholder;
  String _themeMode = 'system';

  // ================= 只读视图 =================

  List<Template> get templates => List<Template>.unmodifiable(_templates);
  bool get isLoaded => _loaded;
  bool get isEmpty => _templates.isEmpty;
  String get activeId => _activeId;

  bool get clearVarsAfterCopy => _clearVarsAfterCopy;
  String get emptyPlaceholder => _emptyPlaceholder;
  String get themeMode => _themeMode; // system | light | dark

  /// 当前模板；列表为空时返回 null；activeId 失效时回退第一条。
  Template? get active {
    if (_templates.isEmpty) return null;
    for (final Template t in _templates) {
      if (t.id == _activeId) return t;
    }
    return _templates.first;
  }

  /// 当前模板拼装后的文本（供复制栏预览）。
  String get activeText {
    final Template? t = active;
    if (t == null) return '';
    return buildText(t, emptyPlaceholder: _emptyPlaceholder);
  }

  List<String> get activeEmptyVariables {
    final Template? t = active;
    if (t == null) return const <String>[];
    return emptyVariableNames(t);
  }

  /// 数据是否发生过写入（UI 展示「已自动保存」）。
  bool get hasUnsavedChanges => _saveTimer?.isActive ?? false;

  // ================= 生命周期 =================

  /// App 启动调用。失败/超时不应阻塞启动。
  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final Object? decoded = jsonDecode(raw);
        if (decoded is Map) {
          _applyDecoded(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (e) {
      debugPrint('Store.load failed: $e');
      _templates.clear();
      _activeId = '';
    } finally {
      _loaded = true;
      _ensureActive();
      notifyListeners();
    }
  }

  void _applyDecoded(Map<String, dynamic> json) {
    _templates.clear();
    final Object? rawList = json['templates'];
    if (rawList is List) {
      for (final Object? item in rawList) {
        if (item is Map) {
          _templates.add(Template.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    _activeId = json['activeId']?.toString() ?? '';
    final Object? settings = json['settings'];
    if (settings is Map) {
      final Map<String, dynamic> s = Map<String, dynamic>.from(settings);
      _clearVarsAfterCopy = s['clearVarsAfterCopy'] as bool? ?? true;
      _emptyPlaceholder =
          s['emptyPlaceholder']?.toString() ?? kDefaultEmptyPlaceholder;
      _themeMode = s['themeMode']?.toString() ?? 'system';
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': schemaVersion,
        'activeId': _activeId,
        'templates': _templates.map((Template t) => t.toJson()).toList(),
        'settings': <String, dynamic>{
          'clearVarsAfterCopy': _clearVarsAfterCopy,
          'emptyPlaceholder': _emptyPlaceholder,
          'themeMode': _themeMode,
        },
      };

  /// 导出为可读 JSON（设置页「导出全部模板」）。
  String exportJson() =>
      const JsonEncoder.withIndent('  ').convert(toJson());

  /// 立即落盘。变更方法内部走 [_scheduleSave]，一般无需手动调用。
  Future<void> save() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, jsonEncode(toJson()));
    } catch (e) {
      debugPrint('Store.save failed: $e');
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), () {
      save();
    });
  }

  void _commit() {
    notifyListeners();
    _scheduleSave();
  }

  void _ensureActive() {
    if (_templates.isEmpty) {
      _activeId = '';
      return;
    }
    final bool exists =
        _templates.any((Template t) => t.id == _activeId);
    if (!exists) {
      _activeId = _templates.first.id;
    }
  }

  // ================= 设置项 =================

  void setClearVarsAfterCopy(bool value) {
    if (_clearVarsAfterCopy == value) return;
    _clearVarsAfterCopy = value;
    _commit();
  }

  void setEmptyPlaceholder(String value) {
    final String v = value.isEmpty ? kDefaultEmptyPlaceholder : value;
    if (_emptyPlaceholder == v) return;
    _emptyPlaceholder = v;
    _commit();
  }

  void setThemeMode(String value) {
    if (_themeMode == value) return;
    _themeMode = value;
    _commit();
  }

  // ================= 模板维度 =================

  Template createTemplate({String name = '未命名模板'}) {
    final Template t = Template(
      name: name,
      colorSeed: _templates.length % 6,
    );
    _templates.add(t);
    _activeId = t.id;
    _commit();
    return t;
  }

  void selectTemplate(String id) {
    if (_activeId == id) return;
    if (!_templates.any((Template t) => t.id == id)) return;
    _activeId = id;
    _commit();
  }

  void renameTemplate(String id, String name) {
    final Template? t = _findTemplate(id);
    if (t == null) return;
    final String n = name.trim();
    if (n.isEmpty || n == t.name) return;
    t.name = n;
    t.touch();
    _commit();
  }

  /// 复制为新模板，并切换过去。
  Template? duplicateTemplate(String id) {
    final Template? t = _findTemplate(id);
    if (t == null) return null;
    final Template copy = t.duplicate();
    _templates.add(copy);
    _activeId = copy.id;
    _commit();
    return copy;
  }

  void deleteTemplate(String id) {
    final int index = _templates.indexWhere((Template t) => t.id == id);
    if (index < 0) return;
    _templates.removeAt(index);
    _ensureActive();
    _commit();
  }

  void clearAll() {
    _templates.clear();
    _activeId = '';
    _commit();
  }

  /// 按更新时间排序后的模板（供列表展示，最近使用的在前可选）。
  List<Template> get templatesByUpdatedAt {
    final List<Template> list = List<Template>.of(_templates);
    list.sort((Template a, Template b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Template? _findTemplate(String id) {
    for (final Template t in _templates) {
      if (t.id == id) return t;
    }
    return null;
  }

  // ================= 片段维度 =================

  /// 在当前模板末尾追加固定文本。
  Segment? addFixed(String text) {
    final Template? t = active;
    if (t == null) return null;
    final Segment s = Segment(
      type: SegmentType.fixed,
      text: text,
      order: t.segments.length,
    );
    t.segments.add(s);
    t.normalizeOrder();
    t.touch();
    _commit();
    return s;
  }

  /// 在当前模板末尾追加变量。
  Segment? addVariable(String name, {String defaultValue = ''}) {
    final Template? t = active;
    if (t == null) return null;
    final Segment s = Segment(
      type: SegmentType.variable,
      name: name.trim(),
      value: defaultValue,
      order: t.segments.length,
    );
    t.segments.add(s);
    t.normalizeOrder();
    t.touch();
    _commit();
    return s;
  }

  /// 更新片段的文本/变量名。
  void updateSegment(
    String segmentId, {
    String? text,
    String? name,
  }) {
    final Segment? s = _findSegment(segmentId);
    if (s == null) return;
    if (text != null && text != s.text) s.text = text;
    if (name != null && name != s.name) s.name = name;
    active?.touch();
    _commit();
  }

  /// 设置变量值（使用态输入）。
  void setValue(String segmentId, String value) {
    final Segment? s = _findSegment(segmentId);
    if (s == null || !s.isVariable) return;
    if (s.value == value) return;
    s.value = value;
    active?.touch();
    _commit();
  }

  void clearValue(String segmentId) {
    final Segment? s = _findSegment(segmentId);
    if (s == null || !s.isVariable || s.value.isEmpty) return;
    s.value = '';
    active?.touch();
    _commit();
  }

  /// 清空当前模板所有变量的值。
  void clearAllValues() {
    final Template? t = active;
    if (t == null) return;
    bool changed = false;
    for (final Segment s in t.segments) {
      if (s.isVariable && s.value.isNotEmpty) {
        s.value = '';
        changed = true;
      }
    }
    if (!changed) return;
    t.touch();
    _commit();
  }

  void removeSegment(String segmentId) {
    final Template? t = active;
    if (t == null) return;
    final int index = t.segments.indexWhere((Segment s) => s.id == segmentId);
    if (index < 0) return;
    t.segments.removeAt(index);
    t.normalizeOrder();
    t.touch();
    _commit();
  }

  /// 在同一分区内（固定 / 变量）拖拽排序，保持两种片段在整句中的相对交织位置。
  ///
  /// [oldIndex] / [newIndex] 为 ReorderableListView 约定的下标
  /// （newIndex 为插入前的位置，需自行减 1）。
  void reorderByType(SegmentType type, int oldIndex, int newIndex) {
    final Template? t = active;
    if (t == null) return;

    final List<Segment> subset = t.sortedSegments
        .where((Segment s) => s.type == type)
        .toList();
    if (oldIndex < 0 || oldIndex >= subset.length) return;

    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex < 0) newIndex = 0;
    if (newIndex >= subset.length) newIndex = subset.length - 1;

    final Segment moved = subset.removeAt(oldIndex);
    subset.insert(newIndex, moved);

    final List<Segment> rebuilt = <Segment>[];
    int k = 0;
    for (final Segment s in t.sortedSegments) {
      rebuilt.add(s.type == type ? subset[k++] : s);
    }
    for (int i = 0; i < rebuilt.length; i++) {
      rebuilt[i].order = i;
    }
    t.segments = rebuilt;
    t.touch();
    _commit();
  }

  /// 把某个片段移动到整句的绝对位置（搭建态画布拖拽用）。
  void moveSegment(String segmentId, int targetIndex) {
    final Template? t = active;
    if (t == null) return;
    final List<Segment> list = t.sortedSegments;
    final int index = list.indexWhere((Segment s) => s.id == segmentId);
    if (index < 0) return;

    final Segment moved = list.removeAt(index);
    int target = targetIndex;
    if (target < 0) target = 0;
    if (target > list.length) target = list.length;
    list.insert(target, moved);

    for (int i = 0; i < list.length; i++) {
      list[i].order = i;
    }
    t.segments = list;
    t.touch();
    _commit();
  }

  /// 复制成功后调用：按设置清空变量值。
  void afterCopied() {
    if (_clearVarsAfterCopy) {
      clearAllValues();
    }
  }

  Segment? _findSegment(String segmentId) {
    for (final Template t in _templates) {
      for (final Segment s in t.segments) {
        if (s.id == segmentId) return s;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
