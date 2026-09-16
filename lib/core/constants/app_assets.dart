/// Centralized asset paths for FinAssist branding, so the official logo
/// is referenced from exactly one place rather than as a raw string
/// literal scattered across every screen that needs it.
abstract final class AppAssets {
  /// The one official FinAssist logo/brand mark. Every in-app usage of
  /// the FinAssist logo — splash, onboarding, auth, the chat drawer,
  /// About FinAssist, the main header — must use this asset via
  /// [FinAssistLogo] rather than a redrawn/recolored/alternate version.
  static const String finAssistLogo = 'assets/splash/splash_logo.png';
}
