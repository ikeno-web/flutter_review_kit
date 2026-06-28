import 'package:shared_preferences/shared_preferences.dart';

import 'review_state.dart';
import 'review_store.dart';

/// Production [ReviewStore] backed by SharedPreferences.
///
/// All keys are prefixed with `flutter_review_kit_` to avoid collisions.
class SharedPreferencesStore implements ReviewStore {
  static const _prefix = 'flutter_review_kit_';
  static const _keyLaunchCount = '${_prefix}launch_count';
  static const _keyEventCount = '${_prefix}event_count';
  static const _keyFirstLaunch = '${_prefix}first_launch';
  static const _keyLastPrompt = '${_prefix}last_prompt';
  static const _keyPromptCount = '${_prefix}prompt_count';
  static const _keyLastPromptVersion = '${_prefix}last_prompt_version';
  static const _keyHasReviewed = '${_prefix}has_reviewed';

  @override
  Future<ReviewState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final firstLaunchStr = prefs.getString(_keyFirstLaunch);
    final lastPromptStr = prefs.getString(_keyLastPrompt);

    return ReviewState(
      launchCount: prefs.getInt(_keyLaunchCount) ?? 0,
      eventCount: prefs.getInt(_keyEventCount) ?? 0,
      firstLaunchDate:
          firstLaunchStr != null ? DateTime.parse(firstLaunchStr) : null,
      lastPromptDate:
          lastPromptStr != null ? DateTime.parse(lastPromptStr) : null,
      promptCount: prefs.getInt(_keyPromptCount) ?? 0,
      lastPromptVersion: prefs.getString(_keyLastPromptVersion),
      hasReviewed: prefs.getBool(_keyHasReviewed) ?? false,
    );
  }

  @override
  Future<void> save(ReviewState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLaunchCount, state.launchCount);
    await prefs.setInt(_keyEventCount, state.eventCount);

    if (state.firstLaunchDate != null) {
      await prefs.setString(
          _keyFirstLaunch, state.firstLaunchDate!.toIso8601String());
    } else {
      await prefs.remove(_keyFirstLaunch);
    }
    if (state.lastPromptDate != null) {
      await prefs.setString(
          _keyLastPrompt, state.lastPromptDate!.toIso8601String());
    } else {
      await prefs.remove(_keyLastPrompt);
    }

    await prefs.setInt(_keyPromptCount, state.promptCount);

    if (state.lastPromptVersion != null) {
      await prefs.setString(_keyLastPromptVersion, state.lastPromptVersion!);
    } else {
      await prefs.remove(_keyLastPromptVersion);
    }

    await prefs.setBool(_keyHasReviewed, state.hasReviewed);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLaunchCount);
    await prefs.remove(_keyEventCount);
    await prefs.remove(_keyFirstLaunch);
    await prefs.remove(_keyLastPrompt);
    await prefs.remove(_keyPromptCount);
    await prefs.remove(_keyLastPromptVersion);
    await prefs.remove(_keyHasReviewed);
  }
}
