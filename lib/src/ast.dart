/// A class that describes the position of the source text.
class SourcePosition {
  const SourcePosition(this.start, this.end);

  /// The start position of this query.
  final int start;

  /// The end position of this query, exclusive.
  final int end;

  // The length of this query, in characters.
  int get length => end - start;
}

/// Base interface for queries.
abstract class Query {
  const Query({
    required this.position,
  });

  /// The position of this query relative to the source.
  final SourcePosition position;

  /// Returns a String-representation of this [Query].
  ///
  /// Implementation should aim to provide a format that can be parsed to the
  /// same form.
  ///
  /// [debug] is used to extend the format with additional characters, making
  /// testing unambiguous.
  @override
  String toString({bool debug = false});

  /// Returns this [Query] cast as [R]
  ///
  /// If the [Query] cannot be cast to [R] it will throw an exception.
  R cast<R extends Query>() => this as R;
}

/// Text query to match [text].
class TextQuery extends Query {
  final String text;
  const TextQuery({
    required this.text,
    required super.position,
  });

  @override
  String toString({bool debug = false}) => _debug(debug, text);
}

/// Phrase query to match "[text]" for a list of words inside quotes.
class PhraseQuery extends TextQuery {
  final List<TextQuery> children;
  const PhraseQuery({
    required super.text,
    required this.children,
    required super.position,
  });

  @override
  String toString({bool debug = false}) =>
      '"${children.map((n) => n.toString(debug: debug)).join(' ')}"';
}

/// Scopes [child] [Query] to be applied only on the [field].
class FieldScope extends Query {
  final TextQuery field;
  final Query child;

  const FieldScope({
    required this.field,
    required this.child,
    required super.position,
  });

  @override
  String toString({bool debug = false}) =>
      '$field:${child.toString(debug: debug)}';
}

/// Describes a [field] [operator] [text] tripled (e.g. year < 2000).
class FieldCompareQuery extends Query {
  final TextQuery field;
  final TextQuery operator;
  final TextQuery text;

  const FieldCompareQuery({
    required this.field,
    required this.operator,
    required this.text,
    required super.position,
  });

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

  const RangeQuery({
    required this.start,
    required this.end,
    required super.position,
    this.startInclusive = true,
    this.endInclusive = true,
  });

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
  const NotQuery({
    required this.child,
    required super.position,
  });

  @override
  String toString({bool debug = false}) => '-${child.toString(debug: debug)}';
}

/// Groups the [child] query to override implicit precedence.
class GroupQuery extends Query {
  final Query child;
  const GroupQuery({
    required this.child,
    required super.position,
  });

  @override
  String toString({bool debug = false}) => '(${child.toString(debug: debug)})';
}

/// Bool AND composition of [children] queries.
class AndQuery extends Query {
  final List<Query> children;

  const AndQuery({
    required this.children,
    required super.position,
  });

  @override
  String toString({bool debug = false}) =>
      '(${children.map((n) => n.toString(debug: debug)).join(' ')})';
}

/// Bool OR composition of [children] queries.
class OrQuery extends Query {
  final List<Query> children;

  const OrQuery({
    required this.children,
    required super.position,
  });

  @override
  String toString({bool debug = false}) =>
      '(${children.map((n) => n.toString(debug: debug)).join(' OR ')})';
}

String _debug(bool debug, String expr) => debug ? '<$expr>' : expr;
