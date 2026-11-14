enum CategoryKind { income, expense }

CategoryKind parseCategoryKind(String value) {
  return switch (value) {
    'income' => CategoryKind.income,
    'expense' => CategoryKind.expense,
    _ => throw ArgumentError.value(value, 'value', 'unknown category kind'),
  };
}

extension CategoryKindLabel on CategoryKind {
  String get storageName => switch (this) {
    CategoryKind.income => 'income',
    CategoryKind.expense => 'expense',
  };
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.kind,
    required this.color,
    required this.iconKey,
  });

  final String id;
  final String name;
  final CategoryKind kind;
  final int color;
  final String iconKey;

  Category copyWith({String? name, int? color, String? iconKey}) {
    return Category(
      id: id,
      name: name ?? this.name,
      kind: kind,
      color: color ?? this.color,
      iconKey: iconKey ?? this.iconKey,
    );
  }
}
