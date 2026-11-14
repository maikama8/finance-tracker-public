class CategoryBudget {
  const CategoryBudget({
    required this.id,
    required this.categoryId,
    required this.limitMinor,
    required this.currencyCode,
  });

  final String id;
  final String categoryId;

  /// Limit in [currencyCode] minor units. The engine converts it to the
  /// current base currency when it draws progress.
  final int limitMinor;
  final String currencyCode;

  CategoryBudget copyWith({int? limitMinor, String? currencyCode}) {
    return CategoryBudget(
      id: id,
      categoryId: categoryId,
      limitMinor: limitMinor ?? this.limitMinor,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }
}
