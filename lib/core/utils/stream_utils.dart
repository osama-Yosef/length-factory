import 'dart:async';

/// Emits [combiner] of the latest values once all three streams have
/// emitted at least once, then on every subsequent event.
Stream<R> combineLatest3<A, B, C, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  R Function(A a, B b, C c) combiner,
) {
  late StreamController<R> controller;
  final subs = <StreamSubscription<dynamic>>[];
  A? va;
  B? vb;
  C? vc;
  var hasA = false, hasB = false, hasC = false;

  void emit() {
    if (hasA && hasB && hasC) controller.add(combiner(va as A, vb as B, vc as C));
  }

  controller = StreamController<R>(
    onListen: () {
      subs
        ..add(a.listen((v) {
          va = v;
          hasA = true;
          emit();
        }, onError: controller.addError))
        ..add(b.listen((v) {
          vb = v;
          hasB = true;
          emit();
        }, onError: controller.addError))
        ..add(c.listen((v) {
          vc = v;
          hasC = true;
          emit();
        }, onError: controller.addError));
    },
    onCancel: () async {
      for (final s in subs) {
        await s.cancel();
      }
    },
  );
  return controller.stream;
}

extension SwitchMapExtension<T> on Stream<T> {
  /// Maps each event to an inner stream, cancelling the previous inner
  /// stream whenever a new outer event arrives (like RxDart's switchMap).
  ///
  /// Needed for "auth state → user profile document" where the profile
  /// listener must be cancelled as soon as the user signs out.
  Stream<R> switchMap<R>(Stream<R> Function(T event) mapper) {
    StreamSubscription<T>? outer;
    StreamSubscription<R>? inner;
    late StreamController<R> controller;

    controller = StreamController<R>(
      onListen: () {
        outer = listen(
          (event) {
            inner?.cancel();
            inner = mapper(event).listen(
              controller.add,
              onError: controller.addError,
            );
          },
          onError: controller.addError,
          onDone: () async {
            await inner?.cancel();
            await controller.close();
          },
        );
      },
      onPause: () {
        outer?.pause();
        inner?.pause();
      },
      onResume: () {
        outer?.resume();
        inner?.resume();
      },
      onCancel: () async {
        await inner?.cancel();
        await outer?.cancel();
      },
    );
    return controller.stream;
  }
}
