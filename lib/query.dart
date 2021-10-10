import 'package:query/src/grammar.dart';

import 'src/ast.dart';

export 'src/ast.dart';

final _parser = QueryGrammarDefinition().build();

/// Parses [input] and returns a parsed [Query].
Query parseQuery(String input) {
  return _parser.parse(input).value as Query;
}
