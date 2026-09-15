import '../data/models/subscription.dart';

/// Known-brand logo assets, keyed by a normalized brand name. Filenames are
/// used exactly as they exist on disk (including a few with stray trailing
/// spaces) — the assets must not be renamed.
const _brandAssets = <String, String>{
  'netflix': 'assets/brands/Netflix.png',
  'spotify': 'assets/brands/Spotify.png',
  'dstv': 'assets/brands/dstv.png',
  'gotv': 'assets/brands/gotv.png',
  'youtube': 'assets/brands/Youtube .png',
  'prime video': 'assets/brands/Prime_video.png',
  'amazon prime': 'assets/brands/Prime_video.png',
  'apple music': 'assets/brands/Apple_Music.png',
  'chatgpt': 'assets/brands/ChatGPT.png',
  'openai': 'assets/brands/ChatGPT.png',
  'canva': 'assets/brands/Canva.png',
  'icloud': 'assets/brands/iCloud.png',
};

/// Category fallback icons, keyed by [SubscriptionCategory.apiValue].
const _categoryAssets = <String, String>{
  'entertainment': 'assets/subscription_categories/entertainment .png',
  'software': 'assets/subscription_categories/software.png',
  'cloud_storage': 'assets/subscription_categories/cloud_storage.png',
  'education': 'assets/subscription_categories/education.png',
  'fitness': 'assets/subscription_categories/fitness.png',
  'news_media': 'assets/subscription_categories/news_media.png',
  'productivity': 'assets/subscription_categories/productivity.png',
  'shopping': 'assets/subscription_categories/shopping .png',
  'gaming': 'assets/subscription_categories/gaming.png',
  'other': 'assets/subscription_categories/other.png',
};

const _otherAsset = 'assets/subscription_categories/other.png';

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[+._-]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Resolves a known brand's local logo asset from a subscription [name],
/// tolerant of normal variations ("Netflix", "Netflix Premium", "Netflix
/// Nigeria" all resolve to the same asset). Returns `null` if the name
/// doesn't match any known brand.
String? resolveBrandAsset(String name) {
  final normalized = _normalize(name);
  if (normalized.isEmpty) return null;
  for (final entry in _brandAssets.entries) {
    if (normalized.contains(entry.key)) return entry.value;
  }
  return null;
}

/// Resolves the icon asset to display for a subscription: a known brand's
/// logo first, then the [category]'s fallback icon, then a generic "other"
/// icon — this always returns a real, bundled asset, so a subscription can
/// never render a broken image.
String resolveIconAsset({required String name, SubscriptionCategory? category}) {
  final brandAsset = resolveBrandAsset(name);
  if (brandAsset != null) return brandAsset;
  if (category != null) {
    return _categoryAssets[category.apiValue] ?? _otherAsset;
  }
  return _otherAsset;
}
