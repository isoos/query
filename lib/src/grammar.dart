import 'package:petitparser/petitparser.dart';

import 'ast.dart';

class QueryParser extends GrammarParser {
  QueryParser() : super(const QueryGrammarDefinition());
}

class QueryGrammarDefinition extends GrammarDefinition {
  const QueryGrammarDefinition();

  @override
  Parser start() => ref(root).end();
  Parser token(Parser parser) => parser.flatten().trim();

  // Handles <exp> AND <exp> sequences (where AND is optional)
  Parser<Query> root() {
    final g =
        ref(or) & (ref(rootSep) & ref(or)).map((list) => list.last).star();
    return g.map((list) {
      final children = <Query>[list.first]..addAll((list.last as List).cast());
      if (children.length == 1) return children.single;
      return new AndQuery(children);
    });
  }

  Parser rootSep() => (ref(EXP_SEP) & string('AND')).optional() & ref(EXP_SEP);

  // Handles <exp> OR <exp> sequences.
  Parser<Query> or() {
    final g = ref(scopedExpression) &
        (string(' OR ') & ref(root)).map((list) => list.last).star();
    return g.map((list) {
      final children = <Query>[list.first]..addAll((list.last as List).cast());
      if (children.length == 1) return children.single;
      final second = children.last;
      if (children.length == 2 && second is OrQuery) {
        second.children.insert(0, children.first);
        return second;
      }
      return new OrQuery(children);
    });
  }

  // Handles scope:<exp>
  Parser<Query> scopedExpression() {
    final g =
        (ref(IDENTIFIER) & char(':')).optional().map((list) => list?.first) &
            ref(exclusion);
    return g.map((list) =>
        list.first == null ? list.last : new FieldScope(list.first, list.last));
  }

  // Handles -<exp>
  Parser<Query> exclusion() {
    final g = (char('-') | (string('NOT') & ref(EXP_SEP))).optional() &
        ref(expression);
    return g.map(
        (list) => list.first == null ? list.last : new NotQuery(list.last));
  }

  Parser expression() =>
      ref(group) | ref(exact) | ref(range) | ref(comparison) | ref(WORD);

  Parser group() => (char('(') & ref(root) & char(')')).map((list) => list[1]);

  Parser comparison() {
    final g = ref(IDENTIFIER) &
        ref(EXP_SEP).optional() &
        ref(COMP_OPERATOR) &
        ref(EXP_SEP).optional() &
        ref(wordOrExact);
    return g.map((list) => new FieldCompareQuery(list[0], list[2], list[4]));
  }

  Parser range() {
    final g = ref(rangeSep) &
        ref(wordOrExact) &
        string(' TO ') &
        ref(wordOrExact) &
        ref(rangeSep);
    return g.map((list) {
      return new RangeQuery(list[1], list[3],
          startInclusive: list[0] == '[', endInclusive: list[4] == ']');
    });
  }

  Parser rangeSep() => char('[') | char(']');

  Parser wordOrExact() => ref(exact) | ref(WORD);

  Parser exact() {
    final g = char('"') & pattern('^"').plus() & char('"');
    return g.map((list) => new TextQuery(list[1].join(), isExactMatch: true));
  }

  Parser<String> EXP_SEP() => WORD_SEP();

  Parser<String> WORD_SEP() => whitespace().plus().map((_) => ' ');

  Parser WORD() {
    final g = word().plus().map((list) => list.join());
    return g.map((str) => new TextQuery(str));
  }

  Parser<String> IDENTIFIER() => word().plus().map((list) => list.join());

  Parser COMP_OPERATOR() =>
      string('<=') |
      string('<') |
      string('>=') |
      string('>') |
      string('!=') |
      string('=');
}

Parser<String> nonWhitespace([String message = 'letter or digit expected']) {
  return CharacterParser(const NonWhitespaceCharPredicate(), message);
}

class NonWhitespaceCharPredicate implements CharacterPredicate {
  const NonWhitespaceCharPredicate();
  static final _ws = new WhitespaceCharPredicate();

  @override
  bool test(int value) => !_ws.test(value);
}

Parser<String> anyCharExcept(String except,
    [String message = 'letter or digit expected']) {
  return CharacterParser(const NonWhitespaceCharPredicate(), message);
}

class AnyCharExceptPredicate implements CharacterPredicate {
  final String except;
  AnyCharExceptPredicate(this.except);
  static final _ws = new WhitespaceCharPredicate();

  @override
  bool test(int value) => !_ws.test(value) && !except.codeUnits.contains(value);
}
