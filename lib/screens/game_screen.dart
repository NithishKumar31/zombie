import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/game_state_provider.dart';
import '../utils/app_theme.dart';
import '../utils/audio_service.dart';
import 'reward_screen.dart';
import 'shop_screen.dart';
import 'package:animate_do/animate_do.dart';

class Projectile {
  double x, y;
  double dx = 0;
  double dy = 0;
  String type;
  bool isPlayer;

  Projectile(
    this.x,
    this.y,
    double targetX,
    double targetY,
    this.type, {
    this.isPlayer = true,
  }) {
    double angle = atan2(targetY - y, targetX - x);
    double speed = type == 'arrow'
        ? 1200.0
        : (type == 'bullet'
              ? 2500.0
              : (type == 'sniper_bullet'
                  ? 4000.0
                  : (type == 'zombie_arrow'
                      ? 400.0
                      : (type == 'laser_beam'
                          ? 6000.0
                          : (type == 'grenade'
                              ? 800.0
                              : (type == 'acid_spit'
                                  ? 600.0
                                  : (type == 'crossbow_bolt'
                                      ? 2400.0
                                      : (type == 'minigun_bullet'
                                          ? 3200.0
                                          : (type == 'flame_stream'
                                              ? 950.0
                                              : (type == 'rpg_rocket'
                                                  ? 1300.0
                                                  : (type == 'tesla_arc'
                                                      ? 4500.0
                                                      : 1800.0)))))))))));
    if (type == 'pellet') {
      angle += (Random().nextDouble() - 0.5) * 0.4;
    }
    dx = cos(angle) * speed;
    dy = sin(angle) * speed;
  }
}

class Turret {
  double x, y;
  double lifeTimer = 10.0;
  double shootTimer = 0.0;
  double aimAngle = 0.0;
  Turret(this.x, this.y);
}

class BloodParticle {
  double x, y;
  double dx, dy;
  double life;
  double maxLife;
  double size;

  BloodParticle(this.x, this.y, this.dx, this.dy, this.life, this.size)
    : maxLife = life;
}

class Zombie {
  double x, y;
  double speed;

  int health = 3;
  int maxHealth = 3;
  double shootTimer = 0;
  double swingTimer = 0.0;
  double walkPhase = 0.0;
  bool isFacingLeft = true;
  bool isDying = false;
  double deathTimer = 1.0;
  String type;
  String weapon;
  late Color color;
  Zombie(this.x, this.y, this.speed, this.type, this.weapon) {
    if (type == 'runner') {
      health = 2;
      maxHealth = 2;
      this.speed = speed * 1.5;
      color = Colors.lightGreenAccent;
    } else if (type == 'tank') {
      health = 8;
      maxHealth = 8;
      this.speed = speed * 0.4;
      color = Colors.purpleAccent;
    } else if (type == 'boss') {
      health = 30;
      maxHealth = 30;
      this.speed = speed * 0.3;
      color = Colors.red;
    } else if (type == 'spitter') {
      health = 4;
      maxHealth = 4;
      this.speed = speed * 0.8;
      color = Colors.green;
    } else {
      health = 3;
      maxHealth = 3;
      color = Colors.primaries[Random().nextInt(Colors.primaries.length)];
    }
    shootTimer = 1.0 + Random().nextDouble() * 2.0;
  }
}

enum PowerUpType {
  medkit,
  shield,
  nuke,
  freeze,
  overcharge,
  scrapCrate,
}

class TacticalPowerUp {
  final String id;
  final PowerUpType type;
  double x;
  double y;
  double targetY;
  double parachuteY;
  bool isAirdrop;
  bool landed;
  double lifeTimer;
  double bouncePhase;

  TacticalPowerUp({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    this.targetY = 0,
    this.parachuteY = -60,
    this.isAirdrop = false,
    this.landed = true,
    this.lifeTimer = 18.0,
    this.bouncePhase = 0.0,
  });
}

class TacticalPickupNotification {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  double timer;

  TacticalPickupNotification({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.timer = 2.4,
  });
}

class _ParachuteLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(0, 0), Offset(size.width * 0.35, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width * 0.65, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.45, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.55, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GameScreen extends StatefulWidget {
  final int level;
  final bool isEndless;
  const GameScreen({super.key, required this.level, this.isEndless = false});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _gameLoop;
  DateTime _lastUpdate = DateTime.now();

  double _screenWidth = 0;
  double _screenHeight = 0;

  // Player State
  double _playerX = 0;
  double _playerY = 0;
  int _health = 100;
  Offset _joystickOffset = Offset.zero;
  final double _playerSpeed = 300.0;

  // Game Entities
  final List<Projectile> _projectiles = [];
  final List<Zombie> _zombies = [];
  final List<BloodParticle> _bloodParticles = [];
  final List<Turret> _turrets = [];

  // Progression
  int _kills = 0;
  late int _targetKills;
  bool _gameOver = false;
  bool _won = false;

  // Timers
  double _zombieSpawnTimer = 0;
  final Random _random = Random();

  // Animation State
  double _currentAimAngle = -pi / 2;
  double _targetAimAngle = -pi / 2;
  double _recoil = 0.0;

  // Firing State
  bool _isShooting = false;
  double _shootTimer = 0;
  Offset _aimTarget = Offset.zero;

  // Power-ups
  int _lightningPowerCount = 3;
  int _firePowerCount = 2;
  int _freezePowerCount = 2;
  int _turretPowerCount = 3;
  bool _showLightning = false;
  List<Offset> _lightningTargets = [];

  // Tactical Power-Ups & Airdrops System
  final List<TacticalPowerUp> _powerUps = [];
  TacticalPickupNotification? _activeNotification;
  double _airdropTimer = 16.0;
  double _shieldTimer = 0.0;
  double _overchargeTimer = 0.0;
  double _nukeFlashTimer = 0.0;
  String? _airdropInboundAlert;
  double _airdropAlertTimer = 0.0;

  // APEX-7 Combat Drone & Adrenaline Overdrive System
  double _overdriveCharge = 0.0; // 0.0 to 100.0%
  bool _isOverdriveActive = false;
  double _overdriveTimer = 0.0; // 15.0 seconds
  double _droneX = 0;
  double _droneY = 0;
  double _droneOrbitPhase = 0.0;
  double _droneShootTimer = 0.0;

  // Dynamic Killstreak Combo System
  int _comboCount = 0;
  double _comboTimer = 0.0;
  double _comboMultiplier = 1.0;
  String? _comboTitle;

  // Endless Survival Horde Mode State
  int _endlessWave = 1;
  int _endlessScore = 0;
  int _waveKills = 0;
  int _waveTargetKills = 15;
  bool _waveBannerVisible = false;
  double _waveBannerTimer = 0.0;

  // Dash & Freeze State
  bool _isDashing = false;
  double _dashTimer = 0;
  double _dashCooldown = 0;
  double _turretCooldown = 0;
  bool _isFrozen = false;
  double _freezeTimer = 0;
  double _survivalTime = 0;
  bool _isPaused = false;

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _gameLoop.stop();
      } else {
        _lastUpdate = DateTime.now();
        _gameLoop.forward();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _targetKills = widget.isEndless ? 15 : (10 + (widget.level * 5));
    if (widget.isEndless) {
      _waveTargetKills = 15;
      _endlessWave = 1;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final gameState = Provider.of<GameStateProvider>(context, listen: false);
        final missionWeapons = gameState.getWeaponsForMission(widget.level);
        if (!missionWeapons.contains(gameState.currentWeapon)) {
          gameState.equipWeapon(missionWeapons.isNotEmpty ? missionWeapons.last : 'Bow');
        }
      }
    });

    _gameLoop = AnimationController(
      vsync: this,
      duration: const Duration(days: 99),
    );
    _gameLoop.addListener(_update);
    _gameLoop.forward();
  }

  void _update() {
    final now = DateTime.now();
    final dt = now.difference(_lastUpdate).inMilliseconds / 1000.0;
    _lastUpdate = now;

    if (_gameOver || _won || _screenWidth == 0 || _isPaused) return;

    final gameState = Provider.of<GameStateProvider>(context, listen: false);
    final missionWeapons = gameState.getWeaponsForMission(widget.level);
    String currentWeapon = missionWeapons.contains(gameState.currentWeapon)
        ? gameState.currentWeapon
        : (missionWeapons.isNotEmpty ? missionWeapons.last : 'Bow');

    setState(() {
      if (!_gameOver && !_won) {
        _survivalTime += dt;
      }

      // Dynamic Combo Timer Countdown
      if (_comboTimer > 0) {
        _comboTimer -= dt;
        if (_comboTimer <= 0) {
          _comboCount = 0;
          _comboMultiplier = 1.0;
          _comboTitle = null;
        }
      }

      // Wave Clear Announcement Timer
      if (_waveBannerTimer > 0) {
        _waveBannerTimer -= dt;
        if (_waveBannerTimer <= 0) {
          _waveBannerVisible = false;
        }
      }

      // APEX-7 Combat Drone & Overdrive Logic
      if (_isOverdriveActive) {
        _overdriveTimer -= dt;
        if (_overdriveTimer <= 0) {
          _isOverdriveActive = false;
          _overdriveTimer = 0.0;
        }

        _droneOrbitPhase += dt * 3.4;
        double targetDroneX = _playerX + cos(_droneOrbitPhase) * 65.0;
        double targetDroneY = _playerY - 55.0 + sin(_droneOrbitPhase * 1.5) * 18.0;
        _droneX += (targetDroneX - _droneX) * 0.18;
        _droneY += (targetDroneY - _droneY) * 0.18;

        _droneShootTimer -= dt;
        if (_droneShootTimer <= 0) {
          _droneShootTimer = 0.28;
          Zombie? nearestTarget;
          double minDistance = 550.0;
          for (var z in _zombies) {
            if (z.isDying) continue;
            double dist = sqrt(pow(z.x - _droneX, 2) + pow(z.y - _droneY, 2));
            if (dist < minDistance) {
              minDistance = dist;
              nearestTarget = z;
            }
          }
          if (nearestTarget != null) {
            _projectiles.add(
              Projectile(_droneX - 12, _droneY, nearestTarget.x, nearestTarget.y, 'plasma_bolt', isPlayer: true),
            );
            _projectiles.add(
              Projectile(_droneX + 12, _droneY, nearestTarget.x, nearestTarget.y, 'plasma_bolt', isPlayer: true),
            );
            if (gameState.soundEnabled) {
              AudioService().playSoundEffect('lightning.wav');
            }
          }
        }
      }

      // Dash Logic
      if (_dashCooldown > 0) _dashCooldown -= dt;
      
      double speedMultiplier = _isOverdriveActive ? 1.25 : 1.0;
      if (_isDashing) {
        _dashTimer -= dt;
        if (_dashTimer > 0) {
           double dashAngle = atan2(_joystickOffset.dy, _joystickOffset.dx);
           if (_joystickOffset == Offset.zero) dashAngle = _currentAimAngle;
           _playerX += cos(dashAngle) * _playerSpeed * 2.5 * speedMultiplier * dt;
           _playerY += sin(dashAngle) * _playerSpeed * 2.5 * speedMultiplier * dt;
        } else {
           _isDashing = false;
        }
      } else {
        // 0. Move Player
        _playerX += _joystickOffset.dx * _playerSpeed * speedMultiplier * dt;
        _playerY += _joystickOffset.dy * _playerSpeed * speedMultiplier * dt;
      }

      // Freeze Logic
      if (_isFrozen) {
        _freezeTimer -= dt;
        if (_freezeTimer <= 0) _isFrozen = false;
      }

      if (_playerX < 40) _playerX = 40;
      if (_playerX > _screenWidth - 40) _playerX = _screenWidth - 40;
      if (_playerY < 40) _playerY = 40;
      if (_playerY > _screenHeight - 80) _playerY = _screenHeight - 80;

      if (_shootTimer > 0) {
        _shootTimer -= dt;
      }
      if (_shootTimer < 0) _shootTimer = 0;

      // 1. Fire Weapon if holding
      if (_isShooting && _shootTimer <= 0) {
        _fireWeapon(currentWeapon);
      }

      // Smoothly rotate aim towards target
      double diff = _targetAimAngle - _currentAimAngle;
      diff = (diff + pi) % (2 * pi) - pi;
      _currentAimAngle += diff * 15 * dt;

      // Decay recoil
      _recoil -= 5.0 * dt;
      if (_recoil < 0) _recoil = 0.0;

      // Tactical Timers Update
      if (_shieldTimer > 0) _shieldTimer -= dt;
      if (_overchargeTimer > 0) _overchargeTimer -= dt;
      if (_nukeFlashTimer > 0) _nukeFlashTimer -= dt;
      if (_airdropAlertTimer > 0) _airdropAlertTimer -= dt;
      if (_activeNotification != null) {
        _activeNotification!.timer -= dt;
        if (_activeNotification!.timer <= 0) {
          _activeNotification = null;
        }
      }

      // Tactical Airdrop Inbound Spawner
      _airdropTimer -= dt;
      if (_airdropTimer <= 0) {
        _airdropTimer = 22.0 + _random.nextDouble() * 10.0;
        _spawnTacticalAirdrop();
      }

      // Update Power-ups & Airdrops
      List<TacticalPowerUp> toRemovePowerUps = [];
      for (var pItem in _powerUps) {
        pItem.bouncePhase += dt * 3.5;
        if (!pItem.landed) {
          pItem.parachuteY += 135.0 * dt;
          pItem.y = pItem.parachuteY;
          if (pItem.parachuteY >= pItem.targetY) {
            pItem.parachuteY = pItem.targetY;
            pItem.y = pItem.targetY;
            pItem.landed = true;
          }
        } else {
          pItem.lifeTimer -= dt;
          if (pItem.lifeTimer <= 0) {
            toRemovePowerUps.add(pItem);
          }
        }

        // Check collection distance with Player
        double pDist = sqrt(pow(pItem.x - _playerX, 2) + pow(pItem.y - _playerY, 2));
        if (pDist <= 48.0) {
          _collectPowerUp(pItem, gameState);
          toRemovePowerUps.add(pItem);
        }
      }
      _powerUps.removeWhere((p) => toRemovePowerUps.contains(p));

      // Move Projectiles
      for (var p in _projectiles) {
        p.x += p.dx * dt;
        p.y += p.dy * dt;
      }
      _projectiles.removeWhere(
        (p) =>
            p.y < -50 ||
            p.y > _screenHeight + 50 ||
            p.x < -50 ||
            p.x > _screenWidth + 50,
      );

      // Move Blood Particles
      for (var bp in _bloodParticles) {
        bp.x += bp.dx * dt;
        bp.y += bp.dy * dt;
        bp.dy += 400 * dt; // gravity
        bp.life -= dt;
      }
      _bloodParticles.removeWhere((bp) => bp.life <= 0);

      if (_turretCooldown > 0) _turretCooldown -= dt;

      // Update Turrets
      for (var t in _turrets) {
        t.lifeTimer -= dt;
        t.shootTimer -= dt;
        
        if (t.shootTimer <= 0 && _zombies.isNotEmpty) {
          Zombie? closest;
          double closestDist = 1000000;
          for (var z in _zombies) {
            if (z.isDying) continue;
            double d = (z.x - t.x) * (z.x - t.x) + (z.y - t.y) * (z.y - t.y);
            if (d < closestDist) {
              closestDist = d;
              closest = z;
            }
          }
          if (closest != null && closestDist < 250000) { // range ~500
            t.aimAngle = atan2(closest.y - 10 - t.y, closest.x - t.x);
            _projectiles.add(Projectile(
              t.x, t.y, closest.x, closest.y - 10, 'turret_bullet',
            ));
            t.shootTimer = 0.3; // Turret fire rate
          }
        }
      }
      _turrets.removeWhere((t) => t.lifeTimer <= 0);

      List<Zombie> zombiesToRemove = [];
      // 2. Move Zombies and Shoot
      for (var zombie in _zombies) {
        if (_isFrozen && !zombie.isDying) continue;
        if (zombie.isDying) {
          zombie.deathTimer -= dt;

          // Drip blood slowly
          if (_random.nextDouble() > 0.6) {
            _bloodParticles.add(
              BloodParticle(
                zombie.x + (_random.nextDouble() - 0.5) * 20,
                zombie.y + (_random.nextDouble() - 0.5) * 40,
                (_random.nextDouble() - 0.5) * 30,
                (_random.nextDouble() - 0.5) * 30 + 50,
                0.3 + _random.nextDouble() * 0.5,
                2.0 + _random.nextDouble() * 3.0,
              ),
            );
          }

          if (zombie.deathTimer <= 0) {
            zombiesToRemove.add(zombie);

            // 1. Combo streak tracking
            _comboCount++;
            _comboTimer = 2.8;
            if (_comboCount >= 15) {
              _comboMultiplier = 3.0;
              _comboTitle = 'GODLIKE // APOCALYPSE';
            } else if (_comboCount >= 10) {
              _comboMultiplier = 2.5;
              _comboTitle = 'UNSTOPPABLE STREAK';
            } else if (_comboCount >= 7) {
              _comboMultiplier = 2.0;
              _comboTitle = 'RAMPAGE';
            } else if (_comboCount >= 4) {
              _comboMultiplier = 1.5;
              _comboTitle = 'MULTI KILL';
            } else if (_comboCount >= 2) {
              _comboMultiplier = 1.2;
              _comboTitle = 'DOUBLE KILL';
            }

            // 2. Charge Adrenaline Overdrive
            if (!_isOverdriveActive) {
              double chargeGain = zombie.type == 'boss'
                  ? 35.0
                  : (zombie.type == 'tank' ? 15.0 : (zombie.type == 'runner' ? 6.0 : 4.0));
              _overdriveCharge = (_overdriveCharge + chargeGain).clamp(0.0, 100.0);
            }

            // 3. Coins reward with Overdrive & Combo multiplier
            int baseCoins = 1;
            if (_isOverdriveActive) baseCoins *= 2;
            int finalCoins = (baseCoins * _comboMultiplier).ceil();
            gameState.addCoins(finalCoins);

            _maybeDropPowerUp(zombie.x, zombie.y, zombie.type);

            if (widget.isEndless) {
              _kills++;
              _endlessScore += (100 * _comboMultiplier).toInt();
              _waveKills++;
              if (_waveKills >= _waveTargetKills) {
                // Advance to next wave!
                _endlessWave++;
                _waveKills = 0;
                _waveTargetKills = 15 + (_endlessWave * 8);
                _health = (_health + 30).clamp(0, 100);
                _waveBannerVisible = true;
                _waveBannerTimer = 3.5;
                _spawnTacticalAirdrop();
                gameState.recordEndlessWave(_endlessWave, _endlessScore);
                if (gameState.soundEnabled) {
                  AudioService().playSoundEffect('freeze.wav');
                }
              }
            } else {
              _kills++;
              if (_kills >= _targetKills) {
                _won = true;
                _gameLoop.stop();
                _winLevel();
              }
            }
          }
          continue;
        }

        if (zombie.swingTimer > 0) {
          zombie.swingTimer -= dt;
        }

        zombie.isFacingLeft = _playerX < zombie.x;

        double dist = sqrt(
          pow(_playerY - zombie.y, 2) + pow(_playerX - zombie.x, 2),
        );
        double attackRange = (zombie.weapon == 'bow' || zombie.weapon == 'acid') ? 300.0 : 60.0;

        if (dist > attackRange) {
          double angle = atan2(_playerY - zombie.y, _playerX - zombie.x);
          zombie.x += cos(angle) * zombie.speed * dt;
          zombie.y += sin(angle) * zombie.speed * dt;
          zombie.walkPhase += dt * 10;
        }

        zombie.shootTimer -= dt;
        if (zombie.shootTimer <= 0) {
          zombie.shootTimer = 2.0 + _random.nextDouble();
          if (zombie.weapon == 'bow') {
            if (dist <= 350) {
              _projectiles.add(
                Projectile(
                  zombie.x,
                  zombie.y,
                  _playerX,
                  _playerY - 50,
                  'zombie_arrow',
                  isPlayer: false,
                ),
              );
            }
          } else if (zombie.weapon == 'acid') {
            if (dist <= 300) {
              _projectiles.add(
                Projectile(
                  zombie.x,
                  zombie.y,
                  _playerX,
                  _playerY - 50,
                  'acid_spit',
                  isPlayer: false,
                ),
              );
            }
          } else {
            if (dist <= attackRange + 20) {
              zombie.swingTimer = 0.3; // Swing animation duration
              if (_shieldTimer > 0) {
                // Forcefield Shield deflects all melee damage!
                for (int i = 0; i < 4; i++) {
                  _bloodParticles.add(
                    BloodParticle(
                      _playerX,
                      _playerY - 20,
                      (_random.nextDouble() - 0.5) * 140,
                      (_random.nextDouble() - 0.5) * 140,
                      0.3,
                      2.5,
                    ),
                  );
                }
              } else {
                _health -= (zombie.weapon == 'axe' || zombie.weapon == 'sword')
                    ? 10
                    : 5;
                if (_health <= 0) {
                  _health = 0;
                  _gameOver = true;
                  _gameLoop.stop();
                  if (widget.isEndless) {
                    gameState.recordEndlessWave(_endlessWave, _endlessScore);
                  }
                }
              }
            }
          }
        }
      }

      // 3. Collision Detection (Projectiles)
      List<Projectile> projectilesToRemove = [];

      for (var p in _projectiles) {
        if (!p.isPlayer) {
          double pLeft = _playerX - 30;
          double pRight = _playerX + 30;
          double pTop = _playerY - 80;
          double pBottom = _playerY + 20;

          if (p.x >= pLeft && p.x <= pRight && p.y >= pTop && p.y <= pBottom) {
            projectilesToRemove.add(p);
            if (_shieldTimer > 0) {
              // Forcefield Shield deflects projectile!
              for (int i = 0; i < 4; i++) {
                _bloodParticles.add(
                  BloodParticle(
                    _playerX,
                    _playerY - 20,
                    (_random.nextDouble() - 0.5) * 140,
                    (_random.nextDouble() - 0.5) * 140,
                    0.3,
                    2.5,
                  ),
                );
              }
            } else {
              _health -= p.type == 'acid_spit' ? 10 : 5;
              if (_health <= 0) {
                _health = 0;
                _gameOver = true;
                _gameLoop.stop();
              }
            }
          }
          continue;
        }

        for (var zombie in _zombies) {
          if (zombie.isDying) continue;
          if (zombiesToRemove.contains(zombie)) continue;

          double zLeft = zombie.x - 25;
          double zRight = zombie.x + 25;
          double zTop = zombie.y - 40;
          double zBottom = zombie.y + 40;
          double zNeck = zombie.y - 10;

          if (p.x >= zLeft && p.x <= zRight && p.y >= zTop && p.y <= zBottom) {
            projectilesToRemove.add(p);

            int damage = 1;
            int headshotDamage = 3;
            switch (p.type) {
              case 'fire_arrow':
                damage = 3; headshotDamage = 10; break;
              case 'crossbow_bolt':
                damage = 18; headshotDamage = 45; break;
              case 'sniper_bullet':
                damage = 15; headshotDamage = 35; break;
              case 'plasma_bolt':
                damage = 8; headshotDamage = 18; break;
              case 'ak47_bullet':
                damage = 5; headshotDamage = 20; break;
              case 'minigun_bullet':
                damage = 4; headshotDamage = 10; break;
              case 'flame_stream':
                damage = 6; headshotDamage = 12; break;
              case 'turret_bullet':
                damage = 4; headshotDamage = 8; break;
              case 'laser_beam':
                damage = 7; headshotDamage = 14; break;
              case 'grenade':
                damage = 25; headshotDamage = 50; break;
              case 'rpg_rocket':
                damage = 65; headshotDamage = 120; break;
              case 'tesla_arc':
                damage = 18; headshotDamage = 36; break;
              case 'pellet':
                damage = 1; headshotDamage = 2; break;
              default:
                damage = 1; headshotDamage = 3;
            }

            if (_overchargeTimer > 0) {
              damage = (damage * 2.2).toInt();
              headshotDamage = (headshotDamage * 2.2).toInt();
            }

            if (p.y < zNeck) {
              zombie.health -= headshotDamage;
            } else {
              zombie.health -= damage;
            }

            if (p.type == 'grenade' || p.type == 'rpg_rocket') {
              double blastRadius = p.type == 'rpg_rocket' ? 220.0 : 150.0;
              int aoeDamage = p.type == 'rpg_rocket' ? 45 : 15;
              for (var otherZ in _zombies) {
                if (otherZ.isDying || otherZ == zombie) continue;
                double dist = sqrt(pow(otherZ.x - p.x, 2) + pow(otherZ.y - p.y, 2));
                if (dist <= blastRadius) {
                  otherZ.health -= aoeDamage;
                  if (otherZ.health <= 0) {
                     otherZ.health = 0;
                     otherZ.isDying = true;
                     for (int i = 0; i < 12; i++) {
                       _bloodParticles.add(
                         BloodParticle(
                           otherZ.x, otherZ.y,
                           (_random.nextDouble() - 0.5) * 240,
                           (_random.nextDouble() - 0.5) * 240 - 50,
                           0.5 + _random.nextDouble(),
                           3.0 + _random.nextDouble() * 5.0,
                         ),
                       );
                     }
                  }
                }
              }
            } else if (p.type == 'tesla_arc') {
              var nearby = _zombies.where((z) => !z.isDying && z != zombie).toList();
              nearby.sort((a, b) => (pow(a.x - p.x, 2) + pow(a.y - p.y, 2)).compareTo(pow(b.x - p.x, 2) + pow(b.y - p.y, 2)));
              for (var target in nearby.take(2)) {
                double d = sqrt(pow(target.x - p.x, 2) + pow(target.y - p.y, 2));
                if (d <= 200) {
                  target.health -= 12;
                  if (target.health <= 0) {
                    target.health = 0;
                    target.isDying = true;
                  }
                }
              }
            }

            if (zombie.health <= 0) {
              zombie.health = 0;
              zombie.isDying = true;

              // Initial blood splatter
              for (int i = 0; i < 15; i++) {
                _bloodParticles.add(
                  BloodParticle(
                    zombie.x,
                    zombie.y - 10,
                    (_random.nextDouble() - 0.5) * 200,
                    (_random.nextDouble() - 0.5) * 200 - 50,
                    0.5 + _random.nextDouble(),
                    3.0 + _random.nextDouble() * 4.0,
                  ),
                );
              }
            }
          }
        }
      }

      _projectiles.removeWhere((p) => projectilesToRemove.contains(p));
      _zombies.removeWhere((z) => zombiesToRemove.contains(z));

      // 5. Spawn Zombies
      _zombieSpawnTimer += dt;
      double spawnRate = max(0.4, 2.0 - (widget.level * 0.15));
      if (_zombieSpawnTimer > spawnRate) {
        _zombieSpawnTimer = 0;
        _spawnZombie();
      }
    });
  }

  void _spawnZombie() {
    double speed = 80 + _random.nextDouble() * 40 + (widget.level * 5);
    int edge = _random.nextInt(3);
    double x = 0, y = 0;
    if (edge == 0) {
      x = _random.nextDouble() * _screenWidth;
      y = -50;
    } else if (edge == 1) {
      x = -50;
      y = _random.nextDouble() * _screenHeight;
    } else {
      x = _screenWidth + 50;
      y = _random.nextDouble() * _screenHeight;
    }

    int typeChance = _random.nextInt(100);
    String type = 'normal';
    String weapon = 'bow';
    if (typeChance > 95 && widget.level > 2) {
      type = 'boss';
      weapon = 'hammer';
    } else if (typeChance > 80) {
      type = 'spitter';
      weapon = 'acid';
    } else if (typeChance > 60) {
      type = 'tank';
      weapon = _random.nextBool() ? 'sword' : 'axe';
    } else if (typeChance > 40) {
      type = 'runner';
      weapon = 'knife';
    } else {
      weapon = _random.nextBool() ? 'bow' : 'axe';
    }
    _zombies.add(Zombie(x, y, speed, type, weapon));
  }

  void _fireWeapon(String weapon) {
    double shoulderX = _playerX;
    double shoulderY = _playerY - 5;

    _targetAimAngle = atan2(
      _aimTarget.dy - shoulderY,
      _aimTarget.dx - shoulderX,
    );
    _recoil = 1.0;

    if (weapon == 'Bow') {
      _projectiles.add(
        Projectile(shoulderX, shoulderY, _aimTarget.dx, _aimTarget.dy, 'arrow'),
      );
      if (Provider.of<GameStateProvider>(context, listen: false).soundEnabled) {
        AudioService().playSoundEffect('arrow.wav');
      }
      _shootTimer = 0.6;
    } else if (weapon == 'Fire Bow') {
      _projectiles.add(
        Projectile(
          shoulderX,
          shoulderY,
          _aimTarget.dx,
          _aimTarget.dy,
          'fire_arrow',
        ),
      );
      _shootTimer = 0.6;
    } else if (weapon == 'Assault Rifle') {
      _projectiles.add(
        Projectile(
          shoulderX,
          shoulderY,
          _aimTarget.dx,
          _aimTarget.dy,
          'bullet',
        ),
      );
      _shootTimer = 0.1;
    } else if (weapon == 'Shotgun') {
      for (int i = 0; i < 5; i++) {
        _projectiles.add(
          Projectile(
            shoulderX,
            shoulderY,
            _aimTarget.dx,
            _aimTarget.dy,
            'pellet',
          ),
        );
      }
      _isShooting = false;
    } else if (weapon == 'Battle Axe') {
      _performMeleeAttack(shoulderX, shoulderY, 150.0, 3, false);
      _isShooting = false;
    } else if (weapon == 'War Hammer') {
      _performMeleeAttack(shoulderX, shoulderY, 200.0, 10, true);
      _isShooting = false;
    } else if (weapon == 'Katana') {
      _performMeleeAttack(shoulderX, shoulderY, 180.0, 5, true);
      _isShooting = false;
    } else if (weapon == 'Sniper Rifle') {
      _projectiles.add(
        Projectile(
          shoulderX,
          shoulderY,
          _aimTarget.dx,
          _aimTarget.dy,
          'sniper_bullet',
        ),
      );
      _shootTimer = 1.2;
    } else if (weapon == 'Plasma Cannon') {
      _projectiles.add(
        Projectile(
          shoulderX,
          shoulderY,
          _aimTarget.dx,
          _aimTarget.dy,
          'plasma_bolt',
        ),
      );
      _shootTimer = 0.2;
    } else if (weapon == 'AK-47') {
      _projectiles.add(
        Projectile(
          shoulderX,
          shoulderY,
          _aimTarget.dx,
          _aimTarget.dy,
          'ak47_bullet',
        ),
      );
      _shootTimer = 0.08;
    } else if (weapon == 'Laser Gun') {
      _projectiles.add(
        Projectile(
          shoulderX,
          shoulderY,
          _aimTarget.dx,
          _aimTarget.dy,
          'laser_beam',
        ),
      );
      _shootTimer = 0.05;
    } else if (weapon == 'Grenade Launcher') {
      _projectiles.add(
        Projectile(
          shoulderX,
          shoulderY,
          _aimTarget.dx,
          _aimTarget.dy,
          'grenade',
        ),
      );
      _shootTimer = 1.5;
    } else if (weapon == 'Crossbow') {
      _projectiles.add(
        Projectile(
          shoulderX,
          shoulderY,
          _aimTarget.dx,
          _aimTarget.dy,
          'crossbow_bolt',
        ),
      );
      if (Provider.of<GameStateProvider>(context, listen: false).soundEnabled) {
        AudioService().playSoundEffect('arrow.wav');
      }
      _shootTimer = 0.45;
    } else if (weapon == 'Chainsaw') {
      _performMeleeAttack(shoulderX, shoulderY, 140.0, 7, true);
      _shootTimer = 0.08;
    } else if (weapon == 'Minigun') {
      double spreadAngle = (_random.nextDouble() - 0.5) * 0.14;
      double dist = sqrt(pow(_aimTarget.dx - shoulderX, 2) + pow(_aimTarget.dy - shoulderY, 2));
      double baseAngle = atan2(_aimTarget.dy - shoulderY, _aimTarget.dx - shoulderX);
      double targetX = shoulderX + cos(baseAngle + spreadAngle) * dist;
      double targetY = shoulderY + sin(baseAngle + spreadAngle) * dist;
      _projectiles.add(
        Projectile(
          shoulderX,
          shoulderY,
          targetX,
          targetY,
          'minigun_bullet',
        ),
      );
      _shootTimer = 0.04;
    } else if (weapon == 'Flamethrower') {
      for (int i = 0; i < 2; i++) {
        double spreadAngle = (_random.nextDouble() - 0.5) * 0.28;
        double dist = sqrt(pow(_aimTarget.dx - shoulderX, 2) + pow(_aimTarget.dy - shoulderY, 2));
        double baseAngle = atan2(_aimTarget.dy - shoulderY, _aimTarget.dx - shoulderX);
        double targetX = shoulderX + cos(baseAngle + spreadAngle) * dist;
        double targetY = shoulderY + sin(baseAngle + spreadAngle) * dist;
        _projectiles.add(
          Projectile(
            shoulderX,
            shoulderY,
            targetX,
            targetY,
            'flame_stream',
          ),
        );
      }
      _shootTimer = 0.06;
    } else if (weapon == 'Rocket Launcher') {
      _projectiles.add(
        Projectile(
          shoulderX,
          shoulderY,
          _aimTarget.dx,
          _aimTarget.dy,
          'rpg_rocket',
        ),
      );
      _shootTimer = 1.4;
    } else if (weapon == 'Tesla Cannon') {
      _projectiles.add(
        Projectile(
          shoulderX,
          shoulderY,
          _aimTarget.dx,
          _aimTarget.dy,
          'tesla_arc',
        ),
      );
      if (Provider.of<GameStateProvider>(context, listen: false).soundEnabled) {
        AudioService().playSoundEffect('lightning.wav');
      }
      _shootTimer = 0.22;
    }
      if (_overchargeTimer > 0) {
      _shootTimer *= 0.45;
    }
  }

  void _performMeleeAttack(
    double px,
    double py,
    double range,
    int damage,
    bool isAoe,
  ) {
    List<Zombie> zombiesHit = [];
    for (var z in _zombies) {
      if (z.isDying) continue;
      double dist = sqrt(pow(z.x - px, 2) + pow(z.y - py, 2));
      if (dist <= range) {
        zombiesHit.add(z);
      }
    }

    if (zombiesHit.isNotEmpty) {
      if (!isAoe) {
        zombiesHit.sort(
          (a, b) => sqrt(
            pow(a.x - px, 2) + pow(a.y - py, 2),
          ).compareTo(sqrt(pow(b.x - px, 2) + pow(b.y - py, 2))),
        );
        zombiesHit = [zombiesHit.first];
      }

      int effectiveDamage = _overchargeTimer > 0 ? (damage * 2.2).toInt() : damage;
      for (var z in zombiesHit) {
        z.health -= effectiveDamage;
        if (z.health <= 0) {
          z.health = 0;
          z.isDying = true;

          for (int i = 0; i < 15; i++) {
            _bloodParticles.add(
              BloodParticle(
                z.x,
                z.y,
                (_random.nextDouble() - 0.5) * 200,
                (_random.nextDouble() - 0.5) * 200 - 50,
                0.5 + _random.nextDouble(),
                3.0 + _random.nextDouble() * 4.0,
              ),
            );
          }
        }
      }
    }
  }

  void _handlePanDown(DragDownDetails details) {
    if (_gameOver || _won) return;
    _isShooting = true;
    _aimTarget = details.localPosition;
    _shootTimer = 0;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_gameOver || _won) return;
    _aimTarget = details.localPosition;
    double shoulderX = _playerX;
    double shoulderY = _playerY - 5;
    _targetAimAngle = atan2(
      _aimTarget.dy - shoulderY,
      _aimTarget.dx - shoulderX,
    );
  }

  void _handlePanEnd(DragEndDetails details) {
    _isShooting = false;
  }

  void _winLevel() {
    int coinsEarned = 150 + (widget.level * 10);
    int xpEarned = 500 + (widget.level * 50);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RewardScreen(
              level: widget.level,
              coinsEarned: coinsEarned,
              xpEarned: xpEarned,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _gameLoop.dispose();
    super.dispose();
  }

  void _useOverdrive() {
    if (_overdriveCharge >= 100.0 && !_isOverdriveActive && !_gameOver && !_won) {
      setState(() {
        _isOverdriveActive = true;
        _overdriveTimer = 15.0;
        _overdriveCharge = 0.0;
        _droneX = _playerX;
        _droneY = _playerY - 80.0;
        _activeNotification = TacticalPickupNotification(
          title: 'APEX-7 COMBAT DRONE ONLINE',
          subtitle: 'AUTONOMOUS PLASMA AIR SUPPORT ENGAGED // +25% SPEED',
          icon: Icons.rocket_launch_rounded,
          color: const Color(0xFF00E5FF),
          timer: 3.0,
        );
      });
      final gs = Provider.of<GameStateProvider>(context, listen: false);
      if (gs.soundEnabled) {
        AudioService().playSoundEffect('lightning.wav');
      }
    }
  }

  void _useLightningPower() {
    if (_lightningPowerCount > 0 &&
        !_gameOver &&
        !_won &&
        _zombies.isNotEmpty) {
      if (Provider.of<GameStateProvider>(context, listen: false).soundEnabled) {
        AudioService().playSoundEffect('lightning.wav');
      }
      setState(() {
        _lightningPowerCount--;
        _showLightning = true;
        _lightningTargets.clear();

        List<Zombie> sortedZombies = _zombies.where((z) => !z.isDying).toList();
        sortedZombies.sort(
          (a, b) => (pow(a.x - _playerX, 2) + pow(a.y - _playerY, 2)).compareTo(
            pow(b.x - _playerX, 2) + pow(b.y - _playerY, 2),
          ),
        );

        int count = min(3, sortedZombies.length);
        for (int i = 0; i < count; i++) {
          _lightningTargets.add(Offset(sortedZombies[i].x, sortedZombies[i].y));
          sortedZombies[i].health = 0;
          sortedZombies[i].isDying = true;
          for (int j = 0; j < 15; j++) {
            _bloodParticles.add(
              BloodParticle(
                sortedZombies[i].x,
                sortedZombies[i].y,
                (_random.nextDouble() - 0.5) * 200,
                (_random.nextDouble() - 0.5) * 200 - 50,
                0.5 + _random.nextDouble(),
                3.0 + _random.nextDouble() * 4.0,
              ),
            );
          }
        }
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _showLightning = false);
      });
    }
  }

  void _useFreezePower() {
    if (_freezePowerCount > 0 && !_gameOver && !_won) {
      if (Provider.of<GameStateProvider>(context, listen: false).soundEnabled) {
        AudioService().playSoundEffect('freeze.wav');
      }
      setState(() {
        _freezePowerCount--;
        _isFrozen = true;
        _freezeTimer = 5.0; // Freeze for 5 seconds
      });
    }
  }

  void _useDash() {
    if (_dashCooldown <= 0 && !_gameOver && !_won) {
      setState(() {
        _isDashing = true;
        _dashTimer = 0.2; // Dash duration
        _dashCooldown = 2.0; // Dash cooldown
      });
    }
  }

  void _deployTurret() {
    if (_turretPowerCount > 0 && _turretCooldown <= 0 && !_gameOver && !_won) {
      setState(() {
        _turretPowerCount--;
        _turretCooldown = 15.0; // 15 seconds cooldown
        _turrets.add(Turret(_playerX, _playerY + 20));
      });
    }
  }

  void _useFirePower() {
    if (_firePowerCount > 0 && !_gameOver && !_won) {
      setState(() {
        _firePowerCount--;
        for (var z in _zombies.toList()) {
          if (z.isDying) continue;
          double dist = sqrt(pow(z.x - _playerX, 2) + pow(z.y - _playerY, 2));
          if (dist <= 250) {
            z.health = 0;
            z.isDying = true;
            for (int i = 0; i < 15; i++) {
              _bloodParticles.add(
                BloodParticle(
                  z.x,
                  z.y,
                  (_random.nextDouble() - 0.5) * 200,
                  (_random.nextDouble() - 0.5) * 200 - 50,
                  0.5 + _random.nextDouble(),
                  3.0 + _random.nextDouble() * 4.0,
                ),
              );
            }
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_screenWidth == 0) {
            _screenWidth = constraints.maxWidth;
            _screenHeight = constraints.maxHeight;
            _playerX = _screenWidth / 2;
            _playerY = _screenHeight - 100;
          }

          final gameState = context.watch<GameStateProvider>();
          final currentWeapon = gameState.currentWeapon;

          return Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.keyF ||
                    event.logicalKey == LogicalKeyboardKey.keyR) {
                  _useOverdrive();
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.keyQ ||
                    event.logicalKey == LogicalKeyboardKey.keyE ||
                    event.logicalKey == LogicalKeyboardKey.tab) {
                  _cycleWeapon(gameState, 1);
                  return KeyEventResult.handled;
                }
                final keyDigits = [
                  LogicalKeyboardKey.digit1,
                  LogicalKeyboardKey.digit2,
                  LogicalKeyboardKey.digit3,
                  LogicalKeyboardKey.digit4,
                  LogicalKeyboardKey.digit5,
                  LogicalKeyboardKey.digit6,
                  LogicalKeyboardKey.digit7,
                  LogicalKeyboardKey.digit8,
                  LogicalKeyboardKey.digit9,
                ];
                int digitIdx = keyDigits.indexOf(event.logicalKey);
                if (digitIdx != -1) {
                  _selectWeaponByIndex(gameState, digitIdx);
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: _handlePanDown,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            onPanCancel: () => _isShooting = false,
            child: Stack(
              children: [
                // 1. Gritty Apocalyptic Ground Wallpaper
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/spooky_bg.png',
                    fit: BoxFit.cover,
                  ),
                ),
                // 2. Heavy Apocalyptic Radial Vignette & Atmospheric Grading
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.15,
                        colors: [
                          const Color(0xFF0F1218).withOpacity(0.72),
                          const Color(0xFF08090C).withOpacity(0.92),
                          Colors.black.withOpacity(0.98),
                        ],
                        stops: const [0.2, 0.75, 1.0],
                      ),
                    ),
                  ),
                ),
                // 3. Tactical Battlefield Combat Grid & Hazard Markers
                Positioned.fill(
                  child: CustomPaint(
                    painter: BattlefieldArenaPainter(),
                  ),
                ),

                ..._projectiles.map((p) {
                  double angle = atan2(p.dy, p.dx);
                  return Positioned(
                    left: p.x - 16,
                    top: p.y - 16,
                    child: Transform.rotate(
                      angle: angle,
                      child: _buildProjectileWidget(p),
                    ),
                  );
                }),

                ..._bloodParticles.map(
                  (bp) => Positioned(
                    left: bp.x,
                    top: bp.y,
                    child: Container(
                      width: bp.size,
                      height: bp.size,
                      decoration: BoxDecoration(
                        color: AppTheme.dangerColor.withValues(alpha: bp.life / bp.maxLife),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.dangerColor.withValues(alpha: 0.5 * (bp.life / bp.maxLife)),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                ..._turrets.map(
                  (t) => Positioned(
                    left: t.x - 20,
                    top: t.y - 20,
                    child: Transform.rotate(
                      angle: t.aimAngle,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.cyanAccent, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.cyanAccent, blurRadius: 10),
                          ],
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 20,
                            height: 6,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                ..._zombies.map(
                  (z) => Positioned(
                    left: z.x - 25,
                    top: z.y - 40,
                    child: Transform.scale(
                      scaleX: z.isFacingLeft ? 1 : -1,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 50,
                        height: 80,
                        child: CustomPaint(
                          painter: ZombiePainter(
                            z.health,
                            z.maxHealth,
                            z.color,
                            z.type,
                            z.weapon,
                            z.swingTimer,
                            z.walkPhase,
                            z.isDying,
                            _isFrozen,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Tactical Power-ups & Airdrops on Battlefield
                ..._powerUps.map((p) => _buildPowerUpWidget(p)),

                Positioned(
                  left: _playerX - 40,
                  top: _playerY - 40,
                  child: SizedBox(
                    width: 80,
                    height: 100,
                    child: CustomPaint(
                      painter: PlayerPainter(
                        aimAngle: _currentAimAngle,
                        recoil: _recoil,
                        weapon: currentWeapon,
                        shootTimer: _shootTimer,
                      ),
                    ),
                  ),
                ),

                // Forcefield Shield Bubble around player
                if (_shieldTimer > 0)
                  Positioned(
                    left: _playerX - 55,
                    top: _playerY - 55,
                    child: IgnorePointer(
                      child: _buildPlayerShieldBubble(),
                    ),
                  ),

                // Overdrive Energy Field
                if (_isOverdriveActive)
                  Positioned(
                    left: _playerX - 60,
                    top: _playerY - 60,
                    child: IgnorePointer(
                      child: _buildOverdriveEnergyAura(),
                    ),
                  ),

                // APEX-7 Combat Drone
                if (_isOverdriveActive)
                  Positioned(
                    left: _droneX - 28,
                    top: _droneY - 28,
                    child: _buildApexCombatDrone(),
                  ),

                // Weapon Overcharge Electrical Aura around player
                if (_overchargeTimer > 0)
                  Positioned(
                    left: _playerX - 50,
                    top: _playerY - 50,
                    child: IgnorePointer(
                      child: _buildPlayerOverchargeAura(),
                    ),
                  ),

                // Movement Controls
                Positioned(
                  left: 30,
                  bottom: 30,
                  child: VirtualJoystick(
                    onMove: (offset) {
                      _joystickOffset = offset;
                    },
                    onEnd: () {
                      _joystickOffset = Offset.zero;
                    },
                  ),
                ),

                // Low-Health Pulsing Crimson Vignette
                if (_health <= 35 && !_gameOver)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: LowHealthVignettePainter(health: _health),
                      ),
                    ),
                  ),

                // Frozen Atmosphere Effect
                if (_isFrozen)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.0,
                            colors: [
                              Colors.cyanAccent.withOpacity(0.04),
                              Colors.cyanAccent.withOpacity(0.22),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.4),
                            width: 6,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Tactical Nuclear Shockwave Flash
                if (_nukeFlashTimer > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.white.withOpacity((_nukeFlashTimer / 0.6).clamp(0.0, 0.95)),
                      ),
                    ),
                  ),

                // Inbound Airdrop Siren Alert Banner
                if (_airdropAlertTimer > 0 && _airdropInboundAlert != null)
                  Positioned(
                    top: 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _buildAirdropAlertBanner(),
                    ),
                  ),

                // Active Floating Tactical Pickup Banner
                if (_activeNotification != null)
                  Positioned(
                    top: 130,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _buildNotificationBanner(),
                    ),
                  ),

                // Dynamic Killstreak Combo Banner
                if (_comboCount >= 2 && _comboTitle != null)
                  Positioned(
                    top: 85,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _buildComboBanner(),
                    ),
                  ),

                // Wave Clear Announcement Banner
                if (_waveBannerVisible)
                  Positioned(
                    top: 140,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _buildWaveClearedBanner(),
                    ),
                  ),

                if (_showLightning)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: LightningSkillPainter(
                        playerX: _playerX,
                        playerY: _playerY,
                        targets: _lightningTargets,
                      ),
                    ),
                  ),

                if (_gameOver)
                  Positioned.fill(
                    child: FadeIn(
                      duration: const Duration(milliseconds: 600),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 1.25,
                              colors: [
                                const Color(0xFF38070D).withOpacity(0.92),
                                const Color(0xFF160408).withOpacity(0.96),
                                const Color(0xFF070103).withOpacity(0.99),
                              ],
                              stops: const [0.1, 0.65, 1.0],
                            ),
                          ),
                          child: Stack(
                            children: [
                              // 1. Subtle Spooky Background Overlay with safe errorBuilder
                              Positioned.fill(
                                child: Opacity(
                                  opacity: 0.16,
                                  child: Image.asset(
                                    'assets/images/spooky_bg.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                  ),
                                ),
                              ),

                              // 2. Rising Crimson Ash / Ember Particles
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: CrimsonAshEmbersPainter(),
                                ),
                              ),

                              // 3. Main Center Modal Content
                              Center(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 680),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Sector Hazard Alert Pill
                                        FadeInDown(
                                          duration: const Duration(milliseconds: 400),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1F080C).withOpacity(0.85),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: const Color(0xFFFF1744).withOpacity(0.6),
                                                width: 1.2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFFF1744).withOpacity(0.25),
                                                  blurRadius: 12,
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Color(0xFFFF5252),
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'SECTOR 0${widget.level} // RECON MISSION COMPROMISED',
                                                  style: GoogleFonts.shareTechMono(
                                                    color: const Color(0xFFFF8A80),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 2.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        // Animated Glowing Skull Crest
                                        ZoomIn(
                                          duration: const Duration(milliseconds: 600),
                                          child: Pulse(
                                            infinite: true,
                                            duration: const Duration(milliseconds: 2200),
                                            child: Container(
                                              width: 100,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: const RadialGradient(
                                                  colors: [
                                                    Color(0xFF4A0812),
                                                    Color(0xFF1F0408),
                                                  ],
                                                ),
                                                border: Border.all(
                                                  color: const Color(0xFFFF1744),
                                                  width: 2.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFFFF1744).withOpacity(0.55),
                                                    blurRadius: 40,
                                                    spreadRadius: 8,
                                                  ),
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.8),
                                                    blurRadius: 20,
                                                  ),
                                                ],
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  '💀',
                                                  style: TextStyle(fontSize: 52),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // "YOU DIED" Title
                                        FadeInDown(
                                          delay: const Duration(milliseconds: 200),
                                          duration: const Duration(milliseconds: 600),
                                          child: Column(
                                            children: [
                                              Text(
                                                'YOU DIED',
                                                style: GoogleFonts.orbitron(
                                                  color: const Color(0xFFFF1744),
                                                  fontSize: 58,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 14,
                                                  shadows: [
                                                    Shadow(
                                                      color: const Color(0xFFFF1744).withOpacity(0.85),
                                                      blurRadius: 35,
                                                    ),
                                                    const Shadow(
                                                      color: Colors.black,
                                                      blurRadius: 15,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'VITAL SIGNS FLATLINED // OPERATOR DOWN',
                                                style: GoogleFonts.shareTechMono(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                  letterSpacing: 3.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 28),

                                        // Mission Debrief Card
                                        FadeInUp(
                                          delay: const Duration(milliseconds: 300),
                                          duration: const Duration(milliseconds: 600),
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(22),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF14070A).withOpacity(0.92),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: const Color(0xFFFF1744).withOpacity(0.4),
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.8),
                                                  blurRadius: 24,
                                                  spreadRadius: 4,
                                                ),
                                                BoxShadow(
                                                  color: const Color(0xFFFF1744).withOpacity(0.15),
                                                  blurRadius: 16,
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              children: [
                                                // Objective Progress Bar
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'MISSION PURGE OBJECTIVE',
                                                      style: GoogleFonts.shareTechMono(
                                                        color: Colors.white60,
                                                        fontSize: 12,
                                                        letterSpacing: 1.5,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${_targetKills > 0 ? ((_kills / _targetKills) * 100).clamp(0, 100).toInt() : 0}% COMPLETE',
                                                      style: GoogleFonts.shareTechMono(
                                                        color: const Color(0xFFFF5252),
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        letterSpacing: 1.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                Container(
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.06),
                                                    borderRadius: BorderRadius.circular(5),
                                                    border: Border.all(color: Colors.white12, width: 0.5),
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      FractionallySizedBox(
                                                        widthFactor: _targetKills > 0
                                                            ? (_kills / _targetKills).clamp(0.0, 1.0)
                                                            : 0.0,
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(5),
                                                            gradient: const LinearGradient(
                                                              colors: [
                                                                Color(0xFFFF7043),
                                                                Color(0xFFFF1744),
                                                              ],
                                                            ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: const Color(0xFFFF1744).withOpacity(0.6),
                                                                blurRadius: 8,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                Container(height: 1, color: Colors.white10),
                                                const SizedBox(height: 20),

                                                // 4 Telemetry Metrics Grid
                                                Row(
                                                  children: [
                                                    _buildGameOverMetric(
                                                      icon: Icons.shield_outlined,
                                                      label: 'SECTOR',
                                                      value: '0${widget.level}',
                                                      accentColor: const Color(0xFF00E5FF),
                                                    ),
                                                    Container(width: 1, height: 42, color: Colors.white12),
                                                    _buildGameOverMetric(
                                                      icon: Icons.crisis_alert,
                                                      label: 'KILLS',
                                                      value: '$_kills/$_targetKills',
                                                      accentColor: const Color(0xFFFF5252),
                                                    ),
                                                    Container(width: 1, height: 42, color: Colors.white12),
                                                    _buildGameOverMetric(
                                                      icon: Icons.timer_outlined,
                                                      label: 'SURVIVED',
                                                      value: '${_survivalTime.toInt()}s',
                                                      accentColor: const Color(0xFFFFD54F),
                                                    ),
                                                    Container(width: 1, height: 42, color: Colors.white12),
                                                    _buildGameOverMetric(
                                                      icon: Icons.monetization_on_outlined,
                                                      label: 'SCRAP',
                                                      value: '${gameState.coins}',
                                                      accentColor: const Color(0xFF69F0AE),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 16),
                                                // Equipped Weapon Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF1E0E12),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.white12),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.flash_on, color: Color(0xFF00E5FF), size: 14),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'EQUIPPED LOADOUT: ${currentWeapon.toUpperCase()}',
                                                        style: GoogleFonts.shareTechMono(
                                                          color: Colors.white70,
                                                          fontSize: 11,
                                                          letterSpacing: 2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 26),

                                        // Action Buttons
                                        FadeInUp(
                                          delay: const Duration(milliseconds: 450),
                                          duration: const Duration(milliseconds: 600),
                                          child: Wrap(
                                            alignment: WrapAlignment.center,
                                            spacing: 14,
                                            runSpacing: 12,
                                            children: [
                                              // 1. Respawn / Retry Button (Primary Crimson Glow)
                                              MouseRegion(
                                                cursor: SystemMouseCursors.click,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    Navigator.pushReplacement(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => GameScreen(level: widget.level, isEndless: widget.isEndless),
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    width: 200,
                                                    height: 52,
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(
                                                        colors: [Color(0xFFFF1744), Color(0xFFB71C1C)],
                                                      ),
                                                      borderRadius: BorderRadius.circular(10),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(0xFFFF1744).withOpacity(0.5),
                                                          blurRadius: 18,
                                                          spreadRadius: 2,
                                                          offset: const Offset(0, 3),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const Icon(Icons.replay_rounded, color: Colors.white, size: 20),
                                                        const SizedBox(width: 10),
                                                        Text(
                                                          'RESPAWN',
                                                          style: GoogleFonts.oswald(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                            letterSpacing: 2.5,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              // 2. Armory / Upgrade Button (Secondary Cyberpunk Amber)
                                              MouseRegion(
                                                cursor: SystemMouseCursors.click,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => const ShopScreen(),
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    width: 190,
                                                    height: 52,
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(
                                                        colors: [Color(0xFFFFB300), Color(0xFFE65100)],
                                                      ),
                                                      borderRadius: BorderRadius.circular(10),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(0xFFFFB300).withOpacity(0.4),
                                                          blurRadius: 16,
                                                          offset: const Offset(0, 3),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const Icon(Icons.military_tech_rounded, color: Colors.black87, size: 20),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          'ARMORY',
                                                          style: GoogleFonts.oswald(
                                                            color: Colors.black87,
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                            letterSpacing: 2,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              // 3. Retreat to Map Button (Tertiary Slate/Crimson)
                                              MouseRegion(
                                                cursor: SystemMouseCursors.click,
                                                child: GestureDetector(
                                                  onTap: () => Navigator.pop(context),
                                                  child: Container(
                                                    width: 170,
                                                    height: 52,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF14171E).withOpacity(0.9),
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(
                                                        color: const Color(0xFFFF5252).withOpacity(0.6),
                                                        width: 1.2,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.6),
                                                          blurRadius: 10,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const Icon(Icons.keyboard_return, color: Colors.white70, size: 18),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          'RETREAT',
                                                          style: GoogleFonts.oswald(
                                                            color: Colors.white70,
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.bold,
                                                            letterSpacing: 2,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                if (_won)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF00E676), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E676).withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SECTOR PURGED!',
                            style: GoogleFonts.oswald(
                              color: const Color(0xFF00E676),
                              fontSize: 54,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 6,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF00E676).withOpacity(0.8),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'MISSION ACCOMPLISHED // EVACUATING...',
                            style: GoogleFonts.shareTechMono(
                              color: Colors.white70,
                              fontSize: 16,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (!_gameOver && !_won)
                  SafeArea(
                    child: Stack(
                    children: [
                      // Top Left: Operator Tactical Status
                      Positioned(
                        left: 20,
                        top: 15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14171E).withOpacity(0.92),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _health <= 25
                                  ? Colors.redAccent
                                  : const Color(0xFF374151),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.7),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                              if (_health <= 25)
                                BoxShadow(
                                  color: Colors.redAccent.withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Survivor Shield / Avatar Badge
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF2E3440), Color(0xFF1E222A)],
                                  ),
                                  border: Border.all(
                                    color: _health > 50
                                        ? const Color(0xFF00E676)
                                        : (_health > 25 ? Colors.amberAccent : Colors.redAccent),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.shield,
                                    color: _health > 50
                                        ? const Color(0xFF00E676)
                                        : (_health > 25 ? Colors.amberAccent : Colors.redAccent),
                                    size: 26,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Callsign, Health Gauge & Weapon Indicator
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'OPERATOR // SURVIVOR',
                                        style: GoogleFonts.shareTechMono(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2A2E39),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.white24, width: 0.8),
                                        ),
                                        child: Text(
                                          currentWeapon.toUpperCase(),
                                          style: GoogleFonts.oswald(
                                            color: Colors.amberAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Health Bar
                                  Container(
                                    width: 190,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.white24, width: 1),
                                    ),
                                    child: Stack(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 250),
                                          width: 190 * (_health / 100).clamp(0.0, 1.0),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5),
                                            gradient: LinearGradient(
                                              colors: _health > 50
                                                  ? [const Color(0xFF00E676), const Color(0xFF00B0FF)]
                                                  : (_health > 25
                                                      ? [Colors.amber, Colors.deepOrangeAccent]
                                                      : [Colors.redAccent, const Color(0xFFB71C1C)]),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: (_health > 50
                                                        ? const Color(0xFF00E676)
                                                        : (_health > 25 ? Colors.amber : Colors.redAccent))
                                                    .withOpacity(0.5),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            '$_health / 100 HP',
                                            style: GoogleFonts.oswald(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                              shadows: const [
                                                Shadow(color: Colors.black, blurRadius: 4),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Top Center: Sector Objective & Purge Wave Status
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          margin: const EdgeInsets.only(top: 15),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14171E).withOpacity(0.92),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE53935).withOpacity(0.8), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.8),
                                blurRadius: 15,
                              ),
                              BoxShadow(
                                color: const Color(0xFFE53935).withOpacity(0.2),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.isEndless
                                        ? 'NIGHTMARE PROTOCOL // WAVE 0$_endlessWave'
                                        : 'SECTOR 0${widget.level} // PURGE ZONE',
                                    style: GoogleFonts.oswald(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 3,
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFFFF5252).withOpacity(0.8),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Kill Progress Bar
                              Container(
                                width: 180,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white12, width: 0.5),
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 180 * (widget.isEndless ? (_waveTargetKills > 0 ? (_waveKills / _waveTargetKills).clamp(0.0, 1.0) : 0) : (_targetKills > 0 ? (_kills / _targetKills).clamp(0.0, 1.0) : 0)),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFF7043), Color(0xFFFF1744)],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.crisis_alert, color: Color(0xFFFF5252), size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.isEndless
                                            ? 'WAVE: $_waveKills/$_waveTargetKills • SCORE: $_endlessScore'
                                            : 'KILLS: $_kills/$_targetKills',
                                        style: GoogleFonts.shareTechMono(
                                          color: const Color(0xFFFF8A80),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Row(
                                    children: [
                                      const Icon(Icons.timer_outlined, color: Color(0xFF64B5F6), size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_survivalTime.toInt()}s',
                                        style: GoogleFonts.shareTechMono(
                                          color: const Color(0xFF90CAF9),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Active Tactical Buff Indicators
                              if (_shieldTimer > 0 || _overchargeTimer > 0 || _isFrozen) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_shieldTimer > 0)
                                      _buildActiveBuffBadge(
                                        icon: Icons.shield,
                                        label: 'SHIELD ${_shieldTimer.toStringAsFixed(1)}s',
                                        color: const Color(0xFF00E5FF),
                                      ),
                                    if (_shieldTimer > 0 && (_overchargeTimer > 0 || _isFrozen))
                                      const SizedBox(width: 6),
                                    if (_overchargeTimer > 0)
                                      _buildActiveBuffBadge(
                                        icon: Icons.flash_on,
                                        label: 'OVERCHARGE ${_overchargeTimer.toStringAsFixed(1)}s',
                                        color: const Color(0xFFFF9100),
                                      ),
                                    if (_overchargeTimer > 0 && _isFrozen)
                                      const SizedBox(width: 6),
                                    if (_isFrozen)
                                      _buildActiveBuffBadge(
                                        icon: Icons.ac_unit,
                                        label: 'FROZEN ${_freezeTimer.toStringAsFixed(1)}s',
                                        color: const Color(0xFF80D8FF),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Top Right: Scavenged Scrap, Sound & Pause
                      Positioned(
                        right: 20,
                        top: 15,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Scrap Currency Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14171E).withOpacity(0.92),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.8), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.7),
                                    blurRadius: 10,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFFFD54F).withOpacity(0.2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.monetization_on_outlined, color: Color(0xFFFFD54F), size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${gameState.coins}',
                                    style: GoogleFonts.oswald(
                                      color: const Color(0xFFFFD54F),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Sound Toggle Button
                            GestureDetector(
                              onTap: () => gameState.toggleSound(),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF14171E).withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF374151), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 8),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    gameState.soundEnabled ? Icons.volume_up : Icons.volume_off,
                                    color: gameState.soundEnabled ? Colors.white70 : Colors.redAccent,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Pause Button
                            GestureDetector(
                              onTap: _togglePause,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF14171E).withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.8), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withOpacity(0.25),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.pause, color: Color(0xFF00E5FF), size: 22),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Threat Scanner Radar (Top Right beneath scrap bar)
                      Positioned(
                        right: 20,
                        top: 75,
                        child: Container(
                          width: 125,
                          height: 125,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.85),
                            border: Border.all(color: const Color(0xFF374151), width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.9), blurRadius: 10),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(125, 125),
                                painter: TacticalRadarPainter(),
                              ),
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: pi * 2),
                                duration: const Duration(seconds: 3),
                                builder: (context, val, child) {
                                  return Transform.rotate(
                                    angle: val,
                                    child: Container(
                                      width: 125,
                                      height: 125,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: SweepGradient(
                                          colors: [
                                            Colors.transparent,
                                            const Color(0xFF00E676).withOpacity(0.35),
                                          ],
                                          stops: const [0.75, 1.0],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Player center direction arrow
                              Transform.rotate(
                                angle: _currentAimAngle + pi / 2,
                                child: const Icon(Icons.navigation, color: Color(0xFF00E5FF), size: 14),
                              ),
                              // Zombie Threat Blips
                              ..._zombies.map((z) {
                                double rx = (z.x - _playerX) / 18;
                                double ry = (z.y - _playerY) / 18;
                                if (rx * rx + ry * ry > 55 * 55) return const SizedBox.shrink();
                                Color blipColor = z.isDying
                                    ? Colors.grey
                                    : (z.type == 'boss' ? Colors.deepPurpleAccent : (z.type == 'tank' ? Colors.orangeAccent : const Color(0xFFFF1744)));
                                double blipSize = (z.type == 'boss' || z.type == 'tank') ? 6.5 : 4.5;
                                return Positioned(
                                  left: 62.5 + rx - blipSize / 2,
                                  top: 62.5 + ry - blipSize / 2,
                                  child: Container(
                                    width: blipSize,
                                    height: blipSize,
                                    decoration: BoxDecoration(
                                      color: blipColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: blipColor.withOpacity(0.8), blurRadius: 4),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),



                      // Tactical Overdrive / Drone Launch Button (Above Dash)
                      Positioned(
                        right: 25,
                        bottom: 115,
                        child: GestureDetector(
                          onTap: _useOverdrive,
                          child: Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              color: const Color(0xFF14171E).withOpacity(0.92),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isOverdriveActive
                                    ? const Color(0xFF00E5FF)
                                    : (_overdriveCharge >= 100.0
                                        ? const Color(0xFF00E676)
                                        : const Color(0xFF374151)),
                                width: 2.5,
                              ),
                              boxShadow: _isOverdriveActive || _overdriveCharge >= 100.0
                                  ? [
                                      BoxShadow(
                                        color: (_isOverdriveActive ? const Color(0xFF00E5FF) : const Color(0xFF00E676)).withOpacity(0.55),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8)],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 70,
                                  height: 70,
                                  child: CircularProgressIndicator(
                                    value: _isOverdriveActive
                                        ? (_overdriveTimer / 15.0).clamp(0.0, 1.0)
                                        : (_overdriveCharge / 100.0).clamp(0.0, 1.0),
                                    strokeWidth: 3.5,
                                    valueColor: AlwaysStoppedAnimation(
                                      _isOverdriveActive
                                          ? const Color(0xFF00E5FF)
                                          : (_overdriveCharge >= 100.0 ? const Color(0xFF00E676) : const Color(0xFFFF9100)),
                                    ),
                                    backgroundColor: Colors.white12,
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.rocket_launch_rounded,
                                      color: _isOverdriveActive
                                          ? const Color(0xFF00E5FF)
                                          : (_overdriveCharge >= 100.0 ? const Color(0xFF00E676) : Colors.grey),
                                      size: 30,
                                    ),
                                    Text(
                                      _isOverdriveActive
                                          ? '${_overdriveTimer.toStringAsFixed(1)}s'
                                          : (_overdriveCharge >= 100.0 ? 'OVERDRIVE' : '${_overdriveCharge.toInt()}%'),
                                      style: GoogleFonts.oswald(
                                        color: _isOverdriveActive || _overdriveCharge >= 100.0 ? Colors.white : Colors.grey,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Tactical Dash / Evade Thruster (Bottom Right)
                      Positioned(
                        right: 25,
                        bottom: 25,
                        child: GestureDetector(
                          onTap: _useDash,
                          child: Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              color: const Color(0xFF14171E).withOpacity(0.92),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _dashCooldown > 0
                                    ? const Color(0xFF374151)
                                    : const Color(0xFF00E5FF),
                                width: 2.5,
                              ),
                              boxShadow: _dashCooldown > 0
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8)]
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withOpacity(0.4),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_dashCooldown > 0)
                                  SizedBox(
                                    width: 70,
                                    height: 70,
                                    child: CircularProgressIndicator(
                                      value: 1.0 - (_dashCooldown / 2.0).clamp(0.0, 1.0),
                                      strokeWidth: 3,
                                      valueColor: const AlwaysStoppedAnimation(Color(0xFF00E5FF)),
                                      backgroundColor: Colors.white12,
                                    ),
                                  ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.fast_forward_rounded,
                                      color: _dashCooldown > 0 ? Colors.grey : const Color(0xFF00E5FF),
                                      size: 32,
                                    ),
                                    Text(
                                      _dashCooldown > 0 ? '${_dashCooldown.toStringAsFixed(1)}s' : 'DASH',
                                      style: GoogleFonts.oswald(
                                        color: _dashCooldown > 0 ? Colors.grey : Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Tactical Weapon Switcher Dock (Bottom Center)
                      Positioned(
                        bottom: 25,
                        left: 150,
                        right: 120,
                        child: Center(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildTacticalWeaponDock(gameState, currentWeapon),
                          ),
                        ),
                      ),

                      // Tactical Pause Modal Overlay
                      if (_isPaused)
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              color: Colors.black.withOpacity(0.75),
                              child: Center(
                                child: Container(
                                  width: 420,
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF14171E).withOpacity(0.96),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.7), width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.9),
                                        blurRadius: 25,
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withOpacity(0.2),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '// TACTICAL PAUSE //',
                                        style: GoogleFonts.oswald(
                                          color: const Color(0xFF00E5FF),
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 4,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'SECTOR 0${widget.level} COMBAT REPORT',
                                        style: GoogleFonts.shareTechMono(
                                          color: Colors.white60,
                                          fontSize: 12,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      // Stats Card
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1F242E),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.white12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            Column(
                                              children: [
                                                Text('KILLS', style: GoogleFonts.oswald(color: Colors.white54, fontSize: 12)),
                                                Text('$_kills / $_targetKills', style: GoogleFonts.oswald(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            Container(width: 1, height: 30, color: Colors.white12),
                                            Column(
                                              children: [
                                                Text('SURVIVED', style: GoogleFonts.oswald(color: Colors.white54, fontSize: 12)),
                                                Text('${_survivalTime.toInt()}s', style: GoogleFonts.oswald(color: const Color(0xFF64B5F6), fontSize: 18, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            Container(width: 1, height: 30, color: Colors.white12),
                                            Column(
                                              children: [
                                                Text('SCRAP', style: GoogleFonts.oswald(color: Colors.white54, fontSize: 12)),
                                                Text('${gameState.coins}', style: GoogleFonts.oswald(color: const Color(0xFFFFD54F), fontSize: 18, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      // Audio controls row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () => gameState.toggleSound(),
                                            icon: Icon(
                                              gameState.soundEnabled ? Icons.volume_up : Icons.volume_off,
                                              color: gameState.soundEnabled ? Colors.greenAccent : Colors.redAccent,
                                              size: 20,
                                            ),
                                            label: Text(
                                              'SFX: ${gameState.soundEnabled ? 'ON' : 'OFF'}',
                                              style: GoogleFonts.oswald(color: Colors.white70),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          TextButton.icon(
                                            onPressed: () => gameState.toggleMusic(),
                                            icon: Icon(
                                              gameState.musicEnabled ? Icons.music_note : Icons.music_off,
                                              color: gameState.musicEnabled ? Colors.greenAccent : Colors.redAccent,
                                              size: 20,
                                            ),
                                            label: Text(
                                              'MUSIC: ${gameState.musicEnabled ? 'ON' : 'OFF'}',
                                              style: GoogleFonts.oswald(color: Colors.white70),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      // Action Buttons
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: ElevatedButton(
                                          onPressed: _togglePause,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF00E5FF),
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: Text(
                                            'RESUME MISSION',
                                            style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => GameScreen(level: widget.level)),
                                                );
                                              },
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.amberAccent,
                                                side: const BorderSide(color: Colors.amberAccent),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              child: Text(
                                                'RESTART',
                                                style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => Navigator.pop(context),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.redAccent,
                                                side: const BorderSide(color: Colors.redAccent),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              child: Text(
                                                'EVACUATE',
                                                style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildGameOverMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: accentColor, size: 18),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.shareTechMono(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.oswald(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _cycleWeapon(GameStateProvider gameState, int delta) {
    final unlocked = gameState.getWeaponsForMission(widget.level);
    if (unlocked.length <= 1) return;
    int currentIndex = unlocked.indexOf(gameState.currentWeapon);
    if (currentIndex == -1) currentIndex = 0;
    int nextIndex = (currentIndex + delta) % unlocked.length;
    if (nextIndex < 0) nextIndex += unlocked.length;
    gameState.equipWeapon(unlocked[nextIndex]);
  }

  void _selectWeaponByIndex(GameStateProvider gameState, int index) {
    final unlocked = gameState.getWeaponsForMission(widget.level);
    if (index >= 0 && index < unlocked.length) {
      gameState.equipWeapon(unlocked[index]);
    }
  }

  Widget _buildTacticalWeaponDock(GameStateProvider gameState, String currentWeapon) {
    final unlocked = gameState.getWeaponsForMission(widget.level);
    if (unlocked.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF14171E).withOpacity(0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.18),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_horiz_rounded, color: Color(0xFF00E5FF), size: 16),
              const SizedBox(width: 4),
              Text(
                'WEAPON [Q]:',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFF00E5FF),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          ...unlocked.asMap().entries.map((entry) {
            int index = entry.key;
            String weaponName = entry.value;
            bool isSelected = weaponName == currentWeapon;

            return GestureDetector(
              onTap: () {
                gameState.equipWeapon(weaponName);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
                        )
                      : null,
                  color: isSelected ? null : const Color(0xFF1F242E),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF374151),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black.withOpacity(0.25) : Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.oswald(
                          color: isSelected ? Colors.black : Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      _getWeaponIcon(weaponName),
                      size: 14,
                      color: isSelected ? Colors.black : Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      weaponName.toUpperCase(),
                      style: GoogleFonts.oswald(
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getWeaponIcon(String weapon) {
    switch (weapon) {
      case 'Bow':
      case 'Fire Bow':
        return Icons.architecture;
      case 'Crossbow':
        return Icons.arrow_right_alt;
      case 'Battle Axe':
        return Icons.content_cut;
      case 'War Hammer':
        return Icons.construction;
      case 'Katana':
        return Icons.sports_martial_arts;
      case 'Chainsaw':
        return Icons.hardware;
      case 'Assault Rifle':
        return Icons.hardware;
      case 'AK-47':
        return Icons.military_tech;
      case 'Shotgun':
        return Icons.adjust;
      case 'Sniper Rifle':
        return Icons.track_changes;
      case 'Plasma Cannon':
        return Icons.flash_on;
      case 'Laser Gun':
        return Icons.electric_bolt;
      case 'Grenade Launcher':
        return Icons.rocket_launch;
      case 'Minigun':
        return Icons.filter_tilt_shift;
      case 'Flamethrower':
        return Icons.whatshot;
      case 'Rocket Launcher':
        return Icons.rocket;
      case 'Tesla Cannon':
        return Icons.offline_bolt;
      default:
        return Icons.shield;
    }
  }

  Widget _buildProjectileWidget(Projectile p) {
    if (p.type == 'arrow' || p.type == 'fire_arrow' || p.type == 'zombie_arrow') {
      return Transform.rotate(
        angle: pi / 2,
        child: Icon(
          Icons.arrow_upward,
          color: p.type == 'fire_arrow'
              ? Colors.deepOrangeAccent
              : (p.type == 'zombie_arrow' ? Colors.redAccent : Colors.white),
          size: p.type == 'fire_arrow' ? 32 : (p.type == 'zombie_arrow' ? 28 : 24),
        ),
      );
    } else if (p.type == 'crossbow_bolt') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              boxShadow: const [BoxShadow(color: Colors.cyanAccent, blurRadius: 6)],
            ),
          ),
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.cyanAccent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      );
    } else if (p.type == 'plasma_bolt') {
      return Container(
        width: 20,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.cyanAccent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Colors.cyanAccent, blurRadius: 10, spreadRadius: 2),
          ],
        ),
      );
    } else if (p.type == 'laser_beam') {
      return Container(
        width: 38,
        height: 5,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE040FB), Color(0xFF00E5FF)],
          ),
          borderRadius: BorderRadius.circular(3),
          boxShadow: const [
            BoxShadow(color: Color(0xFF00E5FF), blurRadius: 10, spreadRadius: 2),
            BoxShadow(color: Color(0xFFE040FB), blurRadius: 6),
          ],
        ),
      );
    } else if (p.type == 'grenade') {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFF33691E),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.redAccent, blurRadius: 6, spreadRadius: 1),
          ],
        ),
        child: Center(
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    } else if (p.type == 'rpg_rocket') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 5,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.transparent, Colors.deepOrangeAccent],
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: const [BoxShadow(color: Colors.orangeAccent, blurRadius: 8)],
            ),
          ),
          Container(
            width: 22,
            height: 7,
            decoration: BoxDecoration(
              color: const Color(0xFF33691E),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.black54, width: 0.8),
            ),
          ),
          Container(
            width: 8,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFFFF5722),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.deepOrange, blurRadius: 6)],
            ),
          ),
        ],
      );
    } else if (p.type == 'flame_stream') {
      return Container(
        width: 26,
        height: 16,
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            colors: [Colors.yellowAccent, Colors.deepOrangeAccent, Colors.transparent],
            stops: [0.2, 0.7, 1.0],
          ),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.deepOrange, blurRadius: 12, spreadRadius: 3),
          ],
        ),
      );
    } else if (p.type == 'tesla_arc') {
      return Container(
        width: 24,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0xFF00E5FF), blurRadius: 12, spreadRadius: 3),
            BoxShadow(color: Colors.white, blurRadius: 4),
          ],
        ),
      );
    } else if (p.type == 'minigun_bullet') {
      return Container(
        width: 18,
        height: 4,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.orangeAccent, Colors.yellowAccent, Colors.white],
          ),
          borderRadius: BorderRadius.circular(2),
          boxShadow: const [
            BoxShadow(color: Colors.amberAccent, blurRadius: 6, spreadRadius: 1),
          ],
        ),
      );
    } else if (p.type == 'sniper_bullet') {
      return Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.cyanAccent, Colors.white],
          ),
          borderRadius: BorderRadius.circular(2),
          boxShadow: const [BoxShadow(color: Colors.cyanAccent, blurRadius: 8)],
        ),
      );
    } else {
      return Container(
        width: (p.type == 'bullet' || p.type == 'ak47_bullet') ? 22 : 10,
        height: 4,
        decoration: BoxDecoration(
          color: p.type == 'bullet'
              ? Colors.yellowAccent
              : (p.type == 'ak47_bullet' ? Colors.deepOrangeAccent : Colors.orange),
          borderRadius: BorderRadius.circular(10),
          boxShadow: p.type == 'ak47_bullet'
              ? const [BoxShadow(color: Colors.deepOrange, blurRadius: 4)]
              : null,
        ),
      );
    }
  }

  Widget _buildTacticalSkill({
    required IconData icon,
    required String name,
    required int count,
    double cooldown = 0,
    double maxCooldown = 1.0,
    bool isActive = false,
    required Color color,
    required VoidCallback onTap,
  }) {
    bool isAvailable = count > 0 && cooldown <= 0;
    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF14171E).withOpacity(0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAvailable
                    ? (isActive ? Colors.white : color)
                    : const Color(0xFF374151),
                width: 1.8,
              ),
              boxShadow: isAvailable
                  ? [
                      BoxShadow(
                        color: color.withOpacity(isActive ? 0.6 : 0.25),
                        blurRadius: 10,
                        spreadRadius: isActive ? 2 : 0,
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (cooldown > 0)
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: (cooldown / maxCooldown).clamp(0.0, 1.0),
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(color),
                      backgroundColor: Colors.white10,
                    ),
                  ),
                Icon(
                  icon,
                  color: isAvailable ? color : Colors.grey,
                  size: 28,
                  shadows: isAvailable
                      ? [Shadow(color: color, blurRadius: 8)]
                      : [],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: -6,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isAvailable ? color : const Color(0xFF262C38),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black, width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 4),
                ],
              ),
              child: Text(
                cooldown > 0 ? '${cooldown.ceil()}s' : '$count',
                style: GoogleFonts.oswald(
                  color: isAvailable ? Colors.black : Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TACTICAL POWER-UPS & AIRDROPS SYSTEM
  // ==========================================
  void _maybeDropPowerUp(double x, double y, String type) {
    double dropChance = (type == 'tank' || type == 'boss' || type == 'spitter') ? 0.70 : 0.28;
    if (_random.nextDouble() > dropChance) return;

    double roll = _random.nextDouble();
    PowerUpType pType;
    if (roll < 0.25) {
      pType = PowerUpType.medkit;
    } else if (roll < 0.45) {
      pType = PowerUpType.shield;
    } else if (roll < 0.65) {
      pType = PowerUpType.freeze;
    } else if (roll < 0.85) {
      pType = PowerUpType.scrapCrate;
    } else if (roll < 0.95) {
      pType = PowerUpType.overcharge;
    } else {
      pType = PowerUpType.nuke;
    }

    _powerUps.add(
      TacticalPowerUp(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: pType,
        x: x.clamp(40.0, max(40.0, _screenWidth - 40.0)),
        y: y.clamp(50.0, max(50.0, _screenHeight - 80.0)),
        landed: true,
        lifeTimer: 18.0,
        bouncePhase: _random.nextDouble() * pi * 2,
      ),
    );
  }

  void _spawnTacticalAirdrop() {
    if (_screenWidth <= 0 || _screenHeight <= 0) return;

    double targetX = 60.0 + _random.nextDouble() * max(40.0, _screenWidth - 120.0);
    double targetY = 80.0 + _random.nextDouble() * max(40.0, _screenHeight - 160.0);

    double roll = _random.nextDouble();
    PowerUpType pType;
    if (roll < 0.25) {
      pType = PowerUpType.nuke;
    } else if (roll < 0.50) {
      pType = PowerUpType.overcharge;
    } else if (roll < 0.75) {
      pType = PowerUpType.shield;
    } else {
      pType = PowerUpType.scrapCrate;
    }

    _powerUps.add(
      TacticalPowerUp(
        id: 'airdrop_${DateTime.now().microsecondsSinceEpoch}',
        type: pType,
        x: targetX,
        y: -60,
        targetY: targetY,
        parachuteY: -60,
        isAirdrop: true,
        landed: false,
        lifeTimer: 24.0,
        bouncePhase: 0.0,
      ),
    );

    _airdropAlertTimer = 3.2;
    _airdropInboundAlert = 'TACTICAL AIRDROP INBOUND!';
    final gameState = Provider.of<GameStateProvider>(context, listen: false);
    if (gameState.soundEnabled) {
      AudioService().playSoundEffect('lightning.wav');
    }
  }

  void _collectPowerUp(TacticalPowerUp item, GameStateProvider gameState) {
    if (gameState.soundEnabled) {
      if (item.type == PowerUpType.nuke || item.type == PowerUpType.overcharge) {
        AudioService().playSoundEffect('lightning.wav');
      } else if (item.type == PowerUpType.freeze) {
        AudioService().playSoundEffect('freeze.wav');
      } else {
        AudioService().playSoundEffect('arrow.wav');
      }
    }

    gameState.recordPowerUpCollected();

    // Spawn tactical burst particles
    for (int i = 0; i < 16; i++) {
      _bloodParticles.add(
        BloodParticle(
          item.x,
          item.y,
          (_random.nextDouble() - 0.5) * 220,
          (_random.nextDouble() - 0.5) * 220 - 40,
          0.6 + _random.nextDouble() * 0.4,
          3.5 + _random.nextDouble() * 4.0,
        ),
      );
    }

    switch (item.type) {
      case PowerUpType.medkit:
        _health = (_health + 35).clamp(0, 100);
        _activeNotification = TacticalPickupNotification(
          title: '+35 HP RESTORED',
          subtitle: 'TACTICAL BIO-MEDKIT APPLIED',
          icon: Icons.local_hospital_rounded,
          color: const Color(0xFF00E676),
        );
        break;

      case PowerUpType.shield:
        _shieldTimer = 8.0;
        _activeNotification = TacticalPickupNotification(
          title: 'FORCEFIELD SHIELD ONLINE',
          subtitle: 'INVINCIBLE FOR 8 SECONDS',
          icon: Icons.shield_rounded,
          color: const Color(0xFF00E5FF),
        );
        break;

      case PowerUpType.nuke:
        _triggerTacticalNuke(gameState);
        break;

      case PowerUpType.freeze:
        _isFrozen = true;
        _freezeTimer = 5.0;
        _activeNotification = TacticalPickupNotification(
          title: 'CRYO-FREEZE PULSE',
          subtitle: 'ALL UNDEAD FROZEN FOR 5s',
          icon: Icons.ac_unit_rounded,
          color: const Color(0xFF80D8FF),
        );
        break;

      case PowerUpType.overcharge:
        _overchargeTimer = 7.0;
        _activeNotification = TacticalPickupNotification(
          title: 'WEAPON OVERCHARGE',
          subtitle: '2.5X FIRE RATE + 2.2X DAMAGE',
          icon: Icons.flash_on_rounded,
          color: const Color(0xFFFF9100),
        );
        break;

      case PowerUpType.scrapCrate:
        gameState.addCoins(150);
        _activeNotification = TacticalPickupNotification(
          title: '+150 SCRAP CACHE',
          subtitle: 'TACTICAL MUNITIONS SECURED',
          icon: Icons.monetization_on_rounded,
          color: const Color(0xFFFFD54F),
        );
        break;
    }
  }

  void _triggerTacticalNuke(GameStateProvider gameState) {
    _nukeFlashTimer = 0.6;
    _activeNotification = TacticalPickupNotification(
      title: 'TACTICAL NUKE DETONATED',
      subtitle: 'SECTOR-WIDE HORDE ELIMINATION',
      icon: Icons.dangerous_rounded,
      color: const Color(0xFFFF1744),
    );

    for (var z in _zombies) {
      if (z.isDying) continue;
      z.health = 0;
      z.isDying = true;
      for (int i = 0; i < 18; i++) {
        _bloodParticles.add(
          BloodParticle(
            z.x,
            z.y,
            (_random.nextDouble() - 0.5) * 320,
            (_random.nextDouble() - 0.5) * 320 - 80,
            0.8 + _random.nextDouble() * 0.5,
            4.0 + _random.nextDouble() * 6.0,
          ),
        );
      }
    }
  }

  Widget _buildApexCombatDrone() {
    return SizedBox(
      width: 56,
      height: 56,
      child: CustomPaint(
        painter: ApexDronePainter(phase: _droneOrbitPhase),
      ),
    );
  }

  Widget _buildOverdriveEnergyAura() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFF00E5FF).withOpacity(0.0),
            const Color(0xFF00E5FF).withOpacity(0.18),
            const Color(0xFF7C4DFF).withOpacity(0.35),
          ],
          stops: const [0.4, 0.75, 1.0],
        ),
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.7),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.4),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildComboBanner() {
    return FadeInDown(
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E1036), Color(0xFF14071D)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE040FB), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE040FB).withOpacity(0.5),
              blurRadius: 14,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: Color(0xFFE040FB), size: 18),
            const SizedBox(width: 6),
            Text(
              '$_comboTitle! (x${_comboMultiplier.toStringAsFixed(1)})',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE040FB).withOpacity(0.25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$_comboCount STREAK',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFFE040FB),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveClearedBanner() {
    return FadeInDown(
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0C2417).withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00E676), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E676).withOpacity(0.4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.military_tech_rounded, color: Color(0xFF00E676), size: 22),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WAVE ${_endlessWave - 1} CLEARED // OUTBREAK ESCALATING',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '+30 HP RECOVERED • TACTICAL SUPPLY AIRDROP INBOUND',
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFF00E676),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerShieldBubble() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFF00E5FF).withOpacity(0.08),
            const Color(0xFF00E5FF).withOpacity(0.28),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.85),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.55),
            blurRadius: 18,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerOverchargeAura() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFFF9100).withOpacity(0.05),
            const Color(0xFFFF5722).withOpacity(0.25),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFFAB00).withOpacity(0.9),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6D00).withOpacity(0.6),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.flash_on,
          color: Color(0xFFFFD54F),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildAirdropAlertBanner() {
    return FadeInDown(
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF140D0F).withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFF1744).withOpacity(0.85),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF1744).withOpacity(0.5),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flight_land, color: Color(0xFFFF5252), size: 20),
            const SizedBox(width: 8),
            Text(
              'TACTICAL AIRDROP INBOUND',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBanner() {
    final note = _activeNotification!;
    return FadeInDown(
      duration: const Duration(milliseconds: 250),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1520).withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: note.color, width: 1.8),
          boxShadow: [
            BoxShadow(
              color: note.color.withOpacity(0.4),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(note.icon, color: note.color, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  note.title,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  note.subtitle,
                  style: GoogleFonts.shareTechMono(
                    color: note.color,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBuffBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.shareTechMono(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerUpWidget(TacticalPowerUp p) {
    if (!p.landed) {
      double tilt = sin(p.bouncePhase) * 0.12;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: p.x - 22,
            top: p.targetY - 8,
            child: Container(
              width: 44,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.elliptical(44, 16)),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.7), width: 1.5),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.4), blurRadius: 10),
                ],
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00E5FF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: p.x - 30,
            top: p.y - 45,
            child: Transform.rotate(
              angle: tilt,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD54F),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFFFD54F).withOpacity(0.6), blurRadius: 8),
                      ],
                    ),
                    child: Center(
                      child: Icon(Icons.flight_land, size: 16, color: Colors.brown[900]),
                    ),
                  ),
                  CustomPaint(
                    size: const Size(40, 18),
                    painter: _ParachuteLinesPainter(),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF263238),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFFFD54F).withOpacity(0.5), blurRadius: 10),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.military_tech, color: Color(0xFFFFD54F), size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    double bob = sin(p.bouncePhase) * 4.5;
    double opacity = (p.lifeTimer < 4.0 && (p.lifeTimer * 5).toInt() % 2 == 0) ? 0.35 : 1.0;

    IconData icon;
    Color color;
    String tag;
    switch (p.type) {
      case PowerUpType.medkit:
        icon = Icons.local_hospital_rounded;
        color = const Color(0xFF00E676);
        tag = '+35 HP';
        break;
      case PowerUpType.shield:
        icon = Icons.shield_rounded;
        color = const Color(0xFF00E5FF);
        tag = 'SHIELD';
        break;
      case PowerUpType.nuke:
        icon = Icons.dangerous_rounded;
        color = const Color(0xFFFF1744);
        tag = 'NUKE';
        break;
      case PowerUpType.freeze:
        icon = Icons.ac_unit_rounded;
        color = const Color(0xFF80D8FF);
        tag = 'CRYO';
        break;
      case PowerUpType.overcharge:
        icon = Icons.flash_on_rounded;
        color = const Color(0xFFFF9100);
        tag = 'OVERCHARGE';
        break;
      case PowerUpType.scrapCrate:
        icon = Icons.monetization_on_rounded;
        color = const Color(0xFFFFD54F);
        tag = '+150 💀';
        break;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: p.x - 22,
          top: p.y + 14,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 44,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.elliptical(44, 12)),
                color: color.withOpacity(0.35),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.6), blurRadius: 8),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: p.x - 24,
          top: p.y - 24 + bob,
          child: Opacity(
            opacity: opacity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1017).withOpacity(0.92),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2.0),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.55), blurRadius: 14, spreadRadius: 1),
                      BoxShadow(color: Colors.black.withOpacity(0.7), blurRadius: 6),
                    ],
                  ),
                  child: Center(
                    child: Icon(icon, color: color, size: 26),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withOpacity(0.6), width: 0.8),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.shareTechMono(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}

class PlayerPainter extends CustomPainter {
  final double aimAngle;
  final double recoil;
  final String weapon;
  final double shootTimer;

  PlayerPainter({
    required this.aimAngle,
    required this.recoil,
    required this.weapon,
    required this.shootTimer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    double cx = size.width * 0.4;
    double cy = size.height * 0.35;
    final headRadius = 18.0;

    void drawBody(Paint p, Offset off) {
      canvas.drawLine(
        Offset(cx, size.height * 0.2 + 15) + off,
        Offset(cx, size.height * 0.6) + off,
        p,
      );
      canvas.drawLine(
        Offset(cx, size.height * 0.6) + off,
        Offset(size.width * 0.15, size.height * 0.95) + off,
        p,
      );
      canvas.drawLine(
        Offset(cx, size.height * 0.6) + off,
        Offset(size.width * 0.65, size.height * 0.95) + off,
        p,
      );
    }

    drawBody(shadowPaint, const Offset(3, 5));
    canvas.drawCircle(
      Offset(cx, size.height * 0.2) + const Offset(3, 5),
      headRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    drawBody(paint, Offset.zero);

    final headPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [Colors.grey[800]!, Colors.black],
            center: const Alignment(-0.3, -0.3),
            radius: 0.8,
          ).createShader(
            Rect.fromCircle(
              center: Offset(cx, size.height * 0.2),
              radius: headRadius,
            ),
          )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, size.height * 0.2), headRadius, headPaint);

    drawBody(highlightPaint, const Offset(-1.5, -1.5));

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(aimAngle);

    double w = size.width;
    double h = size.height;

    if (weapon == 'Bow' || weapon == 'Fire Bow') {
      final quiverShadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawLine(
        Offset(-0.2 * w + 2, -0.2 * h + 4),
        Offset(-0.35 * w + 2, 0.25 * h + 4),
        quiverShadow,
      );

      final quiverPaint = Paint()
        ..shader =
            LinearGradient(
              colors: [Colors.brown[600]!, Colors.brown[900]!],
            ).createShader(
              Rect.fromPoints(
                Offset(-0.2 * w, -0.2 * h),
                Offset(-0.35 * w, 0.25 * h),
              ),
            )
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(-0.2 * w, -0.2 * h),
        Offset(-0.35 * w, 0.25 * h),
        quiverPaint,
      );

      final quiverHighlight = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(-0.2 * w - 3, -0.2 * h),
        Offset(-0.35 * w - 3, 0.25 * h),
        quiverHighlight,
      );

      final strapPaint = Paint()
        ..color = Colors.amber[800]!
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.square;
      canvas.drawLine(
        Offset(-0.23 * w, -0.1 * h),
        Offset(-0.28 * w, -0.1 * h),
        strapPaint,
      );
      canvas.drawLine(
        Offset(-0.3 * w, 0.1 * h),
        Offset(-0.35 * w, 0.1 * h),
        strapPaint,
      );

      void drawQuiverArrow(Offset start, Offset end) {
        canvas.drawLine(
          start,
          end,
          Paint()
            ..color = Colors.brown[300]!
            ..strokeWidth = 2.5,
        );
        final fletchingPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 2;
        canvas.drawLine(start, start + const Offset(-6, -6), fletchingPaint);
        canvas.drawLine(start, start + const Offset(6, -6), fletchingPaint);
      }

      drawQuiverArrow(Offset(-0.25 * w, -0.3 * h), Offset(-0.22 * w, -0.2 * h));
      drawQuiverArrow(
        Offset(-0.2 * w, -0.35 * h),
        Offset(-0.18 * w, -0.15 * h),
      );
      drawQuiverArrow(
        Offset(-0.15 * w, -0.3 * h),
        Offset(-0.14 * w, -0.15 * h),
      );

      double frontHandX = 0.3 * w;
      double frontHandY = 0;
      double backHandX;
      double backHandY;

      bool isArrowNocked = false;
      Offset arrowPos = Offset.zero;
      double arrowAngle = 0.0;

      if (recoil > 0) {
        backHandX = (-0.2 * w) * (1 - recoil) + (frontHandX * recoil);
        backHandY = (0.1 * h) * (1 - recoil);
      } else if (shootTimer > 0) {
        double progress = 1.0 - (shootTimer / 0.6).clamp(0.0, 1.0);

        if (progress < 0.3) {
          double p = progress / 0.3;
          backHandX = frontHandX + (-0.2 * w - frontHandX) * p;
          backHandY = 0 + (-0.3 * h - 0) * p;
        } else if (progress < 0.7) {
          double p = (progress - 0.3) / 0.4;
          backHandX = -0.2 * w + (frontHandX - -0.2 * w) * p;
          backHandY = -0.3 * h + (0 - -0.3 * h) * p;
          isArrowNocked = true;
          arrowPos = Offset(backHandX, backHandY);
          arrowAngle = -pi / 2 + (0 - -pi / 2) * p;
        } else {
          double p = (progress - 0.7) / 0.3;
          backHandX = frontHandX + (-0.2 * w - frontHandX) * p;
          backHandY = 0 + (0.1 * h - 0) * p;
          isArrowNocked = true;
          arrowPos = Offset(backHandX, backHandY);
          arrowAngle = 0;
        }
      } else {
        backHandX = -0.2 * w;
        backHandY = 0.1 * h;
        isArrowNocked = true;
        arrowPos = Offset(backHandX, backHandY);
        arrowAngle = 0;
      }

      void drawArm(Offset start, Offset end) {
        canvas.drawLine(
          start + const Offset(3, 5),
          end + const Offset(3, 5),
          shadowPaint,
        );
        canvas.drawLine(start, end, paint);
        canvas.drawLine(
          start + const Offset(-1.5, -1.5),
          end + const Offset(-1.5, -1.5),
          highlightPaint,
        );
      }

      drawArm(Offset.zero, Offset(frontHandX, frontHandY));
      drawArm(Offset.zero, Offset(backHandX, backHandY));

      final bowPath = Path();
      bowPath.moveTo(frontHandX, -0.3 * h);

      double drawAmount = 0.0;
      if (recoil > 0) {
        drawAmount = 1.0 - recoil;
      } else if (shootTimer == 0) {
        drawAmount = 1.0;
      } else if (shootTimer > 0) {
        double progress = 1.0 - (shootTimer / 0.6).clamp(0.0, 1.0);
        if (progress > 0.7) {
          drawAmount = (progress - 0.7) / 0.3;
        }
      }

      double bowBendX = (0.55 * w) - (0.35 * w * drawAmount);
      bowPath.quadraticBezierTo(bowBendX, 0, frontHandX, 0.3 * h);

      final bowShadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(bowPath.shift(const Offset(2, 4)), bowShadow);

      final bowPaint = Paint()
        ..shader =
            LinearGradient(
              colors: [Colors.brown[400]!, Colors.brown[800]!],
            ).createShader(
              Rect.fromPoints(
                Offset(frontHandX, -0.3 * h),
                Offset(frontHandX, 0.3 * h),
              ),
            )
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(bowPath, bowPaint);

      final stringPaint = Paint()
        ..color = Colors.white70
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      final stringPath = Path();
      stringPath.moveTo(frontHandX, -0.3 * h);
      if (drawAmount > 0) {
        stringPath.lineTo(backHandX, backHandY);
      } else {
        stringPath.lineTo(bowBendX, 0);
      }
      stringPath.lineTo(frontHandX, 0.3 * h);
      canvas.drawPath(stringPath, stringPaint);

      if (isArrowNocked || (recoil > 0 && recoil < 0.2)) {
        canvas.save();
        if (isArrowNocked) {
          canvas.translate(arrowPos.dx, arrowPos.dy);
          canvas.rotate(arrowAngle);
        } else if (recoil > 0) {
          double travel = (1 - recoil) * w;
          canvas.translate(backHandX + travel, backHandY);
        }

        final arrowShaft = Paint()
          ..color = Colors.brown[300]!
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset.zero, Offset(0.45 * w, 0), arrowShaft);

        final fletchingPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 2;
        canvas.drawLine(
          Offset.zero,
          Offset(0.05 * w, -0.03 * h),
          fletchingPaint,
        );
        canvas.drawLine(
          Offset.zero,
          Offset(0.05 * w, 0.03 * h),
          fletchingPaint,
        );

        final tipPaint = Paint()
          ..color = weapon == 'Fire Bow'
              ? Colors.deepOrangeAccent
              : Colors.grey[400]!
          ..strokeWidth = weapon == 'Fire Bow' ? 6 : 4
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(0.45 * w, 0), Offset(0.55 * w, 0), tipPaint);

        canvas.restore();
      }
    } else if (weapon == 'Battle Axe') {
      double swingAngle = recoil * (pi / 1.5);

      canvas.save();
      canvas.rotate(swingAngle);

      canvas.drawLine(Offset.zero, Offset(0.3 * w, 0), paint);
      canvas.drawLine(Offset.zero, Offset(0.2 * w, 0.1 * h), paint);

      final handlePaint = Paint()
        ..color = Colors.brown[600]!
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(0.25 * w, -0.1 * h),
        Offset(0.25 * w, 0.4 * h),
        handlePaint,
      );

      final bladePaint = Paint()
        ..color = Colors.grey[400]!
        ..style = PaintingStyle.fill;
      final bladePath = Path();
      
      bladePath.moveTo(0.25 * w, 0.25 * h);
      bladePath.quadraticBezierTo(0.4 * w, 0.2 * h, 0.45 * w, 0.35 * h);
      bladePath.quadraticBezierTo(0.4 * w, 0.5 * h, 0.25 * w, 0.45 * h);
      canvas.drawPath(bladePath, bladePaint);

      canvas.restore();
    } else if (weapon == 'War Hammer') {
      double swingAngle = recoil * (pi / 1.5);

      canvas.save();
      canvas.rotate(swingAngle);

      canvas.drawLine(Offset.zero, Offset(0.35 * w, -0.05 * h), paint);
      canvas.drawLine(Offset.zero, Offset(0.15 * w, 0.05 * h), paint);

      final handlePaint = Paint()
        ..color = Colors.brown[800]!
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(0.25 * w, -0.2 * h),
        Offset(0.25 * w, 0.6 * h),
        handlePaint,
      );

      final headPaint = Paint()
        ..color = Colors.grey[700]!
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0.25 * w, 0.6 * h),
            width: 0.4 * w,
            height: 0.2 * h,
          ),
          const Radius.circular(5),
        ),
        headPaint,
      );

      canvas.restore();
    } else if (weapon == 'Katana') {
      double swingAngle = recoil * (pi / 1.2);

      canvas.save();
      canvas.rotate(swingAngle);

      canvas.drawLine(Offset.zero, Offset(0.3 * w, 0.1 * h), paint);
      canvas.drawLine(Offset.zero, Offset(0.2 * w, 0.2 * h), paint);

      final handlePaint = Paint()
        ..color = Colors.black87
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(0.25 * w, 0.15 * h),
        Offset(0.25 * w, 0.4 * h),
        handlePaint,
      );

      final guardPaint = Paint()
        ..color = Colors.amber
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(0.2 * w, 0.4 * h),
        Offset(0.3 * w, 0.4 * h),
        guardPaint,
      );

      final bladePaint = Paint()
        ..color = Colors.grey[300]!
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;
      final bladePath = Path();
      bladePath.moveTo(0.25 * w, 0.4 * h);
      bladePath.quadraticBezierTo(0.35 * w, 0.6 * h, 0.25 * w, 0.9 * h);
      canvas.drawPath(bladePath, bladePaint);

      canvas.restore();
    } else if (weapon == 'Sniper Rifle') {
      canvas.drawLine(Offset.zero, Offset(0.35 * w, 0.05 * h), paint);
      canvas.drawLine(Offset.zero, Offset(0.15 * w, 0.1 * h), paint);

      canvas.save();
      if (recoil > 0) {
        canvas.translate(-recoil * 10, 0);
      }

      final bodyPaint = Paint()
        ..color = Colors.black87
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(0.1 * w, 0.08 * h),
        Offset(0.4 * w, 0.05 * h),
        bodyPaint,
      );

      final barrelPaint = Paint()
        ..color = Colors.grey[600]!
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(0.4 * w, 0.05 * h),
        Offset(0.8 * w, 0.01 * h),
        barrelPaint,
      );
      
      final scopePaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(0.2 * w, -0.02 * h),
        Offset(0.35 * w, -0.04 * h),
        scopePaint,
      );

      canvas.restore();
    } else if (weapon == 'Assault Rifle') {
      canvas.drawLine(Offset.zero, Offset(0.35 * w, 0.05 * h), paint);
      canvas.drawLine(Offset.zero, Offset(0.15 * w, 0.1 * h), paint);

      final gunPaint = Paint()
        ..color = Colors.grey[900]!
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;
      final barrelPaint = Paint()
        ..color = Colors.grey[700]!
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      double gunRecoil = recoil * -0.05 * w;
      canvas.drawLine(
        Offset(0.05 * w + gunRecoil, 0.1 * h),
        Offset(0.4 * w + gunRecoil, 0.05 * h),
        gunPaint,
      );
      canvas.drawLine(
        Offset(0.4 * w + gunRecoil, 0.05 * h),
        Offset(0.7 * w + gunRecoil, 0.05 * h),
        barrelPaint,
      );

      if (recoil > 0.5) {
        canvas.drawCircle(
          Offset(0.75 * w + gunRecoil, 0.05 * h),
          12 * recoil,
          Paint()..color = Colors.orangeAccent,
        );
      }
    } else if (weapon == 'Shotgun') {
      canvas.drawLine(Offset.zero, Offset(0.4 * w, 0.08 * h), paint);
      canvas.drawLine(Offset.zero, Offset(0.2 * w, 0.15 * h), paint);

      final gunPaint = Paint()
        ..color = Colors.brown[900]!
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.square;
      final barrelPaint = Paint()
        ..color = Colors.grey[800]!
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;

      double gunRecoil = recoil * -0.15 * w;
      canvas.drawLine(
        Offset(0.1 * w + gunRecoil, 0.15 * h),
        Offset(0.3 * w + gunRecoil, 0.08 * h),
        gunPaint,
      );
      canvas.drawLine(
        Offset(0.3 * w + gunRecoil, 0.08 * h),
        Offset(0.65 * w + gunRecoil, 0.08 * h),
        barrelPaint,
      );

      if (recoil > 0.5) {
        canvas.drawCircle(
          Offset(0.75 * w + gunRecoil, 0.08 * h),
          20 * recoil,
          Paint()..color = Colors.yellowAccent,
        );
      }
    } else if (weapon == 'Plasma Cannon') {
      canvas.drawLine(Offset.zero, Offset(0.35 * w, 0.05 * h), paint);
      canvas.drawLine(Offset.zero, Offset(0.15 * w, 0.1 * h), paint);

      double gunRecoil = recoil * -0.05 * w;
      final bodyPaint = Paint()
        ..color = Colors.grey[850]!
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.square;
      
      final glowPaint = Paint()
        ..color = Colors.cyanAccent
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawLine(
        Offset(0.1 * w + gunRecoil, 0.1 * h),
        Offset(0.6 * w + gunRecoil, 0.05 * h),
        bodyPaint,
      );
      
      canvas.drawLine(
        Offset(0.2 * w + gunRecoil, 0.07 * h),
        Offset(0.5 * w + gunRecoil, 0.05 * h),
        glowPaint,
      );

      if (recoil > 0.5) {
        canvas.drawCircle(
          Offset(0.65 * w + gunRecoil, 0.05 * h),
          15 * recoil,
          Paint()..color = Colors.cyanAccent,
        );
      }
    } else if (weapon == 'AK-47') {
      canvas.drawLine(Offset.zero, Offset(0.35 * w, 0.05 * h), paint);
      canvas.drawLine(Offset.zero, Offset(0.15 * w, 0.1 * h), paint);

      double gunRecoil = recoil * -0.05 * w;
      
      // Stock
      final stockPaint = Paint()
        ..color = Colors.brown[700]!
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(0.05 * w + gunRecoil, 0.1 * h),
        Offset(0.2 * w + gunRecoil, 0.05 * h),
        stockPaint,
      );

      // Body & Barrel
      final bodyPaint = Paint()
        ..color = Colors.grey[800]!
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.square;
      final barrelPaint = Paint()
        ..color = Colors.grey[700]!
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(0.2 * w + gunRecoil, 0.05 * h),
        Offset(0.45 * w + gunRecoil, 0.05 * h),
        bodyPaint,
      );
      canvas.drawLine(
        Offset(0.45 * w + gunRecoil, 0.05 * h),
        Offset(0.75 * w + gunRecoil, 0.05 * h),
        barrelPaint,
      );

      // Magazine (Curved)
      final magPaint = Paint()
        ..color = Colors.grey[900]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;
      final magPath = Path();
      magPath.moveTo(0.35 * w + gunRecoil, 0.08 * h);
      magPath.quadraticBezierTo(
        0.4 * w + gunRecoil, 0.15 * h,
        0.3 * w + gunRecoil, 0.2 * h,
      );
      canvas.drawPath(magPath, magPaint);

      // Muzzle flash
      if (recoil > 0.5) {
        canvas.drawCircle(
          Offset(0.8 * w + gunRecoil, 0.05 * h),
          10 * recoil,
          Paint()..color = Colors.deepOrangeAccent,
        );
      }
    } else if (weapon == 'Laser Gun') {
      canvas.drawLine(Offset.zero, Offset(0.35 * w, 0.05 * h), paint);
      canvas.drawLine(Offset.zero, Offset(0.15 * w, 0.1 * h), paint);

      double gunRecoil = recoil * -0.04 * w;
      final cyberPaint = Paint()
        ..color = const Color(0xFF1E1E2E)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(0.08 * w + gunRecoil, 0.08 * h),
        Offset(0.55 * w + gunRecoil, 0.04 * h),
        cyberPaint,
      );
      final energyPaint = Paint()
        ..color = const Color(0xFFE040FB)
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawLine(
        Offset(0.2 * w + gunRecoil, 0.06 * h),
        Offset(0.45 * w + gunRecoil, 0.04 * h),
        energyPaint,
      );
      final lensPaint = Paint()
        ..color = const Color(0xFF00E5FF)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.square;
      canvas.drawLine(
        Offset(0.55 * w + gunRecoil, 0.04 * h),
        Offset(0.72 * w + gunRecoil, 0.04 * h),
        lensPaint,
      );
      if (recoil > 0.3) {
        canvas.drawCircle(
          Offset(0.75 * w + gunRecoil, 0.04 * h),
          14 * recoil,
          Paint()
            ..color = const Color(0xFF00E5FF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    } else if (weapon == 'Grenade Launcher') {
      canvas.drawLine(Offset.zero, Offset(0.35 * w, 0.08 * h), paint);
      canvas.drawLine(Offset.zero, Offset(0.15 * w, 0.15 * h), paint);

      double gunRecoil = recoil * -0.12 * w;
      final bodyPaint = Paint()
        ..color = const Color(0xFF2E3440)
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(0.08 * w + gunRecoil, 0.12 * h),
        Offset(0.35 * w + gunRecoil, 0.06 * h),
        bodyPaint,
      );
      final drumPaint = Paint()
        ..color = const Color(0xFF4C566A)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(0.28 * w + gunRecoil, 0.12 * h), 12, drumPaint);
      canvas.drawCircle(Offset(0.28 * w + gunRecoil, 0.12 * h), 6, Paint()..color = const Color(0xFFD08770));
      final barrelPaint = Paint()
        ..color = const Color(0xFF1E222A)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.square;
      canvas.drawLine(
        Offset(0.35 * w + gunRecoil, 0.06 * h),
        Offset(0.68 * w + gunRecoil, 0.05 * h),
        barrelPaint,
      );
      if (recoil > 0.5) {
        canvas.drawCircle(
          Offset(0.72 * w + gunRecoil, 0.05 * h),
          18 * recoil,
          Paint()..color = Colors.deepOrangeAccent,
        );
      }
    } else if (weapon == 'Minigun') {
      canvas.drawLine(Offset.zero, Offset(0.35 * w, 0.1 * h), paint);
      canvas.drawLine(Offset.zero, Offset(0.15 * w, 0.15 * h), paint);

      double gunRecoil = recoil * -0.03 * w;
      final framePaint = Paint()
        ..color = const Color(0xFF212529)
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(0.05 * w + gunRecoil, 0.14 * h),
        Offset(0.35 * w + gunRecoil, 0.08 * h),
        framePaint,
      );
      final barrelUpper = Paint()..color = Colors.grey[700]!..strokeWidth = 4;
      final barrelMid = Paint()..color = Colors.grey[850]!..strokeWidth = 4;
      final barrelLower = Paint()..color = Colors.grey[600]!..strokeWidth = 4;
      canvas.drawLine(Offset(0.35 * w + gunRecoil, 0.04 * h), Offset(0.8 * w + gunRecoil, 0.04 * h), barrelUpper);
      canvas.drawLine(Offset(0.35 * w + gunRecoil, 0.08 * h), Offset(0.82 * w + gunRecoil, 0.08 * h), barrelMid);
      canvas.drawLine(Offset(0.35 * w + gunRecoil, 0.12 * h), Offset(0.8 * w + gunRecoil, 0.12 * h), barrelLower);
      final ringPaint = Paint()..color = const Color(0xFFFFB300)..strokeWidth = 3;
      canvas.drawLine(Offset(0.55 * w + gunRecoil, 0.03 * h), Offset(0.55 * w + gunRecoil, 0.13 * h), ringPaint);
      canvas.drawLine(Offset(0.75 * w + gunRecoil, 0.03 * h), Offset(0.75 * w + gunRecoil, 0.13 * h), ringPaint);
      final ammoPaint = Paint()..color = Colors.amber[700]!..strokeWidth = 6..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0.15 * w + gunRecoil, 0.18 * h), Offset(0.25 * w + gunRecoil, 0.15 * h), ammoPaint);
      if (recoil > 0.2) {
        canvas.drawCircle(Offset(0.85 * w + gunRecoil, 0.08 * h), 14 * recoil, Paint()..color = Colors.amberAccent);
      }
    } else if (weapon == 'Flamethrower') {
      canvas.drawLine(Offset.zero, Offset(0.35 * w, 0.08 * h), paint);
      canvas.drawLine(Offset.zero, Offset(0.15 * w, 0.15 * h), paint);

      double gunRecoil = recoil * -0.02 * w;
      final tankPaint = Paint()..color = const Color(0xFFC62828)..strokeWidth = 14..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0.15 * w + gunRecoil, 0.18 * h), Offset(0.4 * w + gunRecoil, 0.16 * h), tankPaint);
      final pipePaint = Paint()..color = const Color(0xFF424242)..strokeWidth = 7..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0.1 * w + gunRecoil, 0.08 * h), Offset(0.75 * w + gunRecoil, 0.06 * h), pipePaint);
      final nozzlePaint = Paint()..color = const Color(0xFFB0BEC5)..strokeWidth = 10..strokeCap = StrokeCap.square;
      canvas.drawLine(Offset(0.72 * w + gunRecoil, 0.06 * h), Offset(0.8 * w + gunRecoil, 0.06 * h), nozzlePaint);
      canvas.drawCircle(
        Offset(0.84 * w + gunRecoil, 0.06 * h),
        recoil > 0.2 ? 18 * recoil : 6,
        Paint()..color = Colors.deepOrangeAccent..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    } else if (weapon == 'Rocket Launcher') {
      canvas.drawLine(Offset.zero, Offset(0.35 * w, 0.05 * h), paint);
      canvas.drawLine(Offset.zero, Offset(0.15 * w, 0.12 * h), paint);

      double gunRecoil = recoil * -0.15 * w;
      final tubePaint = Paint()
        ..color = const Color(0xFF33691E)
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(-0.15 * w + gunRecoil, 0.05 * h),
        Offset(0.6 * w + gunRecoil, 0.02 * h),
        tubePaint,
      );
      final gripPaint = Paint()..color = Colors.black87..strokeWidth = 8;
      canvas.drawLine(Offset(0.2 * w + gunRecoil, 0.05 * h), Offset(0.2 * w + gunRecoil, 0.15 * h), gripPaint);
      canvas.drawLine(Offset(0.3 * w + gunRecoil, -0.05 * h), Offset(0.38 * w + gunRecoil, -0.05 * h), Paint()..color = Colors.grey[800]!..strokeWidth = 5);
      final warheadPaint = Paint()..color = const Color(0xFFFF5722);
      final warheadPath = Path();
      warheadPath.moveTo(0.6 * w + gunRecoil, -0.02 * h);
      warheadPath.lineTo(0.78 * w + gunRecoil, 0.02 * h);
      warheadPath.lineTo(0.6 * w + gunRecoil, 0.06 * h);
      warheadPath.close();
      canvas.drawPath(warheadPath, warheadPaint);
      if (recoil > 0.4) {
        canvas.drawCircle(Offset(0.82 * w + gunRecoil, 0.02 * h), 22 * recoil, Paint()..color = Colors.deepOrangeAccent);
        canvas.drawCircle(Offset(-0.2 * w + gunRecoil, 0.05 * h), 16 * recoil, Paint()..color = Colors.white70);
      }
    } else if (weapon == 'Tesla Cannon') {
      canvas.drawLine(Offset.zero, Offset(0.35 * w, 0.06 * h), paint);
      canvas.drawLine(Offset.zero, Offset(0.15 * w, 0.12 * h), paint);

      double gunRecoil = recoil * -0.06 * w;
      final framePaint = Paint()..color = const Color(0xFF263238)..strokeWidth = 14..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0.08 * w + gunRecoil, 0.08 * h), Offset(0.4 * w + gunRecoil, 0.05 * h), framePaint);
      final prongPaint = Paint()..color = const Color(0xFF90A4AE)..strokeWidth = 4..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0.4 * w + gunRecoil, 0.02 * h), Offset(0.72 * w + gunRecoil, 0.02 * h), prongPaint);
      canvas.drawLine(Offset(0.4 * w + gunRecoil, 0.08 * h), Offset(0.72 * w + gunRecoil, 0.08 * h), prongPaint);
      for (int i = 0; i < 3; i++) {
        double cx = (0.46 + i * 0.09) * w + gunRecoil;
        canvas.drawLine(
          Offset(cx, 0.01 * h),
          Offset(cx, 0.09 * h),
          Paint()..color = const Color(0xFF00E5FF)..strokeWidth = 5..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
      if (recoil > 0.2) {
        canvas.drawCircle(Offset(0.76 * w + gunRecoil, 0.05 * h), 16 * recoil, Paint()..color = const Color(0xFF00E5FF));
      }
    } else if (weapon == 'Crossbow') {
      canvas.drawLine(Offset.zero, Offset(0.35 * w, 0.05 * h), paint);
      canvas.drawLine(Offset.zero, Offset(0.15 * w, 0.1 * h), paint);

      double gunRecoil = recoil * -0.08 * w;
      final stockPaint = Paint()..color = const Color(0xFF4E342E)..strokeWidth = 8..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0.05 * w + gunRecoil, 0.08 * h), Offset(0.55 * w + gunRecoil, 0.04 * h), stockPaint);
      final prodPaint = Paint()..color = const Color(0xFF37474F)..strokeWidth = 6..strokeCap = StrokeCap.round;
      final prodPath = Path();
      prodPath.moveTo(0.52 * w + gunRecoil, -0.22 * h);
      prodPath.quadraticBezierTo(0.6 * w + gunRecoil, 0.04 * h, 0.52 * w + gunRecoil, 0.28 * h);
      canvas.drawPath(prodPath, prodPaint);
      final stringPaint = Paint()..color = Colors.white70..strokeWidth = 1.5;
      canvas.drawLine(Offset(0.52 * w + gunRecoil, -0.22 * h), Offset(0.35 * w + gunRecoil, 0.04 * h), stringPaint);
      canvas.drawLine(Offset(0.52 * w + gunRecoil, 0.28 * h), Offset(0.35 * w + gunRecoil, 0.04 * h), stringPaint);
      if (shootTimer <= 0) {
        canvas.drawLine(Offset(0.3 * w + gunRecoil, 0.04 * h), Offset(0.62 * w + gunRecoil, 0.04 * h), Paint()..color = Colors.cyanAccent..strokeWidth = 3);
      }
    } else if (weapon == 'Chainsaw') {
      double swingOffset = sin(recoil * pi) * 0.1 * h;
      canvas.drawLine(Offset.zero, Offset(0.3 * w, 0.1 * h + swingOffset), paint);
      canvas.drawLine(Offset.zero, Offset(0.15 * w, 0.15 * h + swingOffset), paint);

      final enginePaint = Paint()..color = const Color(0xFFF57C00)..strokeWidth = 16..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0.1 * w, 0.12 * h + swingOffset), Offset(0.35 * w, 0.08 * h + swingOffset), enginePaint);
      final barPaint = Paint()..color = const Color(0xFFB0BEC5)..strokeWidth = 12..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0.35 * w, 0.08 * h + swingOffset), Offset(0.75 * w, 0.05 * h + swingOffset), barPaint);
      final teethPaint = Paint()..color = Colors.black87..strokeWidth = 3;
      for (int i = 0; i < 6; i++) {
        double tx = (0.38 + i * 0.06) * w;
        canvas.drawLine(Offset(tx, 0.02 * h + swingOffset), Offset(tx + 4, 0.07 * h + swingOffset), teethPaint);
        canvas.drawLine(Offset(tx, 0.1 * h + swingOffset), Offset(tx + 4, 0.07 * h + swingOffset), teethPaint);
      }
      if (recoil > 0.2) {
        canvas.drawCircle(Offset(0.78 * w, 0.05 * h + swingOffset), 12 * recoil, Paint()..color = Colors.yellowAccent);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PlayerPainter oldDelegate) {
    return oldDelegate.aimAngle != aimAngle ||
        oldDelegate.recoil != recoil ||
        oldDelegate.weapon != weapon ||
        oldDelegate.shootTimer != shootTimer;
  }
}

class ZombiePainter extends CustomPainter {
  final int health;
  final int maxHealth;
  final Color baseColor;
  final String type;
  final String weapon;
  final double swingProgress;
  final double walkPhase;
  final bool isDying;
  final bool isFrozen;
  ZombiePainter(
    this.health,
    this.maxHealth,
    this.baseColor,
    this.type,
    this.weapon,
    this.swingProgress,
    this.walkPhase,
    this.isDying,
    this.isFrozen,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    double healthRatio = health / maxHealth;
    Color color = healthRatio > 0.35
        ? baseColor.withValues(alpha: 0.3 + 0.7 * healthRatio)
        : AppTheme.dangerColor;
    
    if (isFrozen && !isDying) {
      color = AppTheme.primaryColor.withValues(alpha: 0.8);
    }

    canvas.save();
    if (type == 'tank') {
      canvas.translate(-size.width * 0.1, -size.height * 0.1);
      canvas.scale(1.2, 1.2);
    } else if (type == 'runner') {
      canvas.translate(size.width * 0.1, size.height * 0.1);
      canvas.scale(0.8, 0.8);
    }

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    _drawStickmanBody(canvas, size, shadowPaint, const Offset(2, 4));
    _drawStickmanBody(canvas, size, paint, Offset.zero);
    _drawStickmanBody(canvas, size, highlightPaint, const Offset(-1.5, -1.5));

    double bob = isDying ? 0 : sin(walkPhase * 2) * 3;
    final headCenter = Offset(size.width * 0.5, size.height * 0.2 + bob);
    final headRadius = 16.0;

    canvas.drawCircle(
      headCenter + const Offset(2, 4),
      headRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final headPaint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0.5)],
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
      ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(headCenter, headRadius, headPaint);

    if (!isDying) {
      final eyeGlowPaint = Paint()
        ..color = Colors.redAccent
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final eyePaint = Paint()..color = Colors.red[100]!;

      Offset leftEye = Offset(size.width * 0.4, size.height * 0.18 + bob);
      Offset rightEye = Offset(size.width * 0.6, size.height * 0.18 + bob);

      canvas.drawCircle(leftEye, 6, eyeGlowPaint);
      canvas.drawCircle(rightEye, 6, eyeGlowPaint);
      canvas.drawCircle(leftEye, 2.5, eyePaint);
      canvas.drawCircle(rightEye, 2.5, eyePaint);
    } else {
      // Dead eyes
      final deadEyePaint = Paint()
        ..color = Colors.black87
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      Offset leftEye = Offset(size.width * 0.4, size.height * 0.18 + bob);
      Offset rightEye = Offset(size.width * 0.6, size.height * 0.18 + bob);

      canvas.drawLine(
        leftEye + const Offset(-3, -3),
        leftEye + const Offset(3, 3),
        deadEyePaint,
      );
      canvas.drawLine(
        leftEye + const Offset(-3, 3),
        leftEye + const Offset(3, -3),
        deadEyePaint,
      );

      canvas.drawLine(
        rightEye + const Offset(-3, -3),
        rightEye + const Offset(3, 3),
        deadEyePaint,
      );
      canvas.drawLine(
        rightEye + const Offset(-3, 3),
        rightEye + const Offset(3, -3),
        deadEyePaint,
      );
    }

    _drawArmAndWeapon(canvas, size, paint, shadowPaint, highlightPaint);

    canvas.restore();
  }

  void _drawStickmanBody(Canvas canvas, Size size, Paint paint, Offset offset) {
    double bob = isDying ? 0 : sin(walkPhase * 2) * 3;
    double legSpread = isDying ? 0.6 : sin(walkPhase) * 0.4;

    Offset pelvis = Offset(
      size.width * 0.5,
      size.height * 0.65 + bob + (isDying ? 15 : 0),
    );
    Offset neck = Offset(
      size.width * 0.5,
      size.height * 0.2 + 16 + bob + (isDying ? 15 : 0),
    );

    canvas.drawLine(neck + offset, pelvis + offset, paint);

    Offset leftFoot = Offset(
      size.width * 0.5 - sin(legSpread) * size.width * 0.3,
      size.height * 0.95 + (isDying ? 5 : 0),
    );
    Offset rightFoot = Offset(
      size.width * 0.5 + sin(legSpread) * size.width * 0.3,
      size.height * 0.95 + (isDying ? 5 : 0),
    );

    canvas.drawLine(pelvis + offset, leftFoot + offset, paint);
    canvas.drawLine(pelvis + offset, rightFoot + offset, paint);

    if (weapon == 'sword' || weapon == 'axe' || weapon == 'knife') {
      canvas.drawLine(
        Offset(
              size.width * 0.5,
              size.height * 0.35 + bob + (isDying ? 15 : 0),
            ) +
            offset,
        Offset(
              size.width * 0.8,
              size.height * 0.45 + bob + (isDying ? 25 : 0),
            ) +
            offset,
        paint,
      );
    } else {
      canvas.drawLine(
        Offset(
              size.width * 0.5,
              size.height * 0.35 + bob + (isDying ? 15 : 0),
            ) +
            offset,
        Offset(size.width * 0.8, size.height * 0.5 + bob + (isDying ? 25 : 0)) +
            offset,
        paint,
      );
    }
  }

  void _drawArmAndWeapon(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint shadowPaint,
    Paint highlightPaint,
  ) {
    canvas.save();
    double bob = isDying ? 15 : sin(walkPhase * 2) * 3;
    double pivotX = size.width * 0.5;
    double pivotY = size.height * 0.35 + bob;

    double lungeAngle = (swingProgress > 0)
        ? sin((swingProgress / 0.3) * pi) * -0.2
        : 0;
    double swingAngle = (swingProgress > 0)
        ? sin((swingProgress / 0.3) * pi) * 1.5
        : (isDying ? 0.8 : 0);

    canvas.translate(pivotX, pivotY);
    canvas.rotate(swingAngle + lungeAngle);
    canvas.translate(-pivotX, -pivotY);

    Offset armStart = Offset(size.width * 0.5, size.height * 0.35 + bob);
    Offset armEnd = Offset(
      size.width * 0.2,
      size.height * (weapon == 'bow' ? 0.5 : 0.6) + bob,
    );

    canvas.drawLine(
      armStart + const Offset(2, 4),
      armEnd + const Offset(2, 4),
      shadowPaint,
    );
    canvas.drawLine(armStart, armEnd, paint);
    canvas.drawLine(
      armStart + const Offset(-1.5, -1.5),
      armEnd + const Offset(-1.5, -1.5),
      highlightPaint,
    );

    canvas.translate(0, bob);
    if (weapon == 'sword') {
      _drawSword(canvas, size);
    } else if (weapon == 'axe') {
      _drawAxe(canvas, size);
    } else if (weapon == 'knife') {
      _drawKnife(canvas, size);
    } else {
      _drawBow(canvas, size);
    }

    canvas.restore();
  }

  void _drawBow(Canvas canvas, Size size) {
    final bowPaint = Paint()
      ..color = Colors.brown[600]!
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final bowShadow = Paint()
      ..color = Colors.black87
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final bowPath = Path();
    bowPath.moveTo(size.width * 0.2, size.height * 0.2);
    bowPath.quadraticBezierTo(
      size.width * 0.0,
      size.height * 0.5,
      size.width * 0.2,
      size.height * 0.8,
    );

    canvas.drawPath(bowPath.shift(const Offset(2, 2)), bowShadow);
    canvas.drawPath(bowPath, bowPaint);

    final stringPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.2, size.height * 0.8),
      stringPaint,
    );
  }

  void _drawSword(Canvas canvas, Size size) {
    Offset hand = Offset(size.width * 0.2, size.height * 0.6);
    Offset tip = Offset(-size.width * 0.1, size.height * 0.85);
    Offset pommel = Offset(size.width * 0.28, size.height * 0.53);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawLine(
      hand + const Offset(2, 2),
      tip + const Offset(2, 2),
      shadowPaint,
    );

    final bladePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.purple[300]!, Colors.purple[700]!],
      ).createShader(Rect.fromPoints(hand, tip))
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(hand, tip, bladePaint);

    canvas.drawLine(
      hand,
      tip,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    final guardPaint = Paint()
      ..color = Colors.amber[700]!
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      hand + const Offset(-6, -4),
      hand + const Offset(6, 4),
      guardPaint,
    );

    final handlePaint = Paint()
      ..color = Colors.brown[800]!
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(hand, pommel, handlePaint);
  }

  void _drawAxe(Canvas canvas, Size size) {
    Offset hand = Offset(size.width * 0.2, size.height * 0.6);
    Offset tip = Offset(-size.width * 0.1, size.height * 0.85);

    // Handle
    final handlePaint = Paint()
      ..color = Colors.brown[800]!
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(hand + const Offset(0.2 * 30, -0.3 * 30), tip, handlePaint);

    // Axe Head
    final headPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.fill;
    final headPath = Path();
    headPath.moveTo(-size.width * 0.0, size.height * 0.7);
    headPath.quadraticBezierTo(
      -size.width * 0.3,
      size.height * 0.65,
      -size.width * 0.2,
      size.height * 0.8,
    );
    headPath.quadraticBezierTo(
      -size.width * 0.05,
      size.height * 0.85,
      -size.width * 0.0,
      size.height * 0.7,
    );
    canvas.drawPath(headPath, headPaint);

    // Highlight
    canvas.drawPath(
      headPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawKnife(Canvas canvas, Size size) {
    Offset hand = Offset(size.width * 0.2, size.height * 0.6);
    Offset tip = Offset(size.width * 0.05, size.height * 0.75);

    // Handle
    final handlePaint = Paint()
      ..color = Colors.grey[900]!
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      hand,
      Offset(size.width * 0.1, size.height * 0.65),
      handlePaint,
    );

    // Blade
    final bladePaint = Paint()
      ..shader = LinearGradient(colors: [Colors.grey[300]!, Colors.grey[600]!])
          .createShader(
            Rect.fromPoints(Offset(size.width * 0.1, size.height * 0.65), tip),
          )
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.65),
      tip,
      bladePaint,
    );

    // Highlight
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.65),
      tip,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class VirtualJoystick extends StatefulWidget {
  final ValueChanged<Offset> onMove;
  final VoidCallback onEnd;
  const VirtualJoystick({super.key, required this.onMove, required this.onEnd});
  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _position = Offset.zero;
  final double _radius = 60.0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) => _updatePosition(event.localPosition),
      onPointerMove: (event) => _updatePosition(event.localPosition),
      onPointerUp: (event) {
        setState(() => _position = Offset.zero);
        widget.onEnd();
      },
      onPointerCancel: (event) {
        setState(() => _position = Offset.zero);
        widget.onEnd();
      },
      child: Container(
        width: _radius * 2,
        height: _radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF374151), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: const RadialGradient(
            colors: [Color(0xFF1E222A), Color(0xFF0E1116)],
            radius: 0.85,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Tactical Directional Markers
            Positioned(
              top: 6,
              child: Icon(
                Icons.arrow_drop_up,
                color: const Color(0xFFFFB300).withOpacity(0.6),
                size: 22,
              ),
            ),
            Positioned(
              bottom: 6,
              child: Icon(
                Icons.arrow_drop_down,
                color: const Color(0xFFFFB300).withOpacity(0.6),
                size: 22,
              ),
            ),
            Positioned(
              left: 6,
              child: Icon(
                Icons.arrow_left,
                color: const Color(0xFFFFB300).withOpacity(0.6),
                size: 22,
              ),
            ),
            Positioned(
              right: 6,
              child: Icon(
                Icons.arrow_right,
                color: const Color(0xFFFFB300).withOpacity(0.6),
                size: 22,
              ),
            ),

            // Knurled Steel Thumbstick Knob
            Transform.translate(
              offset: _position,
              child: Container(
                width: _radius,
                height: _radius,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.8), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.85),
                      blurRadius: 10,
                      offset: const Offset(2, 4),
                    ),
                    BoxShadow(
                      color: const Color(0xFFFFB300).withOpacity(0.35),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                  gradient: const RadialGradient(
                    colors: [Color(0xFF374151), Color(0xFF181B22)],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: _radius * 0.38,
                    height: _radius * 0.38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111418),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFB300),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updatePosition(Offset localPosition) {
    Offset center = Offset(_radius, _radius);
    Offset offset = localPosition - center;
    double distance = offset.distance;

    if (distance > _radius / 2) {
      offset = Offset.fromDirection(offset.direction, _radius / 2);
    }

    setState(() {
      _position = offset;
    });

    widget.onMove(offset / (_radius / 2));
  }
}

class LightningSkillPainter extends CustomPainter {
  final double playerX;
  final double playerY;
  final List<Offset> targets;

  LightningSkillPainter({
    required this.playerX,
    required this.playerY,
    required this.targets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final random = Random();
    final lightningCore = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final lightningGlow = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.8)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    for (var target in targets) {
      for (int i = 0; i < 2; i++) {
        Path lPath = Path();
        lPath.moveTo(playerX, playerY - 40);

        double currentX = playerX;
        double currentY = playerY - 40;

        int segments = 6;
        for (int j = 1; j <= segments; j++) {
          double nextX =
              playerX +
              (target.dx - playerX) * (j / segments) +
              (random.nextDouble() - 0.5) * 60;
          double nextY =
              (playerY - 40) +
              (target.dy - (playerY - 40)) * (j / segments) +
              (random.nextDouble() - 0.5) * 60;

          if (j == segments) {
            nextX = target.dx;
            nextY = target.dy;
          }
          lPath.lineTo(nextX, nextY);
          currentX = nextX;
          currentY = nextY;
        }

        canvas.drawPath(lPath, lightningGlow);
        canvas.drawPath(lPath, lightningCore);

        if (random.nextBool()) {
          Path branch = Path();
          branch.moveTo(
            currentX - (target.dx - playerX) * 0.2,
            currentY - (target.dy - playerY) * 0.2,
          );
          branch.lineTo(
            currentX + (random.nextDouble() - 0.5) * 100,
            currentY + (random.nextDouble() - 0.5) * 100,
          );
          canvas.drawPath(branch, lightningGlow);
          canvas.drawPath(branch, lightningCore);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CyberClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    double cut = 12.0;
    path.moveTo(cut, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - cut);
    path.lineTo(size.width - cut, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, cut);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BattlefieldArenaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF374151).withOpacity(0.22)
      ..strokeWidth = 1.0;

    const double step = 60.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Crosshairs at grid points
    final crossPaint = Paint()
      ..color = const Color(0xFFFF5722).withOpacity(0.20)
      ..strokeWidth = 1.2;

    for (double x = step * 2; x < size.width; x += step * 3) {
      for (double y = step * 2; y < size.height; y += step * 3) {
        canvas.drawLine(Offset(x - 5, y), Offset(x + 5, y), crossPaint);
        canvas.drawLine(Offset(x, y - 5), Offset(x, y + 5), crossPaint);
      }
    }

    // Perimeter Hazard Warning Borders
    final hazardPaint = Paint()
      ..color = const Color(0xFFFF9800).withOpacity(0.25)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final perimeterRect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    canvas.drawRect(perimeterRect, hazardPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LowHealthVignettePainter extends CustomPainter {
  final int health;
  LowHealthVignettePainter({required this.health});

  @override
  void paint(Canvas canvas, Size size) {
    double pulse = (sin(DateTime.now().millisecondsSinceEpoch / 250.0) + 1.0) / 2.0;
    double maxOpacity = health <= 15 ? 0.65 : 0.40;
    double opacity = (0.2 + pulse * (maxOpacity - 0.2)).clamp(0.0, 1.0);

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.95,
        colors: [
          Colors.transparent,
          Colors.red[900]!.withOpacity(opacity * 0.4),
          const Color(0xFFFF1744).withOpacity(opacity),
        ],
        stops: const [0.45, 0.8, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TacticalRadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ringPaint = Paint()
      ..color = const Color(0xFF00E676).withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius * 0.33, ringPaint);
    canvas.drawCircle(center, radius * 0.66, ringPaint);
    canvas.drawCircle(center, radius - 2, ringPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF00E676).withOpacity(0.15)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), linePaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.2)
      ..strokeWidth = 1;
    double step = 20;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CrimsonAshEmbersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final ms = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final random = Random(42);

    for (int i = 0; i < 32; i++) {
      double seedX = random.nextDouble();
      double speed = 0.15 + random.nextDouble() * 0.35;
      double emberSize = 1.8 + random.nextDouble() * 3.5;
      double sway = sin(ms * 1.5 + i) * 15.0;

      double y = (1.0 - ((ms * speed + seedX) % 1.0)) * size.height;
      double x = (seedX * size.width + sway).clamp(0.0, size.width);
      double opacity = sin((y / size.height) * pi).clamp(0.0, 1.0);

      Color col = (i % 3 == 0)
          ? const Color(0xFFFF1744).withOpacity(opacity * 0.8)
          : (i % 3 == 1)
              ? const Color(0xFFFF6D00).withOpacity(opacity * 0.75)
              : const Color(0xFFFF5252).withOpacity(opacity * 0.6);

      final paint = Paint()
        ..color = col
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, emberSize * 0.8);

      canvas.drawCircle(Offset(x, y), emberSize, paint);
      canvas.drawCircle(
        Offset(x, y),
        emberSize * 0.4,
        Paint()..color = Colors.white.withOpacity(opacity * 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class ApexDronePainter extends CustomPainter {
  final double phase;
  ApexDronePainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 1. Blue Plasma Thrusters
    final thrusterPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    double flameLength = 8 + sin(phase * 4) * 4;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 14, cy + 18 + flameLength / 2), width: 6, height: flameLength),
      thrusterPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 14, cy + 18 + flameLength / 2), width: 6, height: flameLength),
      thrusterPaint,
    );

    // 2. Drone Chassis Wings (Delta Stealth shape)
    final chassisPath = Path()
      ..moveTo(cx, cy - 18)
      ..lineTo(cx + 24, cy + 14)
      ..lineTo(cx + 12, cy + 10)
      ..lineTo(cx, cy + 15)
      ..lineTo(cx - 12, cy + 10)
      ..lineTo(cx - 24, cy + 14)
      ..close();

    final chassisPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawPath(chassisPath, chassisPaint);

    final chassisBorder = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(chassisPath, chassisBorder);

    // 3. Twin Plasma Cannon Pods
    final cannonPaint = Paint()..color = const Color(0xFF38BDF8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 18, cy + 2), width: 5, height: 16), const Radius.circular(2)),
      cannonPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 18, cy + 2), width: 5, height: 16), const Radius.circular(2)),
      cannonPaint,
    );

    // 4. Central Optic Sensor Eye
    final eyeGlow = Paint()
      ..color = const Color(0xFF00E676).withOpacity(0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(cx, cy - 2), 6, eyeGlow);

    final eyeCore = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy - 2), 3, eyeCore);
  }

  @override
  bool shouldRepaint(covariant ApexDronePainter oldDelegate) => true;
}
