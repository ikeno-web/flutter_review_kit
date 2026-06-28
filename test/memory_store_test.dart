import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_review_kit/flutter_review_kit.dart';

void main() {
  group('MemoryStore', () {
    late MemoryStore store;

    setUp(() {
      store = MemoryStore();
    });

    test('load returns empty state initially', () async {
      final state = await store.load();
      expect(state, const ReviewState());
    });

    test('save persists state in memory', () async {
      const state = ReviewState(launchCount: 5, eventCount: 3);
      await store.save(state);
      final loaded = await store.load();
      expect(loaded, state);
    });

    test('save overwrites previous state', () async {
      await store.save(const ReviewState(launchCount: 3));
      await store.save(const ReviewState(launchCount: 7));
      final loaded = await store.load();
      expect(loaded.launchCount, 7);
    });

    test('clear resets to empty state', () async {
      await store.save(const ReviewState(launchCount: 10, eventCount: 5));
      await store.clear();
      final loaded = await store.load();
      expect(loaded, const ReviewState());
    });

    test('currentState reflects latest save', () async {
      expect(store.currentState, const ReviewState());
      const state = ReviewState(launchCount: 42);
      await store.save(state);
      expect(store.currentState, state);
    });
  });
}
