import '../../core/theme/theme_preference.dart';
import '../../core/time/iso_date.dart';
import '../../features/accounts/domain/account.dart';
import '../../features/budgets/domain/category_budget.dart';
import '../../features/ledger/domain/ledger_snapshot.dart';
import '../../features/settings/domain/app_settings.dart';
import '../../features/transactions/domain/category.dart';
import '../../features/transactions/domain/ledger_transaction.dart';
import '../../features/transactions/domain/recurring_rule.dart';

/// A lived-in Lagos book, generated from [today].
///
/// The open month is the middle of the month, before payday. Food and airtime
/// are already over their budgets. Earlier months in the six-month window stay
/// inside the limits, so the alert on the dashboard is about this month.
class SeedData {
  const SeedData._();

  static const gtbank = 'acct_gtbank';
  static const opay = 'acct_opay';
  static const moniepoint = 'acct_moniepoint';
  static const cash = 'acct_cash';
  static const usd = 'acct_usd';
  static const gbp = 'acct_gbp';
  static const ghs = 'acct_ghs';
  static const kes = 'acct_kes';

  static const food = 'cat_food';
  static const transport = 'cat_transport';
  static const rent = 'cat_rent';
  static const airtime = 'cat_airtime';
  static const utilities = 'cat_utilities';
  static const shopping = 'cat_shopping';
  static const health = 'cat_health';
  static const entertainment = 'cat_entertainment';
  static const family = 'cat_family';
  static const home = 'cat_home';
  static const salary = 'cat_salary';
  static const freelance = 'cat_freelance';
  static const gift = 'cat_gift';

  static const ruleSalary = 'rule_salary';
  static const ruleRent = 'rule_rent';
  static const ruleDstv = 'rule_dstv';
  static const ruleCleaner = 'rule_cleaner';

  static LedgerSnapshot build(DateTime today) {
    final day = dateOnly(today);
    final months = trailingMonths(day, 6);
    final first = months.first;
    final transactions = <LedgerTransaction>[];

    for (final month in months) {
      final y = month.year;
      final m = month.month;
      final current = y == day.year && m == day.month;
      final offset = months.indexOf(month);
      _expense(
        transactions,
        day,
        id: 'txn_util_${y}_$m',
        date: DateTime.utc(y, m, 6),
        accountId: gtbank,
        categoryId: utilities,
        amountMinor: _minor(18500),
        note: 'IKEDC prepaid',
      );
      _expense(
        transactions,
        day,
        id: 'txn_water_${y}_$m',
        date: DateTime.utc(y, m, 10),
        accountId: gtbank,
        categoryId: utilities,
        amountMinor: _minor(4200),
        note: 'Lagos water',
      );
      if (current) continue;
      _expense(
        transactions,
        day,
        id: 'txn_food_${y}_${m}_a',
        date: DateTime.utc(y, m, 3),
        accountId: gtbank,
        categoryId: food,
        amountMinor: _minor(22000 + offset * 800),
        note: 'Shoprite groceries',
      );
      _expense(
        transactions,
        day,
        id: 'txn_food_${y}_${m}_b',
        date: DateTime.utc(y, m, 9),
        accountId: opay,
        categoryId: food,
        amountMinor: _minor(17500),
        note: 'Balogun market',
      );
      _expense(
        transactions,
        day,
        id: 'txn_food_${y}_${m}_c',
        date: DateTime.utc(y, m, 16),
        accountId: cash,
        categoryId: food,
        amountMinor: _minor(14500),
        note: 'Chicken Republic, Ikeja',
      );
      _expense(
        transactions,
        day,
        id: 'txn_food_${y}_${m}_d',
        date: DateTime.utc(y, m, 23),
        accountId: gtbank,
        categoryId: food,
        amountMinor: _minor(9800),
        note: 'Spar, Ikeja',
      );
      _expense(
        transactions,
        day,
        id: 'txn_airtime_${y}_${m}_a',
        date: DateTime.utc(y, m, 4),
        accountId: opay,
        categoryId: airtime,
        amountMinor: _minor(2000),
        note: 'MTN airtime',
      );
      _expense(
        transactions,
        day,
        id: 'txn_airtime_${y}_${m}_b',
        date: DateTime.utc(y, m, 19),
        accountId: moniepoint,
        categoryId: airtime,
        amountMinor: _minor(4500),
        note: 'Airtel data',
      );
      _expense(
        transactions,
        day,
        id: 'txn_ride_${y}_$m',
        date: DateTime.utc(y, m, 6),
        accountId: opay,
        categoryId: transport,
        amountMinor: _minor(8000),
        note: 'Uber to the Island',
      );
      _expense(
        transactions,
        day,
        id: 'txn_fuel_${y}_$m',
        date: DateTime.utc(y, m, 14),
        accountId: gtbank,
        categoryId: transport,
        amountMinor: _minor(15000),
        note: 'Fuel, Mobil Lekki',
      );
      _expense(
        transactions,
        day,
        id: 'txn_brt_${y}_$m',
        date: DateTime.utc(y, m, 27),
        accountId: cash,
        categoryId: transport,
        amountMinor: _minor(7000),
        note: 'BRT and danfo',
      );
      _expense(
        transactions,
        day,
        id: 'txn_shop_${y}_$m',
        date: DateTime.utc(y, m, 18),
        accountId: gtbank,
        categoryId: shopping,
        amountMinor: _minor(15000),
        note: 'Household shop',
      );
      _expense(
        transactions,
        day,
        id: 'txn_family_${y}_$m',
        date: DateTime.utc(y, m, 20),
        accountId: gtbank,
        categoryId: family,
        amountMinor: _minor(15000),
        note: 'Family support',
      );
      _expense(
        transactions,
        day,
        id: 'txn_film_${y}_$m',
        date: DateTime.utc(y, m, 21),
        accountId: opay,
        categoryId: entertainment,
        amountMinor: _minor(7000),
        note: 'Filmhouse, Lekki',
      );
      if (m == 7) {
        _income(
          transactions,
          day,
          id: 'txn_invoice_jul',
          date: DateTime.utc(y, m, 18),
          accountId: usd,
          categoryId: freelance,
          currencyCode: 'USD',
          amountMinor: _minor(400),
          note: 'Freelance invoice',
        );
        _transfer(
          transactions,
          day,
          id: 'txn_topup_jul',
          date: DateTime.utc(y, m, 2),
          fromId: gtbank,
          toId: opay,
          amountMinor: _minor(40000),
          note: 'Top up OPay',
        );
      }
      if (m == 8) {
        _expense(
          transactions,
          day,
          id: 'txn_oyster',
          date: DateTime.utc(y, m, 8),
          accountId: gbp,
          categoryId: shopping,
          currencyCode: 'GBP',
          amountMinor: _minor(8, 50),
          note: 'Oyster card',
        );
        _expense(
          transactions,
          day,
          id: 'txn_pharmacy',
          date: DateTime.utc(y, m, 11),
          accountId: gtbank,
          categoryId: health,
          amountMinor: _minor(15000),
          note: 'Pharmacy, Ikeja',
        );
        _income(
          transactions,
          day,
          id: 'txn_gift_aug',
          date: DateTime.utc(y, m, 15),
          accountId: gtbank,
          categoryId: gift,
          amountMinor: _minor(20000),
          note: 'Birthday gift',
        );
      }
      if (m == 9) {
        _income(
          transactions,
          day,
          id: 'txn_invoice_sep',
          date: DateTime.utc(y, m, 9),
          accountId: usd,
          categoryId: freelance,
          currencyCode: 'USD',
          amountMinor: _minor(350),
          note: 'Freelance invoice',
        );
        _expense(
          transactions,
          day,
          id: 'txn_bolt_nairobi',
          date: DateTime.utc(y, m, 18),
          accountId: kes,
          categoryId: transport,
          currencyCode: 'KES',
          amountMinor: _minor(800),
          note: 'Bolt, Nairobi',
        );
        _transfer(
          transactions,
          day,
          id: 'txn_cash_sep',
          date: DateTime.utc(y, m, 8),
          fromId: gtbank,
          toId: cash,
          amountMinor: _minor(15000),
          note: 'Cash withdrawal',
        );
      }
      if (m == 10) {
        _expense(
          transactions,
          day,
          id: 'txn_accra',
          date: DateTime.utc(y, m, 4),
          accountId: ghs,
          categoryId: food,
          currencyCode: 'GHS',
          amountMinor: _minor(85),
          note: 'Accra dinner',
        );
      }
    }

    final y = day.year;
    final m = day.month;
    _expense(
      transactions,
      day,
      id: 'txn_nov_shoprite',
      date: DateTime.utc(y, m, 2),
      accountId: gtbank,
      categoryId: food,
      amountMinor: _minor(28400),
      note: 'Shoprite groceries',
    );
    _expense(
      transactions,
      day,
      id: 'txn_nov_chicken',
      date: DateTime.utc(y, m, 5),
      accountId: opay,
      categoryId: food,
      amountMinor: _minor(6800),
      note: 'Chicken Republic, Ikeja',
    );
    _expense(
      transactions,
      day,
      id: 'txn_nov_market',
      date: DateTime.utc(y, m, 7),
      accountId: cash,
      categoryId: food,
      amountMinor: _minor(18750),
      note: 'Balogun market',
    );
    _expense(
      transactions,
      day,
      id: 'txn_nov_groceries',
      date: DateTime.utc(y, m, 9),
      accountId: gtbank,
      categoryId: food,
      amountMinor: _minor(22150),
      note: 'Groceries',
    );
    _expense(
      transactions,
      day,
      id: 'txn_nov_lunch',
      date: DateTime.utc(y, m, 12),
      accountId: opay,
      categoryId: food,
      amountMinor: _minor(4500),
      note: 'Lunch',
    );
    _expense(
      transactions,
      day,
      id: 'txn_nov_market_2',
      date: DateTime.utc(y, m, 14),
      accountId: cash,
      categoryId: food,
      amountMinor: _minor(24600),
      note: 'Market run',
    );
    _expense(
      transactions,
      day,
      id: 'txn_nov_mtn',
      date: DateTime.utc(y, m, 3),
      accountId: opay,
      categoryId: airtime,
      amountMinor: _minor(5000),
      note: 'MTN airtime',
    );
    _expense(
      transactions,
      day,
      id: 'txn_nov_airtel',
      date: DateTime.utc(y, m, 8),
      accountId: moniepoint,
      categoryId: airtime,
      amountMinor: _minor(8000),
      note: 'Airtel data',
    );
    _expense(
      transactions,
      day,
      id: 'txn_nov_glo',
      date: DateTime.utc(y, m, 13),
      accountId: opay,
      categoryId: airtime,
      amountMinor: _minor(3000),
      note: 'Glo data',
    );
    _expense(
      transactions,
      day,
      id: 'txn_nov_uber',
      date: DateTime.utc(y, m, 4),
      accountId: opay,
      categoryId: transport,
      amountMinor: _minor(6500),
      note: 'Uber to the Island',
    );
    _expense(
      transactions,
      day,
      id: 'txn_nov_fuel',
      date: DateTime.utc(y, m, 6),
      accountId: gtbank,
      categoryId: transport,
      amountMinor: _minor(12000),
      note: 'Fuel, Mobil Lekki',
    );
    _expense(
      transactions,
      day,
      id: 'txn_nov_brt',
      date: DateTime.utc(y, m, 11),
      accountId: cash,
      categoryId: transport,
      amountMinor: _minor(3500),
      note: 'BRT and danfo',
    );
    _expense(
      transactions,
      day,
      id: 'txn_nov_spar',
      date: DateTime.utc(y, m, 9),
      accountId: gtbank,
      categoryId: shopping,
      amountMinor: _minor(12400),
      note: 'Spar, Ikeja',
    );
    _expense(
      transactions,
      day,
      id: 'txn_nov_figma',
      date: DateTime.utc(y, m, 10),
      accountId: gbp,
      categoryId: shopping,
      currencyCode: 'GBP',
      amountMinor: _minor(12, 50),
      note: 'Figma subscription',
    );
    _expense(
      transactions,
      day,
      id: 'txn_nov_mum',
      date: DateTime.utc(y, m, 7),
      accountId: gtbank,
      categoryId: family,
      amountMinor: _minor(25000),
      note: 'Send to Mum',
    );
    _income(
      transactions,
      day,
      id: 'txn_nov_invoice',
      date: DateTime.utc(y, m, 6),
      accountId: usd,
      categoryId: freelance,
      currencyCode: 'USD',
      amountMinor: _minor(220),
      note: 'Freelance invoice',
    );
    _transfer(
      transactions,
      day,
      id: 'txn_nov_topup',
      date: DateTime.utc(y, m, 2),
      fromId: gtbank,
      toId: opay,
      amountMinor: _minor(50000),
      note: 'Top up OPay',
    );

    return LedgerSnapshot(
      settings: const AppSettings(
        baseCurrencyCode: 'NGN',
        theme: ThemePreference.light,
        seeded: true,
      ),
      accounts: _accounts(),
      categories: _categories(),
      transactions: transactions,
      rules: _rules(first),
      budgets: _budgets(),
    );
  }

  static List<Account> _accounts() {
    return <Account>[
      Account(
        id: gtbank,
        name: 'GTBank Salary',
        kind: AccountKind.bank,
        currencyCode: 'NGN',
        openingBalanceMinor: _minor(220000),
        institution: 'GTBank',
        color: 0xFFB45309,
        createdAt: DateTime.utc(2026, 6, 1, 8),
      ),
      Account(
        id: opay,
        name: 'OPay Everyday',
        kind: AccountKind.mobileMoney,
        currencyCode: 'NGN',
        openingBalanceMinor: _minor(18500),
        institution: 'OPay',
        color: 0xFF0E8F5B,
        createdAt: DateTime.utc(2026, 6, 1, 8, 1),
      ),
      Account(
        id: moniepoint,
        name: 'Moniepoint Business',
        kind: AccountKind.mobileMoney,
        currencyCode: 'NGN',
        openingBalanceMinor: _minor(42000),
        institution: 'Moniepoint',
        color: 0xFF1D4E89,
        createdAt: DateTime.utc(2026, 6, 1, 8, 2),
      ),
      Account(
        id: cash,
        name: 'Cash',
        kind: AccountKind.cash,
        currencyCode: 'NGN',
        openingBalanceMinor: _minor(180000),
        color: 0xFF3D5A40,
        createdAt: DateTime.utc(2026, 6, 1, 8, 3),
      ),
      Account(
        id: usd,
        name: 'Domiciliary USD',
        kind: AccountKind.bank,
        currencyCode: 'USD',
        openingBalanceMinor: _minor(180),
        institution: 'GTBank',
        color: 0xFF1F6F8B,
        createdAt: DateTime.utc(2026, 6, 1, 8, 4),
      ),
      Account(
        id: gbp,
        name: 'Wise GBP',
        kind: AccountKind.bank,
        currencyCode: 'GBP',
        openingBalanceMinor: _minor(95),
        institution: 'Wise',
        color: 0xFF5B4B8A,
        createdAt: DateTime.utc(2026, 6, 1, 8, 5),
      ),
      Account(
        id: ghs,
        name: 'Cedi pocket',
        kind: AccountKind.cash,
        currencyCode: 'GHS',
        openingBalanceMinor: _minor(240),
        color: 0xFFC5922C,
        createdAt: DateTime.utc(2026, 6, 1, 8, 6),
      ),
      Account(
        id: kes,
        name: 'M-Pesa',
        kind: AccountKind.mobileMoney,
        currencyCode: 'KES',
        openingBalanceMinor: _minor(6500),
        institution: 'M-Pesa',
        color: 0xFF2A9D8F,
        createdAt: DateTime.utc(2026, 6, 1, 8, 7),
      ),
    ];
  }

  static List<Category> _categories() {
    return const <Category>[
      Category(
        id: food,
        name: 'Food',
        kind: CategoryKind.expense,
        color: 0xFFC5922C,
        iconKey: 'food',
      ),
      Category(
        id: transport,
        name: 'Transport',
        kind: CategoryKind.expense,
        color: 0xFF1F6F8B,
        iconKey: 'transport',
      ),
      Category(
        id: rent,
        name: 'Rent',
        kind: CategoryKind.expense,
        color: 0xFF0E8F5B,
        iconKey: 'rent',
      ),
      Category(
        id: airtime,
        name: 'Airtime & Data',
        kind: CategoryKind.expense,
        color: 0xFF5B4B8A,
        iconKey: 'airtime',
      ),
      Category(
        id: utilities,
        name: 'Utilities',
        kind: CategoryKind.expense,
        color: 0xFFB23A32,
        iconKey: 'utilities',
      ),
      Category(
        id: shopping,
        name: 'Shopping',
        kind: CategoryKind.expense,
        color: 0xFFD06A2B,
        iconKey: 'shopping',
      ),
      Category(
        id: health,
        name: 'Health',
        kind: CategoryKind.expense,
        color: 0xFF2A9D8F,
        iconKey: 'health',
      ),
      Category(
        id: entertainment,
        name: 'Entertainment',
        kind: CategoryKind.expense,
        color: 0xFF8E3B6A,
        iconKey: 'entertainment',
      ),
      Category(
        id: family,
        name: 'Family',
        kind: CategoryKind.expense,
        color: 0xFF3D5A40,
        iconKey: 'family',
      ),
      Category(
        id: home,
        name: 'Home',
        kind: CategoryKind.expense,
        color: 0xFF6B705C,
        iconKey: 'home',
      ),
      Category(
        id: salary,
        name: 'Salary',
        kind: CategoryKind.income,
        color: 0xFF0E7A45,
        iconKey: 'salary',
      ),
      Category(
        id: freelance,
        name: 'Freelance',
        kind: CategoryKind.income,
        color: 0xFF1D4E89,
        iconKey: 'freelance',
      ),
      Category(
        id: gift,
        name: 'Gift',
        kind: CategoryKind.income,
        color: 0xFFC47B2B,
        iconKey: 'gift',
      ),
    ];
  }

  static List<RecurringRule> _rules(DateTime first) {
    return <RecurringRule>[
      RecurringRule(
        id: ruleSalary,
        kind: TransactionKind.income,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        startOn: DateTime.utc(first.year, first.month, 28),
        accountId: gtbank,
        categoryId: salary,
        amountMinor: _minor(850000),
        currencyCode: 'NGN',
        note: 'Salary',
      ),
      RecurringRule(
        id: ruleRent,
        kind: TransactionKind.expense,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        startOn: first,
        accountId: gtbank,
        categoryId: rent,
        amountMinor: _minor(180000),
        currencyCode: 'NGN',
        note: 'Rent',
      ),
      RecurringRule(
        id: ruleDstv,
        kind: TransactionKind.expense,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        startOn: DateTime.utc(first.year, first.month, 5),
        accountId: gtbank,
        categoryId: entertainment,
        amountMinor: _minor(15500),
        currencyCode: 'NGN',
        note: 'DSTV',
      ),
      RecurringRule(
        id: ruleCleaner,
        kind: TransactionKind.expense,
        frequency: RecurrenceFrequency.weekly,
        interval: 1,
        startOn: DateTime.utc(first.year, first.month, 5),
        accountId: opay,
        categoryId: home,
        amountMinor: _minor(8000),
        currencyCode: 'NGN',
        note: 'Friday cleaner',
      ),
    ];
  }

  static List<CategoryBudget> _budgets() {
    return <CategoryBudget>[
      CategoryBudget(
        id: 'bud_rent',
        categoryId: rent,
        limitMinor: _minor(180000),
        currencyCode: 'NGN',
      ),
      CategoryBudget(
        id: 'bud_food',
        categoryId: food,
        limitMinor: _minor(90000),
        currencyCode: 'NGN',
      ),
      CategoryBudget(
        id: 'bud_transport',
        categoryId: transport,
        limitMinor: _minor(45000),
        currencyCode: 'NGN',
      ),
      CategoryBudget(
        id: 'bud_airtime',
        categoryId: airtime,
        limitMinor: _minor(12000),
        currencyCode: 'NGN',
      ),
      CategoryBudget(
        id: 'bud_utilities',
        categoryId: utilities,
        limitMinor: _minor(40000),
        currencyCode: 'NGN',
      ),
      CategoryBudget(
        id: 'bud_shopping',
        categoryId: shopping,
        limitMinor: _minor(50000),
        currencyCode: 'NGN',
      ),
      CategoryBudget(
        id: 'bud_health',
        categoryId: health,
        limitMinor: _minor(20000),
        currencyCode: 'NGN',
      ),
      CategoryBudget(
        id: 'bud_entertainment',
        categoryId: entertainment,
        limitMinor: _minor(25000),
        currencyCode: 'NGN',
      ),
      CategoryBudget(
        id: 'bud_family',
        categoryId: family,
        limitMinor: _minor(40000),
        currencyCode: 'NGN',
      ),
      CategoryBudget(
        id: 'bud_home',
        categoryId: home,
        limitMinor: _minor(40000),
        currencyCode: 'NGN',
      ),
    ];
  }

  static void _expense(
    List<LedgerTransaction> into,
    DateTime today, {
    required String id,
    required DateTime date,
    required String accountId,
    required String categoryId,
    required int amountMinor,
    required String note,
    String currencyCode = 'NGN',
  }) {
    if (dateOnly(date).isAfter(today)) return;
    into.add(
      LedgerTransaction(
        id: id,
        kind: TransactionKind.expense,
        accountId: accountId,
        categoryId: categoryId,
        amountMinor: amountMinor,
        currencyCode: currencyCode,
        occurredOn: dateOnly(date),
        note: note,
      ),
    );
  }

  static void _income(
    List<LedgerTransaction> into,
    DateTime today, {
    required String id,
    required DateTime date,
    required String accountId,
    required String categoryId,
    required int amountMinor,
    required String note,
    String currencyCode = 'NGN',
  }) {
    if (dateOnly(date).isAfter(today)) return;
    into.add(
      LedgerTransaction(
        id: id,
        kind: TransactionKind.income,
        accountId: accountId,
        categoryId: categoryId,
        amountMinor: amountMinor,
        currencyCode: currencyCode,
        occurredOn: dateOnly(date),
        note: note,
      ),
    );
  }

  static void _transfer(
    List<LedgerTransaction> into,
    DateTime today, {
    required String id,
    required DateTime date,
    required String fromId,
    required String toId,
    required int amountMinor,
    required String note,
  }) {
    if (dateOnly(date).isAfter(today)) return;
    into.add(
      LedgerTransaction(
        id: id,
        kind: TransactionKind.transfer,
        accountId: fromId,
        counterAccountId: toId,
        amountMinor: amountMinor,
        destinationAmountMinor: amountMinor,
        currencyCode: 'NGN',
        occurredOn: dateOnly(date),
        note: note,
      ),
    );
  }

  static int _minor(int major, [int fraction = 0]) => major * 100 + fraction;
}
