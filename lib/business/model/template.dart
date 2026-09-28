import '../util/id.dart';
import 'segment.dart';

/// 一个复制模板：一个名字 + 一串按顺序排列的片段。
class Template {
  Template({
    String? id,
    required this.name,
    this.colorSeed = 0,
    List<Segment>? segments,
    int? updatedAt,
  })  : id = (id == null || id.isEmpty) ? newId('t') : id,
        segments = segments ?? <Segment>[],
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  final String id;
  String name;

  /// 左侧栏首字母色块的取色索引（0..N），UI 层映射为具体颜色。
  int colorSeed;

  List<Segment> segments;
  int updatedAt;

  /// 按 order 排序后的片段（不修改原列表）。
  List<Segment> get sortedSegments {
    final List<Segment> list = List<Segment>.of(segments);
    list.sort((Segment a, Segment b) => a.order.compareTo(b.order));
    return list;
  }

  List<Segment> get variables =>
      sortedSegments.where((Segment s) => s.isVariable).toList();

  List<Segment> get fixedSegments =>
      sortedSegments.where((Segment s) => s.isFixed).toList();

  /// 左侧栏展示用的首字母。
  String get initial {
    final String n = name.trim();
    if (n.isEmpty) return '？';
    return n.characters_first;
  }

  void touch() {
    updatedAt = DateTime.now().millisecondsSinceEpoch;
  }

  /// 把 order 重排为 0..n-1，避免排序出现空洞。
  void normalizeOrder() {
    final List<Segment> list = sortedSegments;
    for (int i = 0; i < list.length; i++) {
      list[i].order = i;
    }
    segments = list;
  }

  Template copyWith({
    String? name,
    int? colorSeed,
    List<Segment>? segments,
    int? updatedAt,
    bool keepId = true,
  }) {
    return Template(
      id: keepId ? id : null,
      name: name ?? this.name,
      colorSeed: colorSeed ?? this.colorSeed,
      segments: segments ?? List<Segment>.of(this.segments),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'colorSeed': colorSeed,
        'updatedAt': updatedAt,
        'segments': segments.map((Segment s) => s.toJson()).toList(),
      };

  factory Template.fromJson(Map<String, dynamic> json) {
    final Object? rawSegments = json['segments'];
    final List<Segment> parsed = <Segment>[];
    if (rawSegments is List) {
      for (final Object? item in rawSegments) {
        if (item is Map) {
          parsed.add(Segment.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final Object? rawSeed = json['colorSeed'];
    final Object? rawUpdated = json['updatedAt'];
    final Template t = Template(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '未命名模板',
      colorSeed: rawSeed is num ? rawSeed.toInt() : 0,
      segments: parsed,
      updatedAt: rawUpdated is num ? rawUpdated.toInt() : null,
    );
    t.normalizeOrder();
    return t;
  }

  /// 深拷贝（新模板 id + 新片段 id），用于「复制为模板」。
  Template duplicate({String? newName}) {
    return Template(
      name: newName ?? '$name 副本',
      colorSeed: colorSeed,
      segments: segments.map((Segment s) => s.cloneWithNewId()).toList(),
    )..normalizeOrder();
  }
}

extension on String {
  /// 取首个字符（对中文/emoji 都安全，避免直接 substring 截断代理对）。
  String get characters_first {
    if (isEmpty) return '？';
    final int first = runes.first;
    return String.fromCharCode(first);
  }
}
