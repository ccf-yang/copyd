import '../model/segment.dart';
import '../model/template.dart';

/// 变量为空时的默认占位符。
const String kDefaultEmptyPlaceholder = '[待填写]';

/// 把一个模板按片段顺序拼装成最终要复制的文本。
///
/// 纯函数，不依赖任何 Flutter API，可直接单测。
/// - 固定文本原样输出；
/// - 变量输出其 value（去除首尾空白）；为空则输出 [emptyPlaceholder]。
String buildText(
  Template template, {
  String emptyPlaceholder = kDefaultEmptyPlaceholder,
}) {
  final StringBuffer buffer = StringBuffer();
  for (final Segment s in template.sortedSegments) {
    if (s.isVariable) {
      final String v = s.value.trim();
      buffer.write(v.isEmpty ? emptyPlaceholder : v);
    } else {
      buffer.write(s.text);
    }
  }
  return buffer.toString();
}

/// 返回所有「值为空」的变量名，用于复制前提示。
List<String> emptyVariableNames(Template template) {
  return template.sortedSegments
      .where((Segment s) => s.isVariable && s.value.trim().isEmpty)
      .map((Segment s) => s.name.trim().isEmpty ? '未命名变量' : s.name.trim())
      .toList();
}

/// 文本长度（按 Unicode 码点计数，中文/emoji 均计为 1）。
int textLength(String text) => text.runes.length;
