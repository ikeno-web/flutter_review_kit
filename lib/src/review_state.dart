/// Immutable snapshot of review tracking state.
///
/// Tracks launch counts, event counts, prompt history, and dates
/// needed to evaluate review conditions.
class ReviewState {
  /// Number of times [ReviewManager.trackLaunch] has been called.
  final int launchCount;

  /// Number of times [ReviewManager.trackEvent] has been called.
  final int eventCount;

  /// Timestamp of the first tracked launch, or null if never launched.
  final DateTime? firstLaunchDate;

  /// Timestamp of the last review prompt, or null if never prompted.
  final DateTime? lastPromptDate;

  /// Total number of times the review dialog has been prompted.
  final int promptCount;

  /// App version string at the time of the last prompt.
  final String? lastPromptVersion;

  /// Whether the user has indicated they reviewed the app.
  ///
  /// Note: Platforms do not reliably report whether a review was submitted.
  /// This is set via [ReviewManager] when the prompt completes without error.
  final bool hasReviewed;

  /// Creates a review state snapshot.
  const ReviewState({
    this.launchCount = 0,
    this.eventCount = 0,
    this.firstLaunchDate,
    this.lastPromptDate,
    this.promptCount = 0,
    this.lastPromptVersion,
    this.hasReviewed = false,
  });

  /// The initial empty state.
  static const empty = ReviewState();

  /// Creates a copy with the given fields replaced.
  ReviewState copyWith({
    int? launchCount,
    int? eventCount,
    DateTime? firstLaunchDate,
    DateTime? lastPromptDate,
    int? promptCount,
    String? lastPromptVersion,
    bool? hasReviewed,
  }) {
    return ReviewState(
      launchCount: launchCount ?? this.launchCount,
      eventCount: eventCount ?? this.eventCount,
      firstLaunchDate: firstLaunchDate ?? this.firstLaunchDate,
      lastPromptDate: lastPromptDate ?? this.lastPromptDate,
      promptCount: promptCount ?? this.promptCount,
      lastPromptVersion: lastPromptVersion ?? this.lastPromptVersion,
      hasReviewed: hasReviewed ?? this.hasReviewed,
    );
  }

  /// Converts this state to a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'launchCount': launchCount,
      'eventCount': eventCount,
      'firstLaunchDate': firstLaunchDate?.toIso8601String(),
      'lastPromptDate': lastPromptDate?.toIso8601String(),
      'promptCount': promptCount,
      'lastPromptVersion': lastPromptVersion,
      'hasReviewed': hasReviewed,
    };
  }

  /// Creates a state from a serialized map.
  factory ReviewState.fromMap(Map<String, dynamic> map) {
    return ReviewState(
      launchCount: map['launchCount'] as int? ?? 0,
      eventCount: map['eventCount'] as int? ?? 0,
      firstLaunchDate: map['firstLaunchDate'] != null
          ? DateTime.parse(map['firstLaunchDate'] as String)
          : null,
      lastPromptDate: map['lastPromptDate'] != null
          ? DateTime.parse(map['lastPromptDate'] as String)
          : null,
      promptCount: map['promptCount'] as int? ?? 0,
      lastPromptVersion: map['lastPromptVersion'] as String?,
      hasReviewed: map['hasReviewed'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewState &&
        other.launchCount == launchCount &&
        other.eventCount == eventCount &&
        other.firstLaunchDate == firstLaunchDate &&
        other.lastPromptDate == lastPromptDate &&
        other.promptCount == promptCount &&
        other.lastPromptVersion == lastPromptVersion &&
        other.hasReviewed == hasReviewed;
  }

  @override
  int get hashCode => Object.hash(
        launchCount,
        eventCount,
        firstLaunchDate,
        lastPromptDate,
        promptCount,
        lastPromptVersion,
        hasReviewed,
      );

  @override
  String toString() => 'ReviewState('
      'launchCount: $launchCount, '
      'eventCount: $eventCount, '
      'firstLaunchDate: $firstLaunchDate, '
      'lastPromptDate: $lastPromptDate, '
      'promptCount: $promptCount, '
      'lastPromptVersion: $lastPromptVersion, '
      'hasReviewed: $hasReviewed)';
}
