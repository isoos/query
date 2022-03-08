import 'package:petitparser/petitparser.dart';

import 'ast.dart';

@Deprecated('Use QueryGrammarDefinition.build instead.')
class QueryParser extends GrammarParser {
  QueryParser() : super(const QueryGrammarDefinition());
}

class QueryGrammarDefinition extends GrammarDefinition {
  const QueryGrammarDefinition();

  @override
  Parser start() => ref0(root).end();
  Parser token(Parser parser) => parser.flatten().trim();

  // Handles <exp> AND <exp> sequences (where AND is optional)
  Parser<Query> root() {
    final g =
        ref0(or) & (ref0(rootSep) & ref0(or)).map((list) => list.last).star();
    return g.map((list) {
      final children = <Query>[
        list.first as Query,
        ...(list.last as List).cast<Query>(),
      ];
      if (children.length == 1) return children.single;
      return AndQuery(children);
    });
  }

  Parser rootSep() =>
      (ref0(EXP_SEP) & string('AND')).optional() & ref0(EXP_SEP);

  // Handles <exp> OR <exp> sequences.
  Parser<Query> or() {
    final g = (ref0(scopedExpression) | ref0(group)) &
        ((string(' | ') | string(' OR ')) & ref0(root))
            .map((list) => list.last)
            .star();
    return g.map((list) {
      final children = <Query>[
        list.first as Query,
        ...(list.last as List).cast<Query>(),
      ];
      if (children.length == 1) return children.single;
      final second = children.last;
      if (children.length == 2 && second is OrQuery) {
        second.children.insert(0, children.first);
        return second;
      }
      return OrQuery(children);
    });
  }

  // Handles scope:<exp>
  Parser<Query> scopedExpression() {
    final g =
        (anyCharExcept(':') & char(':')).optional().map((list) => list?.first) &
            ref0(exclusion);
    return g.map((list) => list.first == null
        ? list.last as Query
        : FieldScope(list.first as String, list.last as Query));
  }

  // Handles -<exp>
  Parser<Query> exclusion() {
    final g = (char('-') | (string('NOT') & ref0(EXP_SEP))).optional() &
        ref0(expression);
    return g.map((list) =>
        list.first == null ? list.last as Query : NotQuery(list.last as Query));
  }

  Parser expression() =>
      ref0(group) | ref0(exact) | ref0(range) | ref0(comparison) | ref0(WORD);

  Parser group() => (char('(') &
          ref0(EXP_SEP).star() &
          ref0(root).optional() &
          ref0(EXP_SEP).star() &
          char(')'))
      .map((list) => list[2] == null
          ? GroupQuery(TextQuery(''))
          : GroupQuery(list[2] as Query));

  Parser comparison() {
    final g = ref0(IDENTIFIER) &
        ref0(EXP_SEP).optional() &
        ref0(COMP_OPERATOR) &
        ref0(EXP_SEP).optional() &
        ref0(wordOrExact);
    return g.map((list) => FieldCompareQuery(
        list[0] as String, list[2] as String, list[4] as TextQuery));
  }

  Parser range() {
    final g = ref0(rangeSep) &
        ref0(wordOrExact) &
        string(' TO ') &
        ref0(wordOrExact) &
        ref0(rangeSep);
    return g.map((list) {
      return RangeQuery(list[1] as TextQuery, list[3] as TextQuery,
          startInclusive: list[0] == '[', endInclusive: list[4] == ']');
    });
  }

  Parser rangeSep() => char('[') | char(']');

  Parser wordOrExact() => ref0(exact) | ref0(WORD);

  Parser exact() {
    final g = char('"') &
        ref0(EXP_SEP).star() &
        (pattern('^" \t\n\r').plus() & ref0(EXP_SEP).star()).star() &
        char('"');
    return g.map((list) {
      final children = <TextQuery>[];
      var phrase = list[1].join() as String;
      for (var w in list[2]) {
        var word = w.first.join() as String;
        var sep = w[1].join() as String;
        phrase += '$word$sep';
        children.add(TextQuery(word));
      }
      return PhraseQuery(phrase, children);
    });
  }

  Parser<String> EXP_SEP() => WORD_SEP();

  Parser<String> WORD_SEP() => whitespace().plus().map((_) => ' ');

  Parser WORD() {
    final g = allowedChars().plus().map((list) => list.join());
    return g.map((str) => TextQuery(str));
  }

  Parser<String> IDENTIFIER() =>
      allowedChars().plus().map((list) => list.join());

  Parser COMP_OPERATOR() =>
      string('<=') |
      string('<') |
      string('>=') |
      string('>') |
      string('!=') |
      string('=');

  Parser<String> allowedChars() => anyCharExcept('[]():<!=>"');
}

Parser<String> extendedWord([String message = 'letter or digit expected']) {
  return CharacterParser(const ExtendedWordCharPredicate(), message);
}

class ExtendedWordCharPredicate implements CharacterPredicate {
  const ExtendedWordCharPredicate();

  @override
  bool test(int value) {
    return (65 <= value && value <= 90 /* A..Z */) ||
        (97 <= value && value <= 122 /* a..z */) ||
        (48 <= value && value <= 57 /* 0..9 */) ||
        (value == 95 /* _ */) ||
        (value > 128);
  }

  @override
  bool isEqualTo(CharacterPredicate other) {
    return (other is ExtendedWordCharPredicate);
  }
}

Parser<String> anyCharExcept(String except,
    [String message = 'letter or digit expected']) {
  return CharacterParser(AnyCharExceptPredicate(except.codeUnits), message)
      .plus()
      .map((list) => list.join());
}

class AnyCharExceptPredicate implements CharacterPredicate {
  final List<int> exceptCodeUnits;
  AnyCharExceptPredicate(this.exceptCodeUnits);
  static final _ws = WhitespaceCharPredicate();

  @override
  bool test(int value) => !_ws.test(value) && !exceptCodeUnits.contains(value);

  @override
  bool isEqualTo(CharacterPredicate other) {
    return (other is AnyCharExceptPredicate) && identical(this, other);
  }
}
