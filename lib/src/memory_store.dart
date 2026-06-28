import 'review_state.dart';
import 'review_store.dart';

/// In-memory [ReviewStore] for testing.
///
/// State is not persisted across instance lifetimes.
///
/// ```dart
/// final store = MemoryStore();
/// final manager = ReviewManager(
///   config: ReviewConfig(),
///   store: store,
/// );
/// ```
class MemoryStore implements ReviewStore {
  ReviewState _state = const ReviewState();

  /// The current in-memory state. Useful for test assertions.
  ReviewState get currentState => _state;

  @override
  Future<ReviewState> load() async => _state;

  @override
  Future<void> save(ReviewState state) async {
    _state = state;
  }

  @override
  Future<void> clear() async {
    _state = const ReviewState();
  }
}
