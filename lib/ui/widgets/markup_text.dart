import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

/// Renders Data Dragon's HTML-like markup (`<br>`, `<physicalDamage>`,
/// `<font color='#ff0'>`, `<li>`...) as styled rich text.
class MarkupText extends StatelessWidget {
  const MarkupText(this.markup, {super.key, this.style, this.maxLines});

  final String markup;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    return Text.rich(
      TextSpan(children: parseMarkup(markup, base)),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

final _token = RegExp(r'<(/?)([a-zA-Z0-9]+)([^>]*)>|([^<]+)');
final _colorAttr = RegExp(r'''color=['"]?#([0-9a-fA-F]{6})''');
final _placeholder = RegExp(r'\{\{[^}]*\}\}');

String _decode(String s) => s
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'");

List<InlineSpan> parseMarkup(String markup, TextStyle base) {
  final spans = <InlineSpan>[];
  final stack = <(String, TextStyle)>[('', base)];
  final text = markup.replaceAll(_placeholder, '?');

  for (final m in _token.allMatches(text)) {
    final literal = m.group(4);
    if (literal != null) {
      spans.add(TextSpan(text: _decode(literal), style: stack.last.$2));
      continue;
    }
    final closing = m.group(1) == '/';
    final tag = m.group(2)!.toLowerCase();
    final attrs = m.group(3) ?? '';

    if (tag == 'br') {
      spans.add(const TextSpan(text: '\n'));
      continue;
    }
    if (tag == 'li' && !closing) {
      spans.add(TextSpan(text: '\n• ', style: stack.last.$2));
      continue;
    }
    if (closing) {
      final idx = stack.lastIndexWhere((e) => e.$1 == tag);
      if (idx > 0) stack.removeRange(idx, stack.length);
      // The stats block is followed directly by the passive text.
      if (tag == 'stats') spans.add(const TextSpan(text: '\n'));
      continue;
    }
    var style = stack.last.$2;
    final colorMatch = _colorAttr.firstMatch(attrs);
    final color = colorMatch != null
        ? Color(int.parse('FF${colorMatch.group(1)}', radix: 16))
        : markupColors[tag];
    if (color != null) style = style.copyWith(color: color);
    if (markupBold.contains(tag)) style = style.copyWith(fontWeight: FontWeight.bold);
    if (tag == 'i' || tag == 'flavortext') style = style.copyWith(fontStyle: FontStyle.italic);
    stack.add((tag, style));
  }
  return spans;
}

/// Strips all markup, for plain previews and search.
String plainText(String markup) => _decode(
  markup
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll(_placeholder, '?'),
).trim();

/// Ensures a fixed style reference for gold accents.
TextStyle goldStyle(BuildContext context) =>
    Theme.of(context).textTheme.titleSmall!.copyWith(color: AppTheme.gold);
