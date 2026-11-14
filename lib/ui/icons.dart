import 'package:flutter/material.dart';

import '../features/accounts/domain/account.dart';

/// Icon for a category [key]. Unknown keys use a generic glyph.
IconData categoryIcon(String key) {
  return switch (key) {
    'food' => Icons.restaurant_outlined,
    'transport' => Icons.directions_bus_outlined,
    'rent' => Icons.home_outlined,
    'airtime' => Icons.wifi_tethering_outlined,
    'utilities' => Icons.bolt_outlined,
    'shopping' => Icons.shopping_bag_outlined,
    'health' => Icons.favorite_outline,
    'entertainment' => Icons.movie_outlined,
    'family' => Icons.people_outline,
    'home' => Icons.cleaning_services_outlined,
    'salary' => Icons.payments_outlined,
    'freelance' => Icons.work_outline,
    'gift' => Icons.card_giftcard_outlined,
    _ => Icons.category_outlined,
  };
}

/// Icon for an [AccountKind].
IconData accountKindIcon(AccountKind kind) {
  return switch (kind) {
    AccountKind.cash => Icons.payments_outlined,
    AccountKind.bank => Icons.account_balance_outlined,
    AccountKind.mobileMoney => Icons.phone_android,
  };
}
