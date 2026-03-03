import 'package:flutter/foundation.dart';

class AppEvents {
  static final ValueNotifier<int> favoritesVersion = ValueNotifier<int>(0);
  static final ValueNotifier<int> notesVersion = ValueNotifier<int>(0);

  static void notifyFavoritesChanged() {
    favoritesVersion.value++;
  }

  static void notifyNotesChanged() {
    notesVersion.value++;
  }
}
