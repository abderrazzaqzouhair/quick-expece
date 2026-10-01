/// Every bundled asset path in `ui_kit`, in one place. Widgets should
/// reference these constants instead of retyping the raw path string — a
/// typo'd constant name fails at compile time; a typo'd string literal just
/// renders a missing-asset error at runtime.
abstract final class AppAssets {
  static const _iconsBase = 'packages/ui_kit/assets/icons';

  static const iconHome = '$_iconsBase/home.svg';
  static const iconStatistics = '$_iconsBase/statistics.svg';
  static const iconHistory = '$_iconsBase/history.svg';
  static const iconProfile = '$_iconsBase/profile.svg';
  static const iconAdd = '$_iconsBase/add.svg';
  static const iconCategoriesGrid = '$_iconsBase/categories-grid.svg';
  static const iconLightbulb = '$_iconsBase/lightbulb.svg';

  static const iconCategoryFood = '$_iconsBase/category-food.svg';
  static const iconCategoryTransport = '$_iconsBase/category-transport.svg';
  static const iconCategoryEntertainment =
      '$_iconsBase/category-entertainment.svg';
  static const iconCategorySubscriptions =
      '$_iconsBase/category-subscriptions.svg';

  static const iconAppleLogo = '$_iconsBase/apple.svg';
  static const iconGoogleLogo = '$_iconsBase/google.svg';

  static const imageLogo = 'assets/images/logo.png';
}
