double toDoubleSafe(dynamic v, [double fallback = 0]) {
  if (v is int) return v.toDouble();
  if (v is double) return v;
  return fallback;
}

int toIntSafe(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is double) return v.round();
  return fallback;
}

String toStringSafe(dynamic v, [String fallback = '-']) {
  if (v == null) return fallback;
  return v.toString();
}
