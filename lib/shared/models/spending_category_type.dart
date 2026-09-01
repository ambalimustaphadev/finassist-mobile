/// The set of spending categories FinAssist classifies transactions into.
enum SpendingCategoryType {
  foodAndDining,
  transfers,
  shopping,
  bills,
  others;

  String get label {
    switch (this) {
      case SpendingCategoryType.foodAndDining:
        return 'Food & Dining';
      case SpendingCategoryType.transfers:
        return 'Transfers';
      case SpendingCategoryType.shopping:
        return 'Shopping';
      case SpendingCategoryType.bills:
        return 'Bills';
      case SpendingCategoryType.others:
        return 'Others';
    }
  }
}
