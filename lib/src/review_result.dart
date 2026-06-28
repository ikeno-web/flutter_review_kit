/// Outcome of a review request attempt.
enum ReviewResult {
  /// The review dialog was requested successfully.
  ///
  /// Note: This does not guarantee the dialog was shown to the user.
  /// Platforms may silently suppress the dialog based on their own rules.
  shown,

  /// Conditions for showing a review prompt are not yet met.
  notReady,

  /// Within the cooldown period after a previous prompt.
  cooldown,

  /// Maximum prompts for the current app version already reached.
  alreadyPromptedThisVersion,

  /// A platform error occurred while requesting the review dialog.
  error,
}
