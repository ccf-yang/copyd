import 'dart:math';

final Random _rng = Random();

/// 生成短小且基本唯一的本地 id（纯 Dart，可在单测中直接使用）。
/// 形如 `s_m3k9x2_1f4a`，前缀区分用途。
String newId([String prefix = 'id']) {
  final String time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final String rand = _rng.nextInt(1 << 32).toRadixString(36);
  return '${prefix}_${time}_$rand';
}
