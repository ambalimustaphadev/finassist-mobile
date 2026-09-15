/// Mirrors the backend's `paginate_query()` metadata shape exactly:
/// `{"page", "per_page", "total"}` — no `has_next`/`total_pages`, so
/// callers must derive "is there more" themselves (`page * perPage < total`)
/// if they need it.
class Pagination {
  const Pagination({
    required this.page,
    required this.perPage,
    required this.total,
  });

  final int page;
  final int perPage;
  final int total;

  bool get hasMore => page * perPage < total;

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
    );
  }
}

/// A page of [T] plus its [Pagination] metadata.
class Paginated<T> {
  const Paginated({required this.items, required this.pagination});

  final List<T> items;
  final Pagination pagination;
}
