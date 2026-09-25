import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:length_factory/core/utils/stream_utils.dart';
import 'package:length_factory/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('bad'), isNotNull);
      expect(Validators.email('a@b.com'), isNull);
    });

    test('password', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('123'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });

    test('phone requires 11 digits', () {
      expect(Validators.phone('0101234567'), isNotNull);
      expect(Validators.phone('0101234567a'), isNotNull);
      expect(Validators.phone('01012345678'), isNull);
    });

    test('positiveNumber / nonNegativeInt', () {
      expect(Validators.positiveNumber('0'), isNotNull);
      expect(Validators.positiveNumber('x'), isNotNull);
      expect(Validators.positiveNumber('12.5'), isNull);
      expect(Validators.nonNegativeInt('-1'), isNotNull);
      expect(Validators.nonNegativeInt('1.5'), isNotNull);
      expect(Validators.nonNegativeInt('0'), isNull);
    });
  });

  group('switchMap', () {
    test('cancels the previous inner stream on a new outer event', () async {
      final outer = StreamController<int>();
      final inners = <int, StreamController<String>>{};
      final results = <String>[];

      final sub = outer.stream.switchMap((i) {
        final c = StreamController<String>();
        inners[i] = c;
        return c.stream;
      }).listen(results.add);

      outer.add(1);
      await pumpEventQueue();
      inners[1]!.add('a1');
      outer.add(2);
      await pumpEventQueue();
      inners[1]!.add('a2'); // must be ignored — inner 1 was cancelled
      inners[2]!.add('b1');
      await pumpEventQueue();

      expect(results, ['a1', 'b1']);
      await sub.cancel();
      await outer.close();
    });
  });

  group('combineLatest3', () {
    test('emits only after all three emitted, then on every change', () async {
      final a = StreamController<int>();
      final b = StreamController<int>();
      final c = StreamController<int>();
      final results = <int>[];

      final sub = combineLatest3<int, int, int, int>(a.stream, b.stream, c.stream, (x, y, z) => x + y + z)
          .listen(results.add);

      a.add(1);
      b.add(10);
      await pumpEventQueue();
      expect(results, isEmpty);

      c.add(100);
      await pumpEventQueue();
      a.add(2);
      await pumpEventQueue();

      expect(results, [111, 112]);
      await sub.cancel();
    });
  });
}
