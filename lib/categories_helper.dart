class ProductCategories {
  static const List<String> categories = [
    '🍎 Fruits',
    '🥦 Vegetables',
    '🧀 Dairy',
    '🍗 Meat & Poultry',
    '🐟 Fish & Seafood',
    '🥖 Bakery',
    '🥤 Beverages',
    '🍪 Snacks',
    '❄️ Frozen Foods',
    '🍚 Grains & Pasta',
    '🥫 Canned Goods',
    '🧂 Spices & Condiments',
    '🥣 Sauces & Dressings',
    '🥞 Breakfast Items',
    '🍰 Sweets & Desserts',
    '👶 Baby Food',
    '🌿 Organic & Bio',
    '🍱 Ready Meals',
    '🧻 Non-Food Essentials',
    '📦 Other',
  ];

  static List<String> get availableCategories => categories;

  static String getDisplayName(String? category) {
    return category ?? '📦 Uncategorized';
  }
}
