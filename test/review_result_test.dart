import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_review_kit/flutter_review_kit.dart';

void main() {
  group('ReviewResult', () {
    test('has all expected values', () {
      expect(ReviewResult.values, hasLength(5));
      expect(ReviewResult.values, contains(ReviewResult.shown));
      expect(ReviewResult.values, contains(ReviewResult.notReady));
      expect(ReviewResult.values, contains(ReviewResult.cooldown));
      expect(
          ReviewResult.values, contains(ReviewResult.alreadyPromptedThisVersion));
      expect(ReviewResult.values, contains(ReviewResult.error));
    });
  });
}
