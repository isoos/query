// ignore_for_file: non_constant_identifier_names

import 'package:petitparser/petitparser.dart';

import 'ast.dart';

class QueryGrammarDefinition extends GrammarDefinition {
  const QueryGrammarDefinition();

  @override
  Parser<Query> start() => ref0(root).end();
  Parser token(Parser parser) => parser.flatten().trim();

  // Handles <exp> AND <exp> sequences (where AND is optional)
  Parser<Query> root() {
    final g =
        ref0(or) & (ref0(rootSep) & ref0(or)).map((list) => list.last).star();
    return g.token().map((list) {
      final children = <Query>[
        list.value.first as Query,
        ...(list.value.last as List).cast<Query>(),
      ];
      if (children.length == 1) return children.single;
      return AndQuery(
          children: children, position: SourcePosition(list.start, list.stop));
    });
  }

  Parser rootSep() =>
      (ref0(EXP_SEP) & string('AND')).optional() & ref0(EXP_SEP);

  // Handles <exp> OR <exp> sequences.
  Parser<Query> or() {
    final g = (ref0(group) | ref0(scopedExclusion) | ref0(exclusion)) &
        ((string(' | ') | string(' OR ')) & ref0(root))
            .map((list) => list.last)
            .star();
    return g.token().map((list) {
      final children = <Query>[
        list.value.first as Query,
        for (final query in (list.value.last as List).cast<Query>())
          // flatten OrQuery children
          if (query is OrQuery)
            for (final child in query.children) child
          else
            query,
      ];
      if (children.length == 1) return children.single;
      return OrQuery(
          children: children, position: SourcePosition(list.start, list.stop));
    });
  }

  Parser exclusionSep() => char('-') | (string('NOT') & ref0(EXP_SEP));

  // Handles scope:<exp>
  Parser<Query> scopedExpression() {
    final g = (anyCharExcept(':').flatten().textQuery() & char(':')) &
        ref0(exclusion).orEmptyTextQuery();
    return g.token().map((list) => list.value.first == null
        ? list.value.last as Query
        : FieldScopeQuery(
            field: list.value.first as TextQuery,
            child: list.value.last as Query,
            position: SourcePosition(list.start, list.stop)));
  }

  // Handles -scope:<exp>
  Parser<Query> scopedExclusion() {
    final g = exclusionSep().optional() & ref0(scopedExpression);
    return g.token().map((list) => list.value.first == null
        ? list.value.last as Query
        : NotQuery(
            child: list.value.last as Query,
            position: SourcePosition(list.start, list.stop)));
  }

  // Handles -<exp>
  Parser<Query> exclusion() {
    final g = exclusionSep().optional() & ref0(expression);
    return g.token().map((list) => list.value.first == null
        ? list.value.last as Query
        : NotQuery(
            child: list.value.last as Query,
            position: SourcePosition(list.start, list.stop)));
  }

  Parser expression() =>
      ref0(group) | ref0(exact) | ref0(range) | ref0(comparison) | ref0(WORD);

  Parser<GroupQuery> group() {
    final g = char('(') &
        ref0(EXP_SEP).star() &
        ref0(root).orEmptyTextQuery() &
        ref0(EXP_SEP).star() &
        char(')');
    return g.token().map((list) => GroupQuery(
        child: list.value[2] as Query,
        position: SourcePosition(list.start, list.stop)));
  }

  Parser<FieldCompareQuery> comparison() {
    final g = ref0(IDENTIFIER).textQuery() &
        ref0(EXP_SEP).optional() &
        ref0(COMP_OPERATOR).textQuery() &
        ref0(EXP_SEP).optional() &
        ref0(wordOrExact).orEmptyTextQuery();
    return g.token().map((list) => FieldCompareQuery(
        field: list.value[0] as TextQuery,
        operator: list.value[2] as TextQuery,
        text: list.value[4] as TextQuery,
        position: SourcePosition(list.start, list.stop)));
  }

  Parser<RangeQuery> range() {
    final g = ref0(rangeSep) &
        ref0(wordOrExact) &
        string(' TO ') &
        ref0(wordOrExact) &
        ref0(rangeSep);
    return g.token().map((list) {
      return RangeQuery(
          start: list.value[1] as TextQuery,
          end: list.value[3] as TextQuery,
          startInclusive: list.value[0] == '[',
          endInclusive: list.value[4] == ']',
          position: SourcePosition(list.start, list.stop));
    });
  }

  Parser rangeSep() => char('[') | char(']');

  Parser<TextQuery> wordOrExact() =>
      (ref0(exact) | ref0(WORD)).cast<TextQuery>();

  Parser<TextQuery> exactWord() =>
      pattern('^" \t\n\r').plus().flatten().textQuery();

  Parser<PhraseQuery> exact() {
    final g = char('"') &
        ref0(EXP_SEP).star().flatten() &
        (ref0(exactWord) & ref0(EXP_SEP).star().flatten()).star() &
        char('"');
    return g.token().map((list) {
      final children = <TextQuery>[];
      var phrase = list.value[1] as String;
      for (var w in list.value[2]) {
        final word = w.first as TextQuery;
        final sep = w[1] as String;
        children.add(word);
        phrase += '${word.text}$sep';
      }
      return PhraseQuery(
          text: phrase,
          children: children,
          position: SourcePosition(list.start, list.stop));
    });
  }

  Parser<String> EXP_SEP() => WORD_SEP();

  Parser<String> WORD_SEP() => whitespace().plus().map((_) => ' ');

  Parser<TextQuery> WORD() => allowedChars().plus().flatten().textQuery();

  Parser<String> IDENTIFIER() => allowedChars().plus().flatten();

  Parser<String> COMP_OPERATOR() => (string('<=') |
          string('<') |
          string('>=') |
          string('>') |
          string('!=') |
          string('='))
      .flatten();

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
      .flatten();
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

extension on Parser<String> {
  Parser<TextQuery> textQuery() => token().map((str) => TextQuery(
      text: str.value, position: SourcePosition(str.start, str.stop)));
}

extension on Parser<Query?> {
  Parser<Query> orEmptyTextQuery() => optional().token().map((value) =>
      value.value ??
      TextQuery(text: '', position: SourcePosition(value.start, value.stop)));
}
