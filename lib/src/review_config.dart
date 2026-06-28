/// Immutable configuration for review prompting behavior.
///
/// All thresholds must be met before a review prompt is considered ready.
///
/// ```dart
/// const config = ReviewConfig(
///   minLaunches: 5,
///   minDaysInstalled: 7,
///   minEvents: 3,
///   cooldownDays: 90,
/// );
/// ```
class ReviewConfig {
  /// Minimum number of app launches before prompting.
  final int minLaunches;

  /// Minimum days since first tracked launch before prompting.
  final int minDaysInstalled;

  /// Minimum number of custom events before prompting.
  final int minEvents;

  /// Days to wait after a prompt before allowing another.
  final int cooldownDays;

  /// Maximum number of prompts allowed per app version.
  final int maxPromptsPerVersion;

  /// Event names that qualify as "happy moments."
  ///
  /// When [ReviewManager.trackHappyMoment] is called with a name
  /// in this list and conditions are met, a review prompt is triggered.
  final List<String> happyMoments;

  /// When true, logs condition checks to the console and bypasses cooldown.
  final bool debug;

  /// Creates a review configuration with sensible defaults.
  const ReviewConfig({
    this.minLaunches = 5,
    this.minDaysInstalled = 7,
    this.minEvents = 3,
    this.cooldownDays = 90,
    this.maxPromptsPerVersion = 1,
    this.happyMoments = const [],
    this.debug = false,
  });

  /// Creates a copy with the given fields replaced.
  ReviewConfig copyWith({
    int? minLaunches,
    int? minDaysInstalled,
    int? minEvents,
    int? cooldownDays,
    int? maxPromptsPerVersion,
    List<String>? happyMoments,
    bool? debug,
  }) {
    return ReviewConfig(
      minLaunches: minLaunches ?? this.minLaunches,
      minDaysInstalled: minDaysInstalled ?? this.minDaysInstalled,
      minEvents: minEvents ?? this.minEvents,
      cooldownDays: cooldownDays ?? this.cooldownDays,
      maxPromptsPerVersion: maxPromptsPerVersion ?? this.maxPromptsPerVersion,
      happyMoments: happyMoments ?? this.happyMoments,
      debug: debug ?? this.debug,
    );
  }

  @override
  String toString() => 'ReviewConfig('
      'minLaunches: $minLaunches, '
      'minDaysInstalled: $minDaysInstalled, '
      'minEvents: $minEvents, '
      'cooldownDays: $cooldownDays, '
      'maxPromptsPerVersion: $maxPromptsPerVersion, '
      'debug: $debug)';
}
