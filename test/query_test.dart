import 'package:query/query.dart';
import 'package:test/test.dart';
import 'package:test/test.dart' as t;

extension<T extends Query> on T {
  R expect<R extends Query>(String matcher, int start, int end) {
    t.expect(runtimeType, R);
    t.expect(toString(debug: true), matcher);
    t.expect(position.start, start);
    t.expect(position.end, end);
    return cast<R>();
  }
}

void main() {
  group('Base expressions', () {
    test('1 string', () {
      parseQuery('abc').expect<TextQuery>('<abc>', 0, 3);
      parseQuery('"abc"')
          .expect<PhraseQuery>('"<abc>"', 0, 5)
          .children
          .first
          .expect<TextQuery>('<abc>', 1, 4);
      parseQuery('abc*').expect<TextQuery>('<abc*>', 0, 4);
    });

    test('2 strings', () {
      parseQuery('abc def').expect<AndQuery>('(<abc> <def>)', 0, 7)
        ..children[0].expect<TextQuery>('<abc>', 0, 3)
        ..children[1].expect<TextQuery>('<def>', 4, 7);
      parseQuery('"abc 1" def').expect<AndQuery>('("<abc> <1>" <def>)', 0, 11)
        ..children[0].expect<PhraseQuery>('"<abc> <1>"', 0, 7)
        ..children[1].expect<TextQuery>('<def>', 8, 11);
      parseQuery('abc "def 2"').expect<AndQuery>('(<abc> "<def> <2>")', 0, 11);
      parseQuery('"abc" "def"').expect<AndQuery>('("<abc>" "<def>")', 0, 11);
      parseQuery('"abc 1" "def 2"')
          .expect<AndQuery>('("<abc> <1>" "<def> <2>")', 0, 15);
    });

    test('explicit AND', () {
      parseQuery('a AND b c').expect<AndQuery>('(<a> <b> <c>)', 0, 9)
        ..children[0].expect<TextQuery>('<a>', 0, 1)
        ..children[1].expect<TextQuery>('<b>', 6, 7)
        ..children[2].expect<TextQuery>('<c>', 8, 9);
    });

    test('negative word', () {
      parseQuery('-abc')
          .expect<NotQuery>('-<abc>', 0, 4)
          .child
          .expect<TextQuery>('<abc>', 1, 4);
      parseQuery('-"abc"')
          .expect<NotQuery>('-"<abc>"', 0, 6)
          .child
          .expect<PhraseQuery>('"<abc>"', 1, 6);
      parseQuery('-"abc 1"')
          .expect<NotQuery>('-"<abc> <1>"', 0, 8)
          .child
          .expect<PhraseQuery>('"<abc> <1>"', 1, 8)
          .children
          .first
          .expect<TextQuery>('<abc>', 2, 5);
      parseQuery('NOT abc')
          .expect<NotQuery>('-<abc>', 0, 7)
          .child
          .expect<TextQuery>('<abc>', 4, 7);
      parseQuery('NOT "abc"').expect<NotQuery>('-"<abc>"', 0, 9);
      parseQuery('NOT "abc 1"').expect<NotQuery>('-"<abc> <1>"', 0, 11);
    });

    test('scoped', () {
      parseQuery('a:abc').expect<FieldScopeQuery>('a:<abc>', 0, 5)
        ..field.expect<TextQuery>('<a>', 0, 1)
        ..child.expect<TextQuery>('<abc>', 2, 5);
      parseQuery('a:"abc"').expect<FieldScopeQuery>('a:"<abc>"', 0, 7);
      parseQuery('a:"abc 1"').expect<FieldScopeQuery>('a:"<abc> <1>"', 0, 9);
      parseQuery('a:-"abc 1"').expect<FieldScopeQuery>('a:-"<abc> <1>"', 0, 10);
      parseQuery('NOT field:abc')
          .expect<NotQuery>('-field:<abc>', 0, 13)
          .child
          .expect<FieldScopeQuery>('field:<abc>', 4, 13)
        ..field.expect<TextQuery>('<field>', 4, 9)
        ..child.expect<TextQuery>('<abc>', 10, 13);
      parseQuery('a:').expect<FieldScopeQuery>('a:<>', 0, 2);
      parseQuery('a: AND a').expect<AndQuery>('(a:<> <a>)', 0, 8);
    });

    test('special scoped', () {
      parseQuery('a*:abc').expect<FieldScopeQuery>('a*:<abc>', 0, 6);
      parseQuery('a%:"abc"').expect<FieldScopeQuery>('a%:"<abc>"', 0, 8);
    });

    test('compare', () {
      parseQuery('year < 2000').expect<FieldCompareQuery>('<year<2000>', 0, 11)
        ..field.expect<TextQuery>('<year>', 0, 4)
        ..operator.expect<TextQuery>('<<>', 5, 6)
        ..text.expect<TextQuery>('<2000>', 7, 11);
      parseQuery('field >= "test case"')
          .expect<FieldCompareQuery>('<field>="test case">', 0, 20)
        ..field.expect<TextQuery>('<field>', 0, 5)
        ..operator.expect<TextQuery>('<>=>', 6, 8)
        ..text.expect<PhraseQuery>('"<test> <case>"', 9, 20);
      parseQuery('year = ').expect<FieldCompareQuery>('<year=>', 0, 7);
    });

    test('range', () {
      parseQuery('[1 TO 10]').expect<RangeQuery>('<[<1> TO <10>]>', 0, 9)
        ..start.expect<TextQuery>('<1>', 1, 2)
        ..end.expect<TextQuery>('<10>', 6, 8);
      parseQuery(']1 TO 10[').expect<RangeQuery>('<]<1> TO <10>[>', 0, 9)
        ..start.expect<TextQuery>('<1>', 1, 2)
        ..end.expect<TextQuery>('<10>', 6, 8);
      parseQuery(']"1 a" TO "10 b"[')
          .expect<RangeQuery>('<]"<1> <a>" TO "<10> <b>"[>', 0, 17)
        ..start.expect<PhraseQuery>('"<1> <a>"', 1, 6)
        ..end.expect<PhraseQuery>('"<10> <b>"', 10, 16);
    });
  });

  group('or', () {
    test('2 items', () {
      parseQuery('a OR b').expect<OrQuery>('(<a> OR <b>)', 0, 6)
        ..children.first.expect<TextQuery>('<a>', 0, 1)
        ..children.last.expect<TextQuery>('<b>', 5, 6);
    });

    test('2 items pipe', () {
      parseQuery('a | b').expect<OrQuery>('(<a> OR <b>)', 0, 5)
        ..children.first.expect<TextQuery>('<a>', 0, 1)
        ..children.last.expect<TextQuery>('<b>', 4, 5);
    });

    test('3 items', () {
      parseQuery('a OR b OR c').expect<OrQuery>('(<a> OR <b> OR <c>)', 0, 11)
        ..children[0].expect<TextQuery>('<a>', 0, 1)
        ..children[1].expect<TextQuery>('<b>', 5, 6)
        ..children[2].expect<TextQuery>('<c>', 10, 11);
    });

    test('3 items pipe', () {
      parseQuery('a | b | c').expect<OrQuery>('(<a> OR <b> OR <c>)', 0, 9)
        ..children[0].expect<TextQuery>('<a>', 0, 1)
        ..children[1].expect<TextQuery>('<b>', 4, 5)
        ..children[2].expect<TextQuery>('<c>', 8, 9);
    });

    test('3 items pipe mixed', () {
      parseQuery('a OR b | c').expect<OrQuery>('(<a> OR <b> OR <c>)', 0, 10)
        ..children[0].expect<TextQuery>('<a>', 0, 1)
        ..children[1].expect<TextQuery>('<b>', 5, 6)
        ..children[2].expect<TextQuery>('<c>', 9, 10);
      parseQuery('a | b OR c').expect<OrQuery>('(<a> OR <b> OR <c>)', 0, 10)
        ..children[0].expect<TextQuery>('<a>', 0, 1)
        ..children[1].expect<TextQuery>('<b>', 4, 5)
        ..children[2].expect<TextQuery>('<c>', 9, 10);
    });

    test('precedence of implicit AND, explicit OR', () {
      parseQuery('a b OR c').expect<AndQuery>('(<a> (<b> OR <c>))', 0, 8);
      parseQuery('a OR b c').expect<OrQuery>('(<a> OR (<b> <c>))', 0, 8);
      parseQuery('a OR b c OR d')
          .expect<OrQuery>('(<a> OR (<b> (<c> OR <d>)))', 0, 13);
    });

    test('precedence of implicit AND, explicit OR pipe', () {
      parseQuery('a b | c').expect<AndQuery>('(<a> (<b> OR <c>))', 0, 7);
      parseQuery('a | b c').expect<OrQuery>('(<a> OR (<b> <c>))', 0, 7);
      parseQuery('a | b c | d')
          .expect<OrQuery>('(<a> OR (<b> (<c> OR <d>)))', 0, 11);
    });
  });

  group('complex cases', () {
    test('#1', () {
      parseQuery('a:-v1 b:(beta OR moon < Deimos OR [a TO e])')
          .expect<AndQuery>(
              '(a:-<v1> b:((<beta> OR <moon<Deimos> OR <[<a> TO <e>]>)))',
              0,
              43);
    });

    test('#2', () {
      parseQuery('a = 2000 b > 2000 c')
          .expect<AndQuery>('(<a=2000> <b>2000> <c>)', 0, 19);
    });

    test('#3', () {
      parseQuery('(f:abc)').expect<GroupQuery>('(f:<abc>)', 0, 7);
    });
  });

  group('unicode chars', () {
    test('hungarian', () {
      parseQuery('árvíztűrő TÜKÖRFÚRÓGÉP')
          .expect<AndQuery>('(<árvíztűrő> <TÜKÖRFÚRÓGÉP>)', 0, 22);
    });
  });

  group('grouping precedence', () {
    test('empty group', () {
      parseQuery('()').expect<GroupQuery>('(<>)', 0, 2);
    });
    test('empty group with space', () {
      parseQuery('(  )').expect<GroupQuery>('(<>)', 0, 4);
    });
    test('single item group', () {
      parseQuery('(a)').expect<GroupQuery>('(<a>)', 0, 3);
    });
    test('single item group with space', () {
      parseQuery('( a )').expect<GroupQuery>('(<a>)', 0, 5);
    });
    test('grouping with two items implicit AND', () {
      parseQuery('(a b)').expect<GroupQuery>('((<a> <b>))', 0, 5);
    });
    test('grouping with two items explicit AND', () {
      parseQuery('(a AND b)').expect<GroupQuery>('((<a> <b>))', 0, 9);
    });
    test('grouping with multiple items', () {
      parseQuery('(a | b) c (d | e)')
          .expect<AndQuery>('(((<a> OR <b>)) <c> ((<d> OR <e>)))', 0, 17);
    });
    test('nested grouping', () {
      parseQuery('(a OR b) OR c')
          .expect<OrQuery>('(((<a> OR <b>)) OR <c>)', 0, 13);
      parseQuery('(a OR b) c').expect<AndQuery>('(((<a> OR <b>)) <c>)', 0, 10);
      parseQuery('((a OR b) c) | d')
          .expect<OrQuery>('(((((<a> OR <b>)) <c>)) OR <d>)', 0, 16);
    });
    test('negative grouping', () {
      parseQuery('-(a OR b) OR c')
          .expect<OrQuery>('(-((<a> OR <b>)) OR <c>)', 0, 14);
      parseQuery('(a OR -b) c')
          .expect<AndQuery>('(((<a> OR -<b>)) <c>)', 0, 11);
      parseQuery('-(-(a OR -b) -c) | -(d)')
          .expect<OrQuery>('(-((-((<a> OR -<b>)) -<c>)) OR -(<d>))', 0, 23);
    });
    test('scoped grouping', () {
      parseQuery('(field:abc)').expect<GroupQuery>('(field:<abc>)', 0, 11);
      parseQuery('(field:abc AND field:def)')
          .expect<GroupQuery>('((field:<abc> field:<def>))', 0, 25);
      parseQuery('(field:abc OR field:def)')
          .expect<GroupQuery>('((field:<abc> OR field:<def>))', 0, 24);
    });
  });

  group('phrase match', () {
    test('empty phrase', () {
      parseQuery('""').expect<PhraseQuery>('""', 0, 2);
    });
    test('empty phrase with space', () {
      parseQuery('"  "').expect<PhraseQuery>('""', 0, 4);
    });
    test('simple word phrase', () {
      parseQuery('"a"').expect<PhraseQuery>('"<a>"', 0, 3);
    });
    test('single word phrase with space', () {
      parseQuery('" a "').expect<PhraseQuery>('"<a>"', 0, 5);
    });
    test('two word phrase', () {
      parseQuery('"a b"').expect<PhraseQuery>('"<a> <b>"', 0, 5);
    });
    test('three word phrase', () {
      parseQuery('"a b c"').expect<PhraseQuery>('"<a> <b> <c>"', 0, 7);
    });
    test('three word phrase with AND', () {
      parseQuery('"a AND b"').expect<PhraseQuery>('"<a> <AND> <b>"', 0, 9);
    });
    test('three word phrase with OR', () {
      parseQuery('"a OR b"').expect<PhraseQuery>('"<a> <OR> <b>"', 0, 8);
    });
    test('negative phrase grouping', () {
      parseQuery('-("a OR b") OR c')
          .expect<OrQuery>('(-("<a> <OR> <b>") OR <c>)', 0, 16);
      parseQuery('(a OR -"b") ("c")')
          .expect<AndQuery>('(((<a> OR -"<b>")) ("<c>"))', 0, 17);
      parseQuery('-(-"a OR -b" -c) | -"d"')
          .expect<OrQuery>('(-((-"<a> <OR> <-b>" -<c>)) OR -"<d>")', 0, 23);
    });
    test('phrase with parenthesis', () {
      parseQuery('"(a OR -b)" -("-c | []")')
          .expect<AndQuery>('("<(a> <OR> <-b)>" -("<-c> <|> <[]>"))', 0, 24);
    });
  });
}
