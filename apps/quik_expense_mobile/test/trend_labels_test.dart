import 'package:flutter_test/flutter_test.dart';
import 'package:quik_expense_mobile/features/statistics/logic/period_stats.dart';
import 'package:quik_expense_mobile/features/statistics/logic/trend_labels.dart';

void main() {
  final now = DateTime(2026, 10, 7, 12); // Wednesday

  PeriodStats stats(StatsPeriod p) =>
      buildPeriodStats(p, windowFor(p, now), const [], now);

  test('comparison phrases', () {
    expect(comparisonPhrase(StatsPeriod.month), 'vs last month');
    expect(comparisonPhrase(StatsPeriod.today), 'vs yesterday');
    expect(comparisonPhrase(StatsPeriod.all), isNull);
  });

  test('window labels', () {
    expect(
      windowLabel(StatsPeriod.week, stats(StatsPeriod.week)),
      'Oct 5 – Oct 11',
    );
    expect(
      windowLabel(StatsPeriod.month, stats(StatsPeriod.month)),
      'October 2026',
    );
    expect(
      windowLabel(StatsPeriod.sixMonths, stats(StatsPeriod.sixMonths)),
      'May – Oct 2026',
    );
    expect(
      windowLabel(StatsPeriod.year, stats(StatsPeriod.year)),
      'Nov 2025 – Oct 2026',
    );
    expect(
      windowLabel(StatsPeriod.today, stats(StatsPeriod.today)),
      'Wednesday, Oct 7',
    );
  });

  test('bucket details', () {
    final month = stats(StatsPeriod.month).buckets;
    expect(bucketDetail(StatsPeriod.month, month[1]), 'Week 2 · Oct 8–14');
    expect(bucketDetail(StatsPeriod.month, month.last), 'Week 5 · Oct 29–31');

    final today = stats(StatsPeriod.today).buckets;
    expect(bucketDetail(StatsPeriod.today, today[1]), 'Morning · 06:00–12:00');
    expect(
      bucketDetail(StatsPeriod.today, today.last),
      'Evening · 18:00–24:00',
    );

    final week = stats(StatsPeriod.week).buckets;
    expect(bucketDetail(StatsPeriod.week, week[2]), 'Wednesday, Oct 7');
    expect(
      axisLabel(StatsPeriod.year, stats(StatsPeriod.year).buckets.first),
      'N',
    );
  });
}
