import 'review_state.dart';

/// Abstract persistence layer for review state.
///
/// Implement this interface to provide custom storage backends.
/// The library ships with [SharedPreferencesStore] for production
/// and [MemoryStore] for testing.
abstract class ReviewStore {
  /// Loads the persisted review state.
  ///
  /// Returns [ReviewState.empty] if no state has been saved.
  Future<ReviewState> load();

  /// Saves the given review state.
  Future<void> save(ReviewState state);

  /// Clears all persisted state, resetting to [ReviewState.empty].
  Future<void> clear();
}
