Map<String, dynamic> asStringDynamicMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

List<dynamic> readListPayload(dynamic value, List<String> preferredKeys) {
  if (value is List) return value;

  final map = asStringDynamicMap(value);
  for (final key in preferredKeys) {
    final item = map[key];
    if (item is List) return item;
    if (item is Map) {
      final nested = readListPayload(item, preferredKeys);
      if (nested.isNotEmpty) return nested;
    }
  }

  final data = map['data'];
  if (data is List) return data;
  if (data is Map) {
    for (final key in preferredKeys) {
      final item = data[key];
      if (item is List) return item;
      if (item is Map) {
        final nested = readListPayload(item, preferredKeys);
        if (nested.isNotEmpty) return nested;
      }
    }

    final paginatorItems = data['data'];
    if (paginatorItems is List) return paginatorItems;
  }

  return const [];
}

Map<String, dynamic> readMapPayload(dynamic value, List<String> preferredKeys) {
  final map = asStringDynamicMap(value);
  if (map.isEmpty) return map;

  for (final key in preferredKeys) {
    final item = map[key];
    if (item is Map) return asStringDynamicMap(item);
  }

  final data = map['data'];
  if (data is Map) {
    final dataMap = asStringDynamicMap(data);
    for (final key in preferredKeys) {
      final item = dataMap[key];
      if (item is Map) return asStringDynamicMap(item);
    }
    return dataMap;
  }

  return map;
}

String? readString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? readInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? readDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(',', '.'));
}

bool readBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return defaultValue;
}

DateTime? readDateTime(dynamic value) {
  final text = readString(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}
