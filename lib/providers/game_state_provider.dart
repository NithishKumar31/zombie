import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameStateProvider with ChangeNotifier {
  SharedPreferences? _prefs;

  int _coins = 0;
  int _xp = 0;
  int _level = 1;
  int _highestLevelUnlocked = 1;
  
  // Audio settings
  bool _soundEnabled = true;
  bool _musicEnabled = true;

  // Weapons
  List<String> _unlockedWeapons = ['Bow'];
  String _currentWeapon = 'Bow';

  int get coins => _coins;
  int get xp => _xp;
  int get level => _level; 
  int get highestLevelUnlocked => _highestLevelUnlocked;
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  List<String> get unlockedWeapons => _unlockedWeapons;
  String get currentWeapon => _currentWeapon;

  GameStateProvider() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _coins = _prefs?.getInt('coins') ?? 0;
    _xp = _prefs?.getInt('xp') ?? 0;
    _level = _calculateLevel(_xp);
    _highestLevelUnlocked = _prefs?.getInt('highestLevelUnlocked') ?? 1;
    _soundEnabled = _prefs?.getBool('soundEnabled') ?? true;
    _musicEnabled = _prefs?.getBool('musicEnabled') ?? true;
    
    _unlockedWeapons = _prefs?.getStringList('unlockedWeapons') ?? ['Bow'];
    _currentWeapon = _prefs?.getString('currentWeapon') ?? 'Bow';
    
    notifyListeners();
  }

  int _calculateLevel(int currentXp) {
    return (currentXp / 1000).floor() + 1;
  }

  Future<void> addCoins(int amount) async {
    _coins += amount;
    await _prefs?.setInt('coins', _coins);
    notifyListeners();
  }

  Future<bool> spendCoins(int amount) async {
    if (_coins >= amount) {
      _coins -= amount;
      await _prefs?.setInt('coins', _coins);
      notifyListeners();
      return true;
    }
    return false;
  }
  
  Future<void> unlockWeapon(String weaponId) async {
    if (!_unlockedWeapons.contains(weaponId)) {
      _unlockedWeapons.add(weaponId);
      await _prefs?.setStringList('unlockedWeapons', _unlockedWeapons);
      notifyListeners();
    }
  }
  
  Future<void> equipWeapon(String weaponId) async {
    if (_unlockedWeapons.contains(weaponId)) {
      _currentWeapon = weaponId;
      await _prefs?.setString('currentWeapon', _currentWeapon);
      notifyListeners();
    }
  }

  Future<void> addXp(int amount) async {
    _xp += amount;
    _level = _calculateLevel(_xp);
    await _prefs?.setInt('xp', _xp);
    notifyListeners();
  }

  Future<void> completeGameLevel(int completedLevel, int coinsEarned, int xpEarned) async {
    await addCoins(coinsEarned);
    await addXp(xpEarned);
    if (completedLevel >= _highestLevelUnlocked) {
      _highestLevelUnlocked = completedLevel + 1;
      await _prefs?.setInt('highestLevelUnlocked', _highestLevelUnlocked);
    }
    notifyListeners();
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    await _prefs?.setBool('soundEnabled', _soundEnabled);
    notifyListeners();
  }

  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    await _prefs?.setBool('musicEnabled', _musicEnabled);
    notifyListeners();
  }
}
