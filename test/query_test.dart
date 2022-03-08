import 'package:query/query.dart';
import 'package:test/test.dart';

String debugQuery(String input) => parseQuery(input).toString(debug: true);

void main() {
  group('Base expressions', () {
    test('1 string', () {
      expect(debugQuery('abc'), '<abc>');
      expect(debugQuery('"abc"'), '"<abc>"');
      expect(debugQuery('abc*'), '<abc*>');
    });

    test('2 strings', () {
      expect(debugQuery('abc def'), '(<abc> <def>)');
      expect(debugQuery('"abc 1" def'), '("<abc> <1>" <def>)');
      expect(debugQuery('abc "def 2"'), '(<abc> "<def> <2>")');
      expect(debugQuery('"abc" "def"'), '("<abc>" "<def>")');
      expect(debugQuery('"abc 1" "def 2"'), '("<abc> <1>" "<def> <2>")');
    });

    test('explicit AND', () {
      expect(debugQuery('a AND b c'), '(<a> <b> <c>)');
    });

    test('negative word', () {
      expect(debugQuery('-abc'), '-<abc>');
      expect(debugQuery('-"abc"'), '-"<abc>"');
      expect(debugQuery('-"abc 1"'), '-"<abc> <1>"');

      expect(debugQuery('NOT abc'), '-<abc>');
      expect(debugQuery('NOT "abc"'), '-"<abc>"');
      expect(debugQuery('NOT "abc 1"'), '-"<abc> <1>"');
    });

    test('scoped', () {
      expect(debugQuery('a:abc'), 'a:<abc>');
      expect(debugQuery('a:"abc"'), 'a:"<abc>"');
      expect(debugQuery('a:"abc 1"'), 'a:"<abc> <1>"');
      expect(debugQuery('a:-"abc 1"'), 'a:-"<abc> <1>"');
    });

    test('special scoped', () {
      expect(debugQuery('a*:abc'), 'a*:<abc>');
      expect(debugQuery('a%:"abc"'), 'a%:"<abc>"');
    });

    test('compare', () {
      expect(debugQuery('year < 2000'), '<year<2000>');
      expect(debugQuery('field >= "test case"'), '<field>="test case">');
    });

    test('range', () {
      expect(debugQuery('[1 TO 10]'), '<[<1> TO <10>]>');
      expect(debugQuery(']1 TO 10['), '<]<1> TO <10>[>');
      expect(debugQuery(']"1 a" TO "10 b"['), '<]"<1> <a>" TO "<10> <b>"[>');
    });
  });

  group('or', () {
    test('2 items', () {
      expect(debugQuery('a OR b'), '(<a> OR <b>)');
    });

    test('2 items pipe', () {
      expect(debugQuery('a | b'), '(<a> OR <b>)');
    });

    test('3 items', () {
      expect(debugQuery('a OR b OR c'), '(<a> OR <b> OR <c>)');
    });

    test('3 items pipe', () {
      expect(debugQuery('a | b | c'), '(<a> OR <b> OR <c>)');
    });

    test('3 items pipe mixed', () {
      expect(debugQuery('a OR b | c'), '(<a> OR <b> OR <c>)');
      expect(debugQuery('a | b OR c'), '(<a> OR <b> OR <c>)');
    });

    test('precedence of implicit AND, explicit OR', () {
      expect(debugQuery('a b OR c'), '(<a> (<b> OR <c>))');
      expect(debugQuery('a OR b c'), '(<a> OR (<b> <c>))');
      expect(debugQuery('a OR b c OR d'), '(<a> OR (<b> (<c> OR <d>)))');
    });

    test('precedence of implicit AND, explicit OR pipe', () {
      expect(debugQuery('a b | c'), '(<a> (<b> OR <c>))');
      expect(debugQuery('a | b c'), '(<a> OR (<b> <c>))');
      expect(debugQuery('a | b c | d'), '(<a> OR (<b> (<c> OR <d>)))');
    });
  });

  group('complex cases', () {
    test('#1', () {
      expect(debugQuery('a:-v1 b:(beta OR moon < Deimos OR [a TO e])'),
          '(a:-<v1> b:((<beta> OR <moon<Deimos> OR <[<a> TO <e>]>)))');
    });

    test('#2', () {
      expect(debugQuery('a = 2000 b > 2000 c'), '(<a=2000> <b>2000> <c>)');
    });

    test('#3', () {
      // TODO: fix
      // expect(debugQuery('(f:abc)'), '');
    });
  });

  group('unicode chars', () {
    test('hungarian', () {
      expect(
          debugQuery('árvíztűrő TÜKÖRFÚRÓGÉP'), '(<árvíztűrő> <TÜKÖRFÚRÓGÉP>)');
    });
  });

  group('grouping precedence', () {
    test('empty group', () {
      expect(debugQuery('()'), '(<>)');
    });
    test('empty group with space', () {
      expect(debugQuery('(  )'), '(<>)');
    });
    test('single item group', () {
      expect(debugQuery('(a)'), '(<a>)');
    });
    test('single item group with space', () {
      expect(debugQuery('( a )'), '(<a>)');
    });
    test('grouping with two items implicit AND', () {
      expect(debugQuery('(a b)'), '((<a> <b>))');
    });
    test('grouping with two items explicit AND', () {
      expect(debugQuery('(a AND b)'), '((<a> <b>))');
    });
    test('grouping with multiple items', () {
      expect(debugQuery('(a | b) c (d | e)'),
          '(((<a> OR <b>)) <c> ((<d> OR <e>)))');
    });
    test('nested grouping', () {
      expect(debugQuery('(a OR b) OR c'), '(((<a> OR <b>)) OR <c>)');
      expect(debugQuery('(a OR b) c'), '(((<a> OR <b>)) <c>)');
      expect(debugQuery('((a OR b) c) | d'), '(((((<a> OR <b>)) <c>)) OR <d>)');
    });
    test('negative grouping', () {
      expect(debugQuery('-(a OR b) OR c'), '(-((<a> OR <b>)) OR <c>)');
      expect(debugQuery('(a OR -b) c'), '(((<a> OR -<b>)) <c>)');
      expect(debugQuery('-(-(a OR -b) -c) | -(d)'),
          '(-((-((<a> OR -<b>)) -<c>)) OR -(<d>))');
    });
  });

  group('phrase match', () {
    test('empty phrase', () {
      expect(debugQuery('""'), '""');
    });
    test('empty phrase with space', () {
      expect(debugQuery('"  "'), '""');
    });
    test('simple word phrase', () {
      expect(debugQuery('"a"'), '"<a>"');
    });
    test('single word phrase with space', () {
      expect(debugQuery('" a "'), '"<a>"');
    });
    test('two word phrase', () {
      expect(debugQuery('"a b"'), '"<a> <b>"');
    });
    test('three word phrase', () {
      expect(debugQuery('"a b c"'), '"<a> <b> <c>"');
    });
    test('three word phrase with AND', () {
      expect(debugQuery('"a AND b"'), '"<a> <AND> <b>"');
    });
    test('three word phrase with OR', () {
      expect(debugQuery('"a OR b"'), '"<a> <OR> <b>"');
    });
    test('negative phrase grouping', () {
      expect(debugQuery('-("a OR b") OR c'), '(-("<a> <OR> <b>") OR <c>)');
      expect(debugQuery('(a OR -"b") ("c")'), '(((<a> OR -"<b>")) ("<c>"))');
      expect(debugQuery('-(-"a OR -b" -c) | -"d"'),
          '(-((-"<a> <OR> <-b>" -<c>)) OR -"<d>")');
    });
    test('phrase with parenthesis', () {
      expect(debugQuery('"(a OR -b)" -("-c | []")'),
          '("<(a> <OR> <-b)>" -("<-c> <|> <[]>"))');
    });
  });
}
