import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _favoritesKey = 'favorites';

  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  static Future<void> addFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList(_favoritesKey) ?? [];
    if (!favs.contains(id)) {
      favs.add(id);
      await prefs.setStringList(_favoritesKey, favs);
    }
  }

  static Future<void> removeFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList(_favoritesKey) ?? [];
    favs.remove(id);
    await prefs.setStringList(_favoritesKey, favs);
  }

  static Future<bool> isFavorite(String id) async {
    final favs = await getFavorites();
    return favs.contains(id);
  }

  // Yeni metod: tüm favori listesini kaydeder
  static Future<void> saveFavorites(List<String> favs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, favs);
  }
}
