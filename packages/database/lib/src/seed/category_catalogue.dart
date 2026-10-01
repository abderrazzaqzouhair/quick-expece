/// The global category/subcategory catalogue — a copy of the Laravel
/// `CategorySeeder` (without icons). Edit here and bump the schema version
/// (or reinstall) to re-run the seeder.
class CatalogueCategory {
  const CatalogueCategory({
    required this.name,
    required this.color,
    required this.subcategories,
  });

  final String name;
  final String color;
  final List<String> subcategories;
}

const categoryCatalogue = <CatalogueCategory>[
  CatalogueCategory(
    name: 'Food & Drinks',
    color: '#F59E0B',
    subcategories: [
      'Groceries',
      'Restaurants',
      'Fast Food',
      'Coffee',
      'Snacks',
      'Delivery',
      'Drinks',
      'Bakery',
    ],
  ),
  CatalogueCategory(
    name: 'Transport',
    color: '#3B82F6',
    subcategories: [
      'Taxi',
      'Bus',
      'Train',
      'Fuel',
      'Parking',
      'Car Maintenance',
      'Ride Apps',
      'Bike',
    ],
  ),
  CatalogueCategory(
    name: 'Housing & Living',
    color: '#10B981',
    subcategories: [
      'Rent',
      'Electricity',
      'Water',
      'Internet',
      'Phone',
      'Furniture',
      'Repairs',
      'Cleaning',
    ],
  ),
  CatalogueCategory(
    name: 'Entertainment & Fun',
    color: '#8B5CF6',
    subcategories: [
      'Games',
      'Movies',
      'Streaming',
      'Music',
      'Events',
      'Outings',
      'Hobbies',
    ],
  ),
  CatalogueCategory(
    name: 'Personal & Lifestyle',
    color: '#EC4899',
    subcategories: [
      'Clothes',
      'Shoes',
      'Haircut',
      'Skincare',
      'Gym',
      'Accessories',
      'Perfume',
    ],
  ),
  CatalogueCategory(
    name: 'Subscriptions & Digital',
    color: '#6366F1',
    subcategories: [
      'Netflix',
      'Spotify',
      'Cloud Storage',
      'Apps',
      'Gaming Subscriptions',
      'Software',
    ],
  ),
  CatalogueCategory(
    name: 'Education & Learning',
    color: '#0EA5E9',
    subcategories: [
      'Courses',
      'Books',
      'Supplies',
      'Online Platforms',
      'Certifications',
    ],
  ),
  CatalogueCategory(
    name: 'Health & Medical',
    color: '#EF4444',
    subcategories: [
      'Doctor',
      'Pharmacy',
      'Insurance',
      'Fitness',
      'Supplements',
    ],
  ),
  CatalogueCategory(
    name: 'Social & Gifts',
    color: '#D946EF',
    subcategories: ['Gifts', 'Charity', 'Family', 'Friends', 'Events'],
  ),
  CatalogueCategory(
    name: 'Travel',
    color: '#06B6D4',
    subcategories: [
      'Flights',
      'Hotels',
      'Food (Travel)',
      'Transport (Travel)',
      'Activities',
    ],
  ),
  CatalogueCategory(
    name: 'Bills & Financial',
    color: '#64748B',
    subcategories: ['Taxes', 'Bank Fees', 'Loan', 'Credit Card', 'Fines'],
  ),
  CatalogueCategory(
    name: 'Miscellaneous',
    color: '#78716C',
    subcategories: ['Unexpected', 'Small Stuff', 'Random'],
  ),
];
