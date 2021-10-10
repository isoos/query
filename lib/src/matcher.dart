import 'package:query/src/ast.dart';

//Matching Operators
const String OP_LESS_OR_EQUAL = '<=';
const String OP_LESS = '<';
const String OP_MORE_OR_EQUAL = '>=';
const String OP_MORE = '>';
const String OP_NOT_EQAUL = '!=';
const String OP_EQUAL = '=';

abstract class QueryMatcher {
  //AnyField indicates any field
  static final String AnyField = '';
  //getFieldMatcher returns a matcher for a specific field
  QueryMatcher? getFieldMatcher(String field);
  //matches a field
  bool matchField(String field, String operator, TextQuery text);
  // matches a range
  bool matchRange(
      TextQuery start, bool startInclusive, TextQuery end, bool endInclusive);
}
