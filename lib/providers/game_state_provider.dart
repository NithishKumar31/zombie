import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/audio_service.dart';
import '../utils/weapon_registry.dart';

class GameStateProvider with ChangeNotifier {
  SharedPreferences? _prefs;

  int _coins = 0;
  int _xp = 0;
  int _level = 1;
  int _highestLevelUnlocked = 1;
  int _totalZombiesKilled = 0;
  int _tacticalCratesCollected = 0;
  int _highestEndlessWave = 1;
  int _endlessHighScore = 0;

  // Audio settings
  bool _soundEnabled = true;
  bool _musicEnabled = true;

  // Weapons (strictly tied to level progression)
  List<String> _unlockedWeapons = ['Bow'];
  String _currentWeapon = 'Bow';

  int get coins => _coins;
  int get xp => _xp;
  int get level => _level;
  int get highestLevelUnlocked => _highestLevelUnlocked;
  int get totalZombiesKilled => _totalZombiesKilled;
  int get tacticalCratesCollected => _tacticalCratesCollected;
  int get highestEndlessWave => _highestEndlessWave;
  int get endlessHighScore => _endlessHighScore;
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
    _totalZombiesKilled = _prefs?.getInt('totalZombiesKilled') ?? 0;
    _tacticalCratesCollected = _prefs?.getInt('tacticalCratesCollected') ?? 0;
    _highestEndlessWave = _prefs?.getInt('highestEndlessWave') ?? 1;
    _endlessHighScore = _prefs?.getInt('endlessHighScore') ?? 0;
    _soundEnabled = _prefs?.getBool('soundEnabled') ?? true;
    _musicEnabled = _prefs?.getBool('musicEnabled') ?? true;

    // Strict sanitization: Weapons unlock section by section, level by level!
    // Prevents all weapons from being open at level 1.
    _sanitizeAndSyncWeapons();

    if (_musicEnabled) {
      AudioService().playBackgroundMusic();
    }

    notifyListeners();
  }

  void _sanitizeAndSyncWeapons() {
    // Only weapons whose unlockLevel <= _highestLevelUnlocked are accessible
    final allowedWeapons = WeaponRegistry.allWeapons
        .where((w) => w.unlockLevel <= _highestLevelUnlocked)
        .map((w) => w.name)
        .toList();

    if (!allowedWeapons.contains('Bow')) {
      allowedWeapons.insert(0, 'Bow');
    }

    _unlockedWeapons = allowedWeapons;
    _prefs?.setStringList('unlockedWeapons', _unlockedWeapons);

    final savedWeapon = _prefs?.getString('currentWeapon');
    if (savedWeapon != null && _unlockedWeapons.contains(savedWeapon)) {
      _currentWeapon = savedWeapon;
    } else {
      _currentWeapon = _unlockedWeapons.last;
      _prefs?.setString('currentWeapon', _currentWeapon);
    }
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

  Future<void> recordKill() async {
    _totalZombiesKilled++;
    await _prefs?.setInt('totalZombiesKilled', _totalZombiesKilled);
  }

  Future<void> recordPowerUpCollected() async {
    _tacticalCratesCollected++;
    await _prefs?.setInt('tacticalCratesCollected', _tacticalCratesCollected);
    notifyListeners();
  }

  Future<void> recordEndlessWave(int wave, int score) async {
    bool changed = false;
    if (wave > _highestEndlessWave) {
      _highestEndlessWave = wave;
      await _prefs?.setInt('highestEndlessWave', _highestEndlessWave);
      changed = true;
    }
    if (score > _endlessHighScore) {
      _endlessHighScore = score;
      await _prefs?.setInt('endlessHighScore', _endlessHighScore);
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// Get weapons available for a specific mission level.
  /// Strictly ensures that higher level weapons do not open in earlier levels.
  List<String> getWeaponsForMission(int missionLevel) {
    return WeaponRegistry.allWeapons
        .where((w) => w.unlockLevel <= missionLevel && _unlockedWeapons.contains(w.name))
        .map((w) => w.name)
        .toList();
  }

  bool isWeaponUnlocked(String weaponName) {
    return _unlockedWeapons.contains(weaponName);
  }

  Future<void> unlockWeapon(String weaponId) async {
    final weapon = WeaponRegistry.getWeaponByName(weaponId);
    if (weapon != null && weapon.unlockLevel <= _highestLevelUnlocked) {
      if (!_unlockedWeapons.contains(weaponId)) {
        _unlockedWeapons.add(weaponId);
        await _prefs?.setStringList('unlockedWeapons', _unlockedWeapons);
        notifyListeners();
      }
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

    bool leveledUp = false;
    if (completedLevel >= _highestLevelUnlocked) {
      _highestLevelUnlocked = completedLevel + 1;
      await _prefs?.setInt('highestLevelUnlocked', _highestLevelUnlocked);
      leveledUp = true;
    }

    _sanitizeAndSyncWeapons();

    // If a new weapon unlocked for this sector, auto-equip it!
    if (leveledUp) {
      final newlyUnlocked = WeaponRegistry.getWeaponUnlockedAtLevel(_highestLevelUnlocked);
      if (newlyUnlocked != null && _unlockedWeapons.contains(newlyUnlocked.name)) {
        _currentWeapon = newlyUnlocked.name;
        await _prefs?.setString('currentWeapon', _currentWeapon);
      }
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
    if (_musicEnabled) {
      AudioService().playBackgroundMusic();
    } else {
      AudioService().stopBackgroundMusic();
    }
    notifyListeners();
  }
}
