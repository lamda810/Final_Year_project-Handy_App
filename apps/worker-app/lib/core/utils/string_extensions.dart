extension StringInitial on String {
  /// First character, uppercased — or [fallback] if the string is empty.
  /// Safe to use for avatar initials, where a plain `substring(0, 1)` throws
  /// a RangeError on an empty name (e.g. an incomplete profile).
  String initial([String fallback = '?']) =>
      isNotEmpty ? this[0].toUpperCase() : fallback;
}
