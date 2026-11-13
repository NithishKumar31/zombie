import 'package:flutter/material.dart';

class WeaponInfo {
  final String id;
  final String name;
  final String desc;
  final int unlockLevel;
  final int price;
  final IconData icon;

  const WeaponInfo({
    required this.id,
    required this.name,
    required this.desc,
    required this.unlockLevel,
    required this.price,
    required this.icon,
  });
}

class WeaponRegistry {
  static const List<WeaponInfo> allWeapons = [
    WeaponInfo(
      id: 'Bow',
      name: 'Bow',
      desc: 'Starter weapon with silent high-velocity arrows',
      unlockLevel: 1,
      price: 0,
      icon: Icons.architecture,
    ),
    WeaponInfo(
      id: 'Crossbow',
      name: 'Crossbow',
      desc: 'Silent high-penetration steel bolts with piercing impact',
      unlockLevel: 2,
      price: 350,
      icon: Icons.arrow_right_alt,
    ),
    WeaponInfo(
      id: 'Battle Axe',
      name: 'Battle Axe',
      desc: 'Heavy cleaving melee sweep with lethal close-quarters arc',
      unlockLevel: 3,
      price: 400,
      icon: Icons.content_cut,
    ),
    WeaponInfo(
      id: 'Assault Rifle',
      name: 'Assault Rifle',
      desc: 'Automatic military carbine with rapid continuous fire',
      unlockLevel: 4,
      price: 500,
      icon: Icons.hardware,
    ),
    WeaponInfo(
      id: 'Shotgun',
      name: 'Shotgun',
      desc: 'Devastating 5-pellet spread blast for horde shredding',
      unlockLevel: 5,
      price: 750,
      icon: Icons.adjust,
    ),
    WeaponInfo(
      id: 'War Hammer',
      name: 'War Hammer',
      desc: 'Ground-shattering titan smash with massive AOE radius',
      unlockLevel: 6,
      price: 1000,
      icon: Icons.construction,
    ),
    WeaponInfo(
      id: 'Katana',
      name: 'Katana',
      desc: 'Razor-sharp samurai steel executing rapid slicing strikes',
      unlockLevel: 7,
      price: 1200,
      icon: Icons.sports_martial_arts,
    ),
    WeaponInfo(
      id: 'Fire Bow',
      name: 'Fire Bow',
      desc: '3x Damage blazing incendiary arrows that burn undead',
      unlockLevel: 8,
      price: 1500,
      icon: Icons.local_fire_department,
    ),
    WeaponInfo(
      id: 'Chainsaw',
      name: 'Chainsaw',
      desc: 'Motorized revolving teeth for continuous visceral slaughter',
      unlockLevel: 9,
      price: 1600,
      icon: Icons.hardware,
    ),
    WeaponInfo(
      id: 'AK-47',
      name: 'AK-47',
      desc: 'Legendary 7.62mm Assault Rifle. Heavy recoil, lethal damage.',
      unlockLevel: 10,
      price: 1800,
      icon: Icons.military_tech,
    ),
    WeaponInfo(
      id: 'Sniper Rifle',
      name: 'Sniper Rifle',
      desc: 'Extreme piercing velocity round that obliterates targets',
      unlockLevel: 12,
      price: 2000,
      icon: Icons.track_changes,
    ),
    WeaponInfo(
      id: 'Plasma Cannon',
      name: 'Plasma Cannon',
      desc: 'Superheated ion plasma bolts triggering energy detonations',
      unlockLevel: 15,
      price: 2500,
      icon: Icons.flash_on,
    ),
    WeaponInfo(
      id: 'Laser Gun',
      name: 'Laser Gun',
      desc: 'Continuous high-intensity particle beam of pure disintegration',
      unlockLevel: 18,
      price: 3000,
      icon: Icons.electric_bolt,
    ),
    WeaponInfo(
      id: 'Grenade Launcher',
      name: 'Grenade Launcher',
      desc: 'High-explosive 40mm fragmentation ordnance with brutal blast',
      unlockLevel: 22,
      price: 3500,
      icon: Icons.rocket_launch,
    ),
    WeaponInfo(
      id: 'Minigun',
      name: 'Minigun',
      desc: '6-barrel motorized rotary beast with blistering bullet storm',
      unlockLevel: 26,
      price: 4000,
      icon: Icons.filter_tilt_shift,
    ),
    WeaponInfo(
      id: 'Flamethrower',
      name: 'Flamethrower',
      desc: 'Torches hordes with continuous roaring stream of liquid napalm',
      unlockLevel: 30,
      price: 4500,
      icon: Icons.whatshot,
    ),
    WeaponInfo(
      id: 'Rocket Launcher',
      name: 'Rocket Launcher',
      desc: 'Guided high-caliber warhead unleashing catastrophic shockwaves',
      unlockLevel: 35,
      price: 5000,
      icon: Icons.rocket,
    ),
    WeaponInfo(
      id: 'Tesla Cannon',
      name: 'Tesla Cannon',
      desc: 'Discharges 1,000,000V arcs that chain through entire swarms',
      unlockLevel: 40,
      price: 5500,
      icon: Icons.offline_bolt,
    ),
  ];

  static WeaponInfo? getWeaponByName(String name) {
    for (final w in allWeapons) {
      if (w.name == name || w.id == name) return w;
    }
    return null;
  }

  static WeaponInfo? getWeaponUnlockedAtLevel(int level) {
    for (final w in allWeapons) {
      if (w.unlockLevel == level) return w;
    }
    return null;
  }

  static WeaponInfo? getNextWeaponToUnlock(int currentHighestLevel) {
    for (final w in allWeapons) {
      if (w.unlockLevel > currentHighestLevel) return w;
    }
    return null;
  }
}
