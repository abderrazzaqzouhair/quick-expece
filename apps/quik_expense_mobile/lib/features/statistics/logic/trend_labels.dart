import 'package:intl/intl.dart';

import 'period_stats.dart';

/// What the "% change" compares against, e.g. "vs last month". `null` for
/// periods with nothing before them (All).
String? comparisonPhrase(StatsPeriod period) => switch (period) {
  StatsPeriod.today => 'vs yesterday',
  StatsPeriod.week => 'vs last week',
  StatsPeriod.month => 'vs last month',
  StatsPeriod.sixMonths => 'vs previous 6 months',
  StatsPeriod.year => 'vs previous year',
  StatsPeriod.all => null,
};

/// The dates a window covers, for the card subtitle: "Oct 5 – Oct 11",
/// "Oct 2026", "May – Oct 2026", "Since 2024".
String windowLabel(StatsPeriod period, PeriodStats stats) {
  final buckets = stats.buckets;
  if (buckets.isEmpty) return '';
  final from = buckets.first.range.from;
  // Ranges are half-open — the last day is the instant before `to`.
  final to = buckets.last.range.to.subtract(const Duration(minutes: 1));
  final md = DateFormat.MMMd('en_US');
  return switch (period) {
    StatsPeriod.today => DateFormat('EEEE, MMM d', 'en_US').format(from),
    StatsPeriod.week => '${md.format(from)} – ${md.format(to)}',
    StatsPeriod.month => DateFormat.yMMMM('en_US').format(from),
    StatsPeriod.sixMonths || StatsPeriod.year =>
      '${(from.year == to.year ? DateFormat.MMM('en_US') : DateFormat.yMMM('en_US')).format(from)}'
          ' – ${DateFormat.yMMM('en_US').format(to)}',
    StatsPeriod.all => 'Since ${from.year}',
  };
}

/// One bar's full description for the readout: "Morning · 06:00–12:00",
/// "Wednesday, Oct 7", "Week 2 · Oct 8–14", "September 2026", "2025".
String bucketDetail(StatsPeriod period, StatsBucket bucket) {
  final from = bucket.range.from;
  final last = bucket.range.to.subtract(const Duration(minutes: 1));
  final hm = DateFormat.Hm('en_US');
  return switch (period) {
    // The last quarter ends at midnight — show it as 24:00, not 00:00.
    StatsPeriod.today =>
      '${bucket.label} · ${hm.format(from)}–'
          '${bucket.range.to.day != from.day ? '24:00' : hm.format(bucket.range.to)}',
    StatsPeriod.week => DateFormat('EEEE, MMM d', 'en_US').format(from),
    StatsPeriod.month =>
      'Week ${bucket.label.substring(1)} · '
          '${DateFormat.MMMd('en_US').format(from)}–${last.day}',
    StatsPeriod.sixMonths ||
    StatsPeriod.year => DateFormat.yMMMM('en_US').format(from),
    StatsPeriod.all => bucket.label,
  };
}

/// Short caption for the chart bubble: "Morning", "Wednesday", "Week 2",
/// "October", "2025".
String bucketCaption(StatsPeriod period, StatsBucket bucket) =>
    switch (period) {
      StatsPeriod.today || StatsPeriod.all => bucket.label,
      StatsPeriod.week => DateFormat.EEEE('en_US').format(bucket.range.from),
      StatsPeriod.month => 'Week ${bucket.label.substring(1)}',
      StatsPeriod.sixMonths ||
      StatsPeriod.year => DateFormat.MMMM('en_US').format(bucket.range.from),
    };

/// Short axis label under a bar. Twelve month names don't fit, so the
/// Year view uses initials.
String axisLabel(StatsPeriod period, StatsBucket bucket) => switch (period) {
  StatsPeriod.year => bucket.label.substring(0, 1),
  StatsPeriod.today => bucket.label.substring(0, 3),
  _ => bucket.label,
};
