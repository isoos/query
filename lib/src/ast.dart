/// Base interface for queries.
abstract class Query {
  const Query(this.startIndex, this.endIndex);

  /// The start index of the token from the input.
  final int startIndex;

  /// The end index of the token from the input.
  final int endIndex;

  /// Returns a String-representation of this [Query].
  ///
  /// Implementation should aim to provide a format that can be parsed to the
  /// same form.
  ///
  /// [debug] is used to extend the format with additional characters, making
  /// testing unambiguous.
  @override
  String toString({bool debug = false});
}

/// Text query to match [text].
///
/// [isExactMatch] is set when the [text] was inside quotes.
class TextQuery extends Query {
  final String text;
  final bool isExactMatch;
  const TextQuery(this.text, super.startIndex, super.endIndex,
      {this.isExactMatch = false});

  @override
  String toString({bool debug = false}) =>
      _debug(debug, isExactMatch ? '"$text"' : text);
}

/// Phrase query to match "[text]" for a list of words inside quotes.
class PhraseQuery extends TextQuery {
  final List<TextQuery> children;
  const PhraseQuery(
      super.phrase, this.children, super.startIndex, super.endIndex)
      : super(isExactMatch: true);

  @override
  String toString({bool debug = false}) =>
      '"' + children.map((n) => n.toString(debug: debug)).join(' ') + '"';
}

/// Scopes [child] [Query] to be applied only on the [field].
class FieldScope extends Query {
  final TextQuery fieldText;
  final Query child;

  const FieldScope(
      this.fieldText, this.child, super.startIndex, super.endIndex);

  String get field => fieldText.text;

  @override
  String toString({bool debug = false}) =>
      '$field:${child.toString(debug: debug)}';
}

/// Describes a [field] [operator] [text] tripled (e.g. year < 2000).
class FieldCompareQuery extends Query {
  final TextQuery fieldText;
  final TextQuery operatorText;
  final TextQuery text;

  const FieldCompareQuery(this.fieldText, this.operatorText, this.text,
      super.startIndex, super.endIndex);

  String get field => fieldText.text;

  String get operator => operatorText.text;

  @override
  String toString({bool debug = false}) =>
      _debug(debug, '$field$operator$text');
}

/// Describes a range query between [start] and [end].
class RangeQuery extends Query {
  final TextQuery start;
  final bool startInclusive;
  final TextQuery end;
  final bool endInclusive;

  const RangeQuery(this.start, this.end, super.startIndex, super.endIndex,
      {this.startInclusive = true, this.endInclusive = true});

  @override
  String toString({bool debug = false}) => _debug(
      debug,
      '${_sp(true, startInclusive)}${start.toString(debug: debug)} TO '
      '${end.toString(debug: debug)}${_sp(false, endInclusive)}');

  String _sp(bool start, bool inclusive) {
    return start ? (inclusive ? '[' : ']') : (inclusive ? ']' : '[');
  }
}

/// Negates the [child] query. (bool NOT)
class NotQuery extends Query {
  final Query child;
  const NotQuery(this.child, super.startIndex, super.endIndex);

  @override
  String toString({bool debug = false}) => '-${child.toString(debug: debug)}';
}

/// Groups the [child] query to override implicit precedence.
class GroupQuery extends Query {
  final Query child;
  const GroupQuery(this.child, super.startIndex, super.endIndex);

  @override
  String toString({bool debug = false}) => '(${child.toString(debug: debug)})';
}

/// Bool AND composition of [children] queries.
class AndQuery extends Query {
  final List<Query> children;

  const AndQuery(this.children, super.startIndex, super.endIndex);

  @override
  String toString({bool debug = false}) =>
      '(' + children.map((n) => n.toString(debug: debug)).join(' ') + ')';
}

/// Bool OR composition of [children] queries.
class OrQuery extends Query {
  final List<Query> children;

  const OrQuery(this.children, super.startIndex, super.endIndex);

  @override
  String toString({bool debug = false}) =>
      '(' + children.map((n) => n.toString(debug: debug)).join(' OR ') + ')';
}

String _debug(bool debug, String expr) => debug ? '<$expr>' : expr;
