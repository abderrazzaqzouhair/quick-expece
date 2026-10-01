import '../app_database.dart';

/// An expense joined with its subcategory and category — what every expense
/// list needs to render a row.
class ExpenseDetails {
  const ExpenseDetails({
    required this.expense,
    required this.subcategory,
    required this.category,
  });

  final ExpenseRow expense;
  final SubcategoryRow subcategory;
  final CategoryRow category;
}

/// Sum of a category's expenses over a period (statistics / home breakdown).
class CategoryTotal {
  const CategoryTotal({
    required this.category,
    required this.totalCents,
    required this.count,
  });

  final CategoryRow category;
  final int totalCents;
  final int count;
}
