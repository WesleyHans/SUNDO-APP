/// A device fix can only be presented as current for one minute. A small clock
/// allowance accepts native timestamps without accepting far-future fixes.
bool residentFixIsFresh(DateTime recordedAt, DateTime now,
    {Duration maximumAge = const Duration(seconds: 60),
    Duration clockAllowance = const Duration(seconds: 5)}) {
  final age = now.difference(recordedAt);
  return age >= -clockAllowance && age <= maximumAge;
}
