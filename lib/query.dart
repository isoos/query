import 'src/ast.dart';
import 'src/grammar.dart';

export 'src/ast.dart';

final _parser = QueryGrammarDefinition().build<Query>();

/// Parses [input] and returns a parsed [Query].
Query parseQuery(String input) {
  return _parser.parse(input).value;
}
