/// 模板中的一个「片段」：要么是固定文本，要么是一个变量。
///
/// - 固定文本（fixed）：每次复制都原样保留，只读，位于编辑器下半区。
/// - 变量（variable）：每次复制前需要替换的值，位于编辑器上半区。
///
/// 片段通过 [order] 在整句中排序，固定/变量在展示时分区，但拼装时统一按 order 排序。
library;

import '../util/id.dart';

enum SegmentType { fixed, variable }

SegmentType segmentTypeFromName(String? wire) =>
    wire == 'variable' ? SegmentType.variable : SegmentType.fixed;

extension SegmentTypeWire on SegmentType {
  String get wire => this == SegmentType.variable ? 'variable' : 'fixed';
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String _asString(Object? value) => value?.toString() ?? '';

class Segment {
  Segment({
    String? id,
    required this.type,
    this.name = '',
    this.text = '',
    this.value = '',
    this.order = 0,
  }) : id = (id == null || id.isEmpty) ? newId('s') : id;

  final String id;
  final SegmentType type;

  /// 变量名（仅 variable 使用）。
  String name;

  /// 固定文本正文（仅 fixed 使用）。
  String text;

  /// 变量当前填入的值（仅 variable 使用）。
  String value;

  /// 整句中的顺序。
  int order;

  bool get isVariable => type == SegmentType.variable;
  bool get isFixed => type == SegmentType.fixed;

  /// 用于列表标题展示：变量显示名字，固定文本显示正文摘要。
  String get displayLabel {
    if (isVariable) return name.isEmpty ? '未命名变量' : name;
    return text;
  }

  Segment copyWith({
    String? type,
    String? name,
    String? text,
    String? value,
    int? order,
    bool keepId = true,
  }) {
    return Segment(
      id: keepId ? id : null,
      type: type == null ? this.type : segmentTypeFromName(type),
      name: name ?? this.name,
      text: text ?? this.text,
      value: value ?? this.value,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.wire,
        'name': name,
        'text': text,
        'value': value,
        'order': order,
      };

  factory Segment.fromJson(Map<String, dynamic> json) {
    return Segment(
      id: _asString(json['id']),
      type: segmentTypeFromName(json['type']?.toString()),
      name: _asString(json['name']),
      text: _asString(json['text']),
      value: _asString(json['value']),
      order: _asInt(json['order']),
    );
  }

  /// 深拷贝并生成新 id（用于「复制为模板」）。
  Segment cloneWithNewId() => copyWith(keepId: false);

  @override
  String toString() =>
      'Segment(${type.wire}, name=$name, text=$text, value=$value, order=$order)';
}
