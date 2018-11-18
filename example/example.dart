import 'package:query/query.dart';

main() {
  final q = parseQuery('some text OR field:another');
  // prints "(some (text OR field:another))"
  print(q);
}
