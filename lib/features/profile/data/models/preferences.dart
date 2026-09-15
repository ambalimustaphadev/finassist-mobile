/// Mirrors `GET/PATCH /api/preferences`'s response shape — Flutter only
/// reads/writes the fields still meaningful for FinAssist's AI-first
/// product; any other key the backend returns is simply ignored.
///
/// [financialExperience], [interests] and [responseStyle] are set once,
/// together, by the personalization flow's completion step (see
/// `PersonalizationController.completeSetup`) — an existing user who
/// hasn't been through it has all three as `null`, which is valid, not an
/// error. [proactiveSuggestions] always has a real value (it defaults to
/// `true` server-side too), so it's never nullable.
class Preferences {
  const Preferences({
    required this.currency,
    required this.language,
    required this.notificationsEnabled,
    required this.documentNotifications,
    required this.updatedAt,
    this.proactiveSuggestions = true,
    this.financialExperience,
    this.interests,
    this.responseStyle,
  });

  final String currency;
  final String language;
  final bool notificationsEnabled;
  final bool documentNotifications;

  /// `beginner` / `some_knowledge` / `moderate` / `advanced`.
  final String? financialExperience;

  /// Conversation-topic slugs, e.g. `general_money_questions` — see
  /// `PersonalizationController`'s `_interestToBackend` for the full list.
  final List<String>? interests;

  /// `simple` / `balanced` / `detailed`.
  final String? responseStyle;
  final bool proactiveSuggestions;
  final DateTime updatedAt;

  factory Preferences.fromJson(Map<String, dynamic> json) {
    return Preferences(
      currency: json['currency'] as String? ?? 'NGN',
      language: json['language'] as String? ?? 'en',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      documentNotifications: json['document_notifications'] as bool? ?? true,
      financialExperience: json['financial_experience'] as String?,
      interests: (json['interests'] as List?)
          ?.map((interest) => interest as String)
          .toList(),
      responseStyle: json['response_style'] as String?,
      proactiveSuggestions: json['proactive_suggestions'] as bool? ?? true,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class CurrencyOption {
  const CurrencyOption(this.code, this.symbol, this.label);
  final String code;
  final String symbol;
  final String label;
}

/// Exactly the 26 codes `utils.CURRENCIES` accepts on the backend — every
/// option here is guaranteed to PATCH successfully.
const supportedCurrencies = [
  CurrencyOption('NGN', '₦', 'Nigerian Naira'),
  CurrencyOption('USD', '\$', 'US Dollar'),
  CurrencyOption('EUR', '€', 'Euro'),
  CurrencyOption('GBP', '£', 'British Pound'),
  CurrencyOption('CAD', 'C\$', 'Canadian Dollar'),
  CurrencyOption('AUD', 'A\$', 'Australian Dollar'),
  CurrencyOption('ZAR', 'R', 'South African Rand'),
  CurrencyOption('GHS', 'GH₵', 'Ghanaian Cedi'),
  CurrencyOption('KES', 'KSh', 'Kenyan Shilling'),
  CurrencyOption('INR', '₹', 'Indian Rupee'),
  CurrencyOption('JPY', '¥', 'Japanese Yen'),
  CurrencyOption('CNY', '¥', 'Chinese Yuan'),
  CurrencyOption('CHF', 'CHF', 'Swiss Franc'),
  CurrencyOption('SEK', 'kr', 'Swedish Krona'),
  CurrencyOption('NOK', 'kr', 'Norwegian Krone'),
  CurrencyOption('DKK', 'kr', 'Danish Krone'),
  CurrencyOption('AED', 'AED', 'UAE Dirham'),
  CurrencyOption('SAR', 'SAR', 'Saudi Riyal'),
  CurrencyOption('EGP', 'E£', 'Egyptian Pound'),
  CurrencyOption('XOF', 'CFA', 'West African CFA Franc'),
  CurrencyOption('XAF', 'FCFA', 'Central African CFA Franc'),
  CurrencyOption('BRL', 'R\$', 'Brazilian Real'),
  CurrencyOption('MXN', 'MX\$', 'Mexican Peso'),
  CurrencyOption('SGD', 'S\$', 'Singapore Dollar'),
  CurrencyOption('HKD', 'HK\$', 'Hong Kong Dollar'),
  CurrencyOption('NZD', 'NZ\$', 'New Zealand Dollar'),
];

CurrencyOption currencyOptionFor(String code) {
  return supportedCurrencies.firstWhere(
    (c) => c.code == code,
    orElse: () => supportedCurrencies.first,
  );
}

class LanguageOption {
  const LanguageOption(this.code, this.label);
  final String code;
  final String label;
}

/// Exactly the 5 codes `preference_routes.py` accepts on the backend.
const supportedLanguages = [
  LanguageOption('en', 'English'),
  LanguageOption('fr', 'French'),
  LanguageOption('es', 'Spanish'),
  LanguageOption('pt', 'Portuguese'),
  LanguageOption('sw', 'Swahili'),
];

LanguageOption languageOptionFor(String code) {
  return supportedLanguages.firstWhere(
    (l) => l.code == code,
    orElse: () => supportedLanguages.first,
  );
}
