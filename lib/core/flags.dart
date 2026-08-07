/// Извлекает флаг страны из имени ноды (emoji или текст).
String extractFlag(String name) {
  // Emoji флаги уже в имени
  final flagRegex = RegExp(r'[\u{1F1E6}-\u{1F1FF}]{2}', unicode: true);
  final match = flagRegex.firstMatch(name);
  if (match != null) return match.group(0)!;
  
  // Текстовые названия
  final lower = name.toLowerCase();
  const map = {
    'germany': '\u{1F1E9}\u{1F1EA}', 'deutschland': '\u{1F1E9}\u{1F1EA}', 'германия': '\u{1F1E9}\u{1F1EA}',
    'sweden': '\u{1F1F8}\u{1F1EA}', 'швеция': '\u{1F1F8}\u{1F1EA}',
    'finland': '\u{1F1EB}\u{1F1EE}', 'финляндия': '\u{1F1EB}\u{1F1EE}',
    'estonia': '\u{1F1EA}\u{1F1EA}', 'эстония': '\u{1F1EA}\u{1F1EA}',
    'poland': '\u{1F1F5}\u{1F1F1}', 'польша': '\u{1F1F5}\u{1F1F1}',
    'russia': '\u{1F1F7}\u{1F1FA}', 'россия': '\u{1F1F7}\u{1F1FA}',
    'lithuania': '\u{1F1F1}\u{1F1F9}', 'литва': '\u{1F1F1}\u{1F1F9}',
    'latvia': '\u{1F1F1}\u{1F1FB}', 'латвия': '\u{1F1F1}\u{1F1FB}',
    'netherlands': '\u{1F1F3}\u{1F1F1}', 'нидерланды': '\u{1F1F3}\u{1F1F1}',
    'turkey': '\u{1F1F9}\u{1F1F7}', 'турция': '\u{1F1F9}\u{1F1F7}',
    'usa': '\u{1F1FA}\u{1F1F8}', 'us': '\u{1F1FA}\u{1F1F8}', 'сша': '\u{1F1FA}\u{1F1F8}',
    'france': '\u{1F1EB}\u{1F1F7}', 'франция': '\u{1F1EB}\u{1F1F7}',
    'uk': '\u{1F1EC}\u{1F1E7}', 'britain': '\u{1F1EC}\u{1F1E7}', 'великобритания': '\u{1F1EC}\u{1F1E7}',
    'kazakhstan': '\u{1F1F0}\u{1F1FF}', 'казахстан': '\u{1F1F0}\u{1F1FF}',
  };
  for (final entry in map.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return '\u{1F310}';
}
