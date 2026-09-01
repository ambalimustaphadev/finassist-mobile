/// Determines the time-of-day greeting label (e.g. "Good morning") for a
/// given local time, so the dashboard greeting always matches the device
/// clock instead of being hardcoded.
abstract final class GreetingService {
  static String greetingFor(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
