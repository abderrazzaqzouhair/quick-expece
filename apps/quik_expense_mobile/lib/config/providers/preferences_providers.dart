import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key-value storage for small user data (profile, settings). Loaded once
/// in `main()` and injected with `overrideWithValue`, so reads are
/// synchronous everywhere else.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);
