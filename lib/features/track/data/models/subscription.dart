/// Mirrors `subscription_to_dict()` in the Flask backend's
/// `services/subscription_service.py` exactly — every field name below is
/// the real JSON key, not a guess.
class Subscription {
  const Subscription({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.currency,
    required this.frequency,
    required this.nextBillingDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.paymentMethod,
    this.website,
    this.notes,
    this.cancelledAt,
  });

  final int id;
  final int userId;
  final String name;
  final double amount;
  final String currency;
  final SubscriptionFrequency frequency;
  final DateTime nextBillingDate;
  final SubscriptionCategory? category;
  final PaymentMethod? paymentMethod;
  final String? website;
  final String? notes;
  final SubscriptionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? cancelledAt;

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as String?;
    final paymentMethod = json['payment_method'] as String?;
    final cancelledAt = json['cancelled_at'] as String?;
    return Subscription(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'NGN',
      frequency: SubscriptionFrequency.fromApiValue(
        json['frequency'] as String? ?? 'monthly',
      ),
      nextBillingDate: DateTime.parse(json['next_billing_date'] as String),
      category: category == null
          ? null
          : SubscriptionCategory.fromApiValue(category),
      paymentMethod: paymentMethod == null
          ? null
          : PaymentMethod.fromApiValue(paymentMethod),
      website: json['website'] as String?,
      notes: json['notes'] as String?,
      status: SubscriptionStatus.fromApiValue(
        json['status'] as String? ?? 'active',
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      cancelledAt: cancelledAt == null ? null : DateTime.parse(cancelledAt),
    );
  }
}

enum SubscriptionFrequency {
  weekly('weekly', 'Weekly', 'week'),
  monthly('monthly', 'Monthly', 'month'),
  quarterly('quarterly', 'Every 3 months', '3 months'),
  semiannual('semiannual', 'Every 6 months', '6 months'),
  yearly('yearly', 'Yearly', 'year');

  const SubscriptionFrequency(this.apiValue, this.label, this.shortUnit);

  final String apiValue;
  final String label;

  /// Short billing-unit suffix for compact "₦7,000 / month" style rows.
  final String shortUnit;

  static SubscriptionFrequency fromApiValue(String value) {
    return SubscriptionFrequency.values.firstWhere(
      (f) => f.apiValue == value,
      orElse: () => SubscriptionFrequency.monthly,
    );
  }
}

enum SubscriptionCategory {
  entertainment('entertainment', 'Entertainment'),
  software('software', 'Software'),
  cloudStorage('cloud_storage', 'Cloud & Storage'),
  education('education', 'Education'),
  fitness('fitness', 'Fitness'),
  newsMedia('news_media', 'News & Media'),
  productivity('productivity', 'Productivity'),
  shopping('shopping', 'Shopping'),
  gaming('gaming', 'Gaming'),
  other('other', 'Other');

  const SubscriptionCategory(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static SubscriptionCategory fromApiValue(String value) {
    return SubscriptionCategory.values.firstWhere(
      (c) => c.apiValue == value,
      orElse: () => SubscriptionCategory.other,
    );
  }
}

enum PaymentMethod {
  debitCard('debit_card', 'Debit card'),
  creditCard('credit_card', 'Credit card'),
  bankAccount('bank_account', 'Bank account'),
  mobileWallet('mobile_wallet', 'Mobile wallet'),
  directDebit('direct_debit', 'Direct debit'),
  cash('cash', 'Cash'),
  other('other', 'Other');

  const PaymentMethod(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PaymentMethod fromApiValue(String value) {
    return PaymentMethod.values.firstWhere(
      (m) => m.apiValue == value,
      orElse: () => PaymentMethod.other,
    );
  }
}

enum SubscriptionStatus {
  active('active', 'Active'),
  paused('paused', 'Paused'),
  cancelled('cancelled', 'Cancelled');

  const SubscriptionStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static SubscriptionStatus fromApiValue(String value) {
    return SubscriptionStatus.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => SubscriptionStatus.active,
    );
  }
}
