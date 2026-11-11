/// One page of a cursor-paginated list: `{"items": [...], "next_cursor": "..." | null}`.
class PagedResult<T> {
  const PagedResult({required this.items, this.nextCursor});

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> item) fromJson,
  ) => PagedResult(
    items: [
      for (final item in json['items'] as List<dynamic>)
        fromJson(item as Map<String, dynamic>),
    ],
    nextCursor: json['next_cursor'] as String?,
  );

  final List<T> items;

  /// `null` on the last page.
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}
