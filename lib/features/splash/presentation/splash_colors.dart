import 'package:flutter/material.dart';

/// Splash is a deliberately fixed-dark, pre-auth brand animation — it does
/// not follow the user's Light/Dark preference (not even loaded yet at this
/// point in the app lifecycle) and must keep its exact original look. These
/// are literal, non-theme-reactive values (the original palette this
/// composition was designed against), used directly instead of
/// `context.colors` so every usage here stays `const`-constructible.
const kSplashDarkBg = Color(0xFF0E1A15);
const kSplashAccent = Color(0xFF55E39A);
const kSplashAccentStrong = Color(0xFF2EDB87);
const kSplashAccentSoft = Color(0xFF8AF5B8);
const kSplashCtaGradient = [Color(0xFF2EDB87), Color(0xFF55E9C7)];
