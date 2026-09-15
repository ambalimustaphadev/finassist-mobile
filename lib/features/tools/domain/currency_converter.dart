/// Converts [amount] using a rate already fetched from `FxRateService` (or
/// typed in manually as a fallback) — kept as its own pure function so the
/// arithmetic is testable independent of the network call that produces
/// the rate.
double convertAmount(double amount, double rate) => amount * rate;
