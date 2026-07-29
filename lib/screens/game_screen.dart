
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../utils/app_theme.dart';
import 'reward_screen.dart';

class Projectile {
  double x, y;
  double dx = 0;
  double dy = 0;
  String type; 
  bool isPlayer;
  
  Projectile(this.x, this.y, double targetX, double targetY, this.type, {this.isPlayer = true}) {
    double angle = atan2(targetY - y, targetX - x);
    double speed = type == 'arrow' ? 1200.0 : (type == 'bullet' ? 2500.0 : (type == 'zombie_arrow' ? 400.0 : 1800.0));
    if (type == 'pellet') {
       angle += (Random().nextDouble() - 0.5) * 0.4;
    }
    dx = cos(angle) * speed;
    dy = sin(angle) * speed;
  }
}

class BloodParticle {
  double x, y;
  double dx, dy;
  double life;
  double maxLife;
  double size;

  BloodParticle(this.x, this.y, this.dx, this.dy, this.life, this.size) : maxLife = life;
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
    } else {
      health = 3;
      maxHealth = 3;
      color = Colors.primaries[Random().nextInt(Colors.primaries.length)];
    }
    shootTimer = 1.0 + Random().nextDouble() * 2.0;
  }
}

class GameScreen extends StatefulWidget {
  final int level;
  const GameScreen({super.key, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
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
  bool _showLightning = false;
  List<Offset> _lightningTargets = [];

  @override
  void initState() {
    super.initState();
    _targetKills = 10 + (widget.level * 5); 
    
    _gameLoop = AnimationController(vsync: this, duration: const Duration(days: 99));
    _gameLoop.addListener(_update);
    _gameLoop.forward();
  }

  void _update() {
    final now = DateTime.now();
    final dt = now.difference(_lastUpdate).inMilliseconds / 1000.0;
    _lastUpdate = now;
    
    if (_gameOver || _won || _screenWidth == 0) return;
    
    final gameState = Provider.of<GameStateProvider>(context, listen: false);
    String currentWeapon = gameState.currentWeapon;

    setState(() {
      // 0. Move Player
      _playerX += _joystickOffset.dx * _playerSpeed * dt;
      _playerY += _joystickOffset.dy * _playerSpeed * dt;

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

      // Move Projectiles
      for (var p in _projectiles) {
        p.x += p.dx * dt;
        p.y += p.dy * dt;
      }
      _projectiles.removeWhere((p) => p.y < -50 || p.y > _screenHeight + 50 || p.x < -50 || p.x > _screenWidth + 50);

      // Move Blood Particles
      for (var bp in _bloodParticles) {
        bp.x += bp.dx * dt;
        bp.y += bp.dy * dt;
        bp.dy += 400 * dt; // gravity
        bp.life -= dt;
      }
      _bloodParticles.removeWhere((bp) => bp.life <= 0);
      
      List<Zombie> zombiesToRemove = [];
      // 2. Move Zombies and Shoot
      for (var zombie in _zombies) {
        if (zombie.isDying) {
          zombie.deathTimer -= dt;
          
          // Drip blood slowly
          if (_random.nextDouble() > 0.6) {
             _bloodParticles.add(BloodParticle(
                zombie.x + (_random.nextDouble() - 0.5) * 20,
                zombie.y + (_random.nextDouble() - 0.5) * 40,
                (_random.nextDouble() - 0.5) * 30,
                (_random.nextDouble() - 0.5) * 30 + 50,
                0.3 + _random.nextDouble() * 0.5,
                2.0 + _random.nextDouble() * 3.0,
             ));
          }
          
          if (zombie.deathTimer <= 0) {
            zombiesToRemove.add(zombie);
            _kills++;
            if (_kills >= _targetKills) {
              _won = true;
              _gameLoop.stop();
              _winLevel();
            }
          }
          continue;
        }

        if (zombie.swingTimer > 0) {
          zombie.swingTimer -= dt;
        }

        zombie.isFacingLeft = _playerX < zombie.x;

        double dist = sqrt(pow(_playerY - zombie.y, 2) + pow(_playerX - zombie.x, 2));
        double attackRange = (zombie.weapon == 'bow') ? 300.0 : 60.0;
        
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
              _projectiles.add(Projectile(zombie.x, zombie.y, _playerX, _playerY - 50, 'zombie_arrow', isPlayer: false));
            }
          } else {
            if (dist <= attackRange + 20) {
              zombie.swingTimer = 0.3; // Swing animation duration
              _health -= (zombie.weapon == 'axe' || zombie.weapon == 'sword') ? 10 : 5;
              if (_health <= 0) {
                _health = 0;
                _gameOver = true;
                _gameLoop.stop();
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
             _health -= 5;
             if (_health <= 0) {
               _health = 0;
               _gameOver = true;
               _gameLoop.stop();
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
            
            int damage = p.type == 'fire_arrow' ? 3 : 1; 
            
            if (p.y < zNeck) {
              zombie.health -= p.type == 'pellet' ? 2 : (p.type == 'fire_arrow' ? 10 : 3); 
            } else {
              zombie.health -= damage;
            }
            
            if (zombie.health <= 0) {
              zombie.health = 0;
              zombie.isDying = true;
              
              // Initial blood splatter
              for (int i = 0; i < 15; i++) {
                 _bloodParticles.add(BloodParticle(
                    zombie.x, zombie.y - 10,
                    (_random.nextDouble() - 0.5) * 200,
                    (_random.nextDouble() - 0.5) * 200 - 50,
                    0.5 + _random.nextDouble(),
                    3.0 + _random.nextDouble() * 4.0,
                 ));
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
    
    int typeChance = _random.nextInt(10);
    String type = 'normal';
    String weapon = 'bow';
    if (typeChance > 7) {
      type = 'tank';
      weapon = _random.nextBool() ? 'sword' : 'axe';
    } else if (typeChance > 5) {
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
    
    _targetAimAngle = atan2(_aimTarget.dy - shoulderY, _aimTarget.dx - shoulderX);
    _recoil = 1.0;

    if (weapon == 'Bow') {
      _projectiles.add(Projectile(shoulderX, shoulderY, _aimTarget.dx, _aimTarget.dy, 'arrow'));
      _shootTimer = 0.6;
    } else if (weapon == 'Fire Bow') {
      _projectiles.add(Projectile(shoulderX, shoulderY, _aimTarget.dx, _aimTarget.dy, 'fire_arrow'));
      _shootTimer = 0.6;
    } else if (weapon == 'Assault Rifle') {
      _projectiles.add(Projectile(shoulderX, shoulderY, _aimTarget.dx, _aimTarget.dy, 'bullet'));
      _shootTimer = 0.1; 
    } else if (weapon == 'Shotgun') {
      for (int i=0; i<5; i++) {
        _projectiles.add(Projectile(shoulderX, shoulderY, _aimTarget.dx, _aimTarget.dy, 'pellet'));
      }
      _isShooting = false; 
    } else if (weapon == 'Battle Axe') {
      _performMeleeAttack(shoulderX, shoulderY, 150.0, 3, false);
      _isShooting = false;
    } else if (weapon == 'War Hammer') {
      _performMeleeAttack(shoulderX, shoulderY, 200.0, 10, true);
      _isShooting = false;
    }
  }

  void _performMeleeAttack(double px, double py, double range, int damage, bool isAoe) {
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
           zombiesHit.sort((a, b) => sqrt(pow(a.x - px, 2) + pow(a.y - py, 2)).compareTo(sqrt(pow(b.x - px, 2) + pow(b.y - py, 2))));
           zombiesHit = [zombiesHit.first];
        }
        
        for (var z in zombiesHit) {
           z.health -= damage;
           if (z.health <= 0) {
              z.health = 0;
              z.isDying = true;
              
              for (int i = 0; i < 15; i++) {
                 _bloodParticles.add(BloodParticle(
                    z.x, z.y,
                    (_random.nextDouble() - 0.5) * 200,
                    (_random.nextDouble() - 0.5) * 200 - 50,
                    0.5 + _random.nextDouble(),
                    3.0 + _random.nextDouble() * 4.0,
                 ));
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
    _targetAimAngle = atan2(_aimTarget.dy - shoulderY, _aimTarget.dx - shoulderX);
  }

  void _handlePanEnd(DragEndDetails details) {
    _isShooting = false;
  }

  void _winLevel() {
    int coinsEarned = 150 + (widget.level * 10);
    int xpEarned = 500 + (widget.level * 50);

    Future.delayed(const Duration(seconds: 2), () {
      if(mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(
            builder: (_) => RewardScreen(
              level: widget.level,
              coinsEarned: coinsEarned,
              xpEarned: xpEarned,
            )
          )
        );
      }
    });
  }

  @override
  void dispose() {
    _gameLoop.dispose();
    super.dispose();
  }

  void _useLightningPower() {
    if (_lightningPowerCount > 0 && !_gameOver && !_won && _zombies.isNotEmpty) {
      setState(() {
        _lightningPowerCount--;
        _showLightning = true;
        _lightningTargets.clear();

        List<Zombie> sortedZombies = _zombies.where((z) => !z.isDying).toList();
        sortedZombies.sort((a, b) => 
           (pow(a.x - _playerX, 2) + pow(a.y - _playerY, 2))
           .compareTo(pow(b.x - _playerX, 2) + pow(b.y - _playerY, 2))
        );
        
        int count = min(3, sortedZombies.length);
        for(int i = 0; i < count; i++) {
            _lightningTargets.add(Offset(sortedZombies[i].x, sortedZombies[i].y));
            sortedZombies[i].health = 0;
            sortedZombies[i].isDying = true;
            for (int j = 0; j < 15; j++) {
               _bloodParticles.add(BloodParticle(
                  sortedZombies[i].x, sortedZombies[i].y,
                  (_random.nextDouble() - 0.5) * 200,
                  (_random.nextDouble() - 0.5) * 200 - 50,
                  0.5 + _random.nextDouble(),
                  3.0 + _random.nextDouble() * 4.0,
               ));
            }
        }
      });
      
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _showLightning = false);
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
                 _bloodParticles.add(BloodParticle(
                    z.x, z.y,
                    (_random.nextDouble() - 0.5) * 200,
                    (_random.nextDouble() - 0.5) * 200 - 50,
                    0.5 + _random.nextDouble(),
                    3.0 + _random.nextDouble() * 4.0,
                 ));
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

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: _handlePanDown,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            onPanCancel: () => _isShooting = false,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/spooky_bg.png',
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.4), // Darker, less saturated tint
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (context, error, stackTrace) => Container(color: AppTheme.backgroundColor),
                  ),
                ),
                
                ..._projectiles.map((p) {
                  double angle = atan2(p.dy, p.dx); 
                  return Positioned(
                    left: p.x - 12,
                    top: p.y - 12,
                    child: Transform.rotate(
                      angle: angle,
                      child: (p.type == 'arrow' || p.type == 'fire_arrow' || p.type == 'zombie_arrow')
                        ? Transform.rotate(angle: pi/2, child: Icon(Icons.arrow_upward, color: p.type == 'fire_arrow' ? Colors.deepOrangeAccent : (p.type == 'zombie_arrow' ? Colors.redAccent : Colors.white), size: p.type == 'fire_arrow' ? 32 : (p.type == 'zombie_arrow' ? 28 : 24)))
                        : Container(
                            width: p.type == 'bullet' ? 24 : 10,
                            height: 4,
                            margin: const EdgeInsets.only(left: 10),
                            decoration: BoxDecoration(
                              color: p.type == 'bullet' ? Colors.yellowAccent : Colors.orange,
                              borderRadius: BorderRadius.circular(10)
                            ),
                          ),
                    ),
                  );
                }),

                ..._bloodParticles.map((bp) => Positioned(
                  left: bp.x,
                  top: bp.y,
                  child: Container(
                    width: bp.size,
                    height: bp.size,
                    decoration: BoxDecoration(
                      color: Colors.red[900]?.withOpacity(bp.life / bp.maxLife),
                      shape: BoxShape.circle,
                    ),
                  ),
                )),
                
                ..._zombies.map((z) => Positioned(
                  left: z.x - 25,
                  top: z.y - 40,
                  child: Transform.scale(
                    scaleX: z.isFacingLeft ? 1 : -1,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 50,
                      height: 80,
                      child: CustomPaint(
                        painter: ZombiePainter(z.health, z.maxHealth, z.color, z.type, z.weapon, z.swingTimer, z.walkPhase, z.isDying),
                      ),
                    ),
                  ),
                )),

                Positioned(
                  left: _playerX - 40,
                  top: _playerY - 40,
                  child: SizedBox(
                    width: 80,
                    height: 100,
                    child: CustomPaint(
                      painter: PlayerPainter(aimAngle: _currentAimAngle, recoil: _recoil, weapon: currentWeapon, shootTimer: _shootTimer),
                    ),
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

                if (_showLightning)
                   Positioned.fill(
                     child: CustomPaint(
                       painter: LightningSkillPainter(
                         playerX: _playerX, 
                         playerY: _playerY, 
                         targets: _lightningTargets
                       ),
                     ),
                   ),

                if (_gameOver)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.8),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/game_over_bg.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 80,
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black87,
                                border: Border.all(color: Colors.red[900]!, width: 4),
                                boxShadow: [
                                  BoxShadow(color: Colors.red[900]!.withOpacity(0.8), blurRadius: 40, spreadRadius: 15),
                                  const BoxShadow(color: Colors.black, blurRadius: 50, spreadRadius: 20),
                                ],
                              ),
                              child: const Text('💀', style: TextStyle(fontSize: 60)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              boxShadow: const [
                                BoxShadow(color: Colors.black, blurRadius: 30, spreadRadius: 25),
                              ],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'YOU DIED',
                              style: TextStyle(
                                color: const Color(0xFFD32F2F), // red[700]
                                fontSize: 85,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 8,
                                shadows: [
                                  const Shadow(color: Colors.black, blurRadius: 5, offset: Offset(4, 4)),
                                  Shadow(color: Colors.red[900]!, blurRadius: 30),
                                  const Shadow(color: Colors.redAccent, blurRadius: 50),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 80,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 340,
                                height: 90,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.grey[900]!,
                                      Colors.grey[800]!,
                                      Colors.grey[900]!,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  border: Border.all(color: Colors.redAccent, width: 3),
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: [
                                    BoxShadow(color: Colors.redAccent.withOpacity(0.6), blurRadius: 20, spreadRadius: 5),
                                    const BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 5)),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Positioned(left: 10, top: 10, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle))),
                                    Positioned(right: 10, top: 10, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle))),
                                    Positioned(left: 10, bottom: 10, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle))),
                                    Positioned(right: 10, bottom: 10, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle))),
                                    
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'RETREAT TO BASE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2,
                                            shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))],
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.keyboard_double_arrow_left, color: Colors.redAccent, size: 24),
                                            const SizedBox(width: 15),
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.red[900],
                                                border: Border.all(color: Colors.redAccent),
                                              ),
                                              child: const Icon(Icons.fort, color: Colors.white, size: 18),
                                            ),
                                            const SizedBox(width: 15),
                                            const Icon(Icons.keyboard_double_arrow_right, color: Colors.redAccent, size: 24),
                                          ],
                                        ),
                                      ],
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

                if (_won)
                  const Center(
                    child: Text('AREA CLEARED!', style: TextStyle(color: Colors.greenAccent, fontSize: 45, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),

                SafeArea(
                  child: Stack(
                    children: [
                      // Top Left: Player Status
                      Positioned(
                        left: 20,
                        top: 20,
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blueGrey[900]!, width: 4),
                                color: Colors.black87,
                                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(2, 4))],
                              ),
                              child: Center(child: Icon(Icons.person_outline, color: Colors.blueGrey[300], size: 40)),
                            ),
                            // Health Bar
                            Container(
                              width: 180,
                              height: 40,
                              margin: const EdgeInsets.only(left: 5),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                border: Border.all(color: Colors.brown[900]!, width: 3),
                                borderRadius: const BorderRadius.only(topRight: Radius.circular(5), bottomRight: Radius.circular(5)),
                                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 5, offset: Offset(2, 4))],
                              ),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Icon(Icons.favorite, color: Colors.red[900], size: 24),
                                  ),
                                  Expanded(
                                    child: Stack(
                                      alignment: Alignment.centerLeft,
                                      children: [
                                        Container(color: Colors.grey[900]), // Background of bar
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 130 * (_health / 100).clamp(0.0, 1.0),
                                          height: 34,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Colors.red[900]!, Colors.red[700]!, Colors.red[900]!],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            '$_health / 100', 
                                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1, shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1))]),
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Top Center: Level & Objectives
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          margin: const EdgeInsets.only(top: 15),
                          width: 220,
                          height: 80,
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              Container(
                                width: 200,
                                height: 60,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  border: Border.all(color: Colors.brown[800]!, width: 4),
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 15, spreadRadius: 2, offset: Offset(0, 5))],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('LEVEL ${widget.level}', style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3, fontFamily: 'serif')),
                                    Text('KILLS: $_kills / $_targetKills', style: TextStyle(color: Colors.red[300], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  ],
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.brown[800]!, width: 2),
                                    boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 5)],
                                  ),
                                  child: Icon(Icons.pest_control, color: Colors.grey[400], size: 20), // Skull alternative
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Top Right: Coins & Settings
                      Positioned(
                        right: 20,
                        top: 20,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                border: Border.all(color: Colors.amber[900]!, width: 2),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(2, 2))],
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.monetization_on, color: Colors.amber[600], size: 20),
                                  const SizedBox(width: 8),
                                  Text('${gameState.coins}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                border: Border.all(color: Colors.grey[800]!, width: 2),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(2, 2))],
                              ),
                              child: Icon(Icons.settings, color: Colors.grey[400], size: 24),
                            )
                          ],
                        ),
                      ),

                      // Right Side: Skills
                      Positioned(
                        right: 20,
                        top: 120,
                        child: Column(
                          children: [
                            _buildSkillButton(Icons.flash_on, '$_lightningPowerCount', Colors.purple[700]!, _useLightningPower),
                          ],
                        ),
                      ),


                      // Bottom Right: Action Button
                      Positioned(
                        right: 30,
                        bottom: 30,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black87,
                            border: Border.all(color: Colors.cyan[800]!, width: 4),
                            boxShadow: [
                              BoxShadow(color: Colors.cyan[900]!.withOpacity(0.5), blurRadius: 15, spreadRadius: 2),
                              const BoxShadow(color: Colors.black, blurRadius: 10, offset: Offset(4, 4)),
                            ],
                            gradient: RadialGradient(
                              colors: [Colors.grey[850]!, Colors.black],
                              radius: 0.8,
                            )
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.gps_fixed, color: Colors.cyan[200]!.withOpacity(0.3), size: 80),
                              Icon(Icons.my_location, color: Colors.cyan[100], size: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoveButton(IconData icon, VoidCallback onDown, VoidCallback onUp) {
    return Listener(
      onPointerDown: (_) => onDown(),
      onPointerUp: (_) => onUp(),
      onPointerCancel: (_) => onUp(),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border.all(color: Colors.blueAccent, width: 2),
          borderRadius: BorderRadius.circular(15), // Hexagonal-ish
          boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 10)],
        ),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildSkillButton(IconData icon, String count, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black87,
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.6), blurRadius: 15, spreadRadius: 1),
                const BoxShadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 4))
              ],
              gradient: RadialGradient(
                colors: [Colors.grey[850]!, Colors.black],
                radius: 0.8,
              )
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          Container(
            margin: const EdgeInsets.only(right: 5, bottom: 5),
            child: Text(count, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
          )
        ],
      ),
    );
  }

  Widget _buildInventorySlot(IconData icon, String count, bool isActive) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isActive ? Colors.grey[850] : Colors.black87,
        border: Border.all(color: isActive ? Colors.cyan[700]! : Colors.grey[800]!, width: 2),
        borderRadius: BorderRadius.circular(3),
        boxShadow: isActive ? [BoxShadow(color: Colors.cyan[900]!.withOpacity(0.3), blurRadius: 5, spreadRadius: 1)] : [],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: isActive ? Colors.cyan[100] : Colors.grey[500], size: 28),
          Positioned(
            bottom: 2,
            right: 4,
            child: Text(count, style: TextStyle(color: isActive ? Colors.cyan[50] : Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold, shadows: const [Shadow(color: Colors.black, blurRadius: 2)])),
          ),
        ],
      ),
    );
  }
}

class PlayerPainter extends CustomPainter {
  final double aimAngle;
  final double recoil;
  final String weapon;
  final double shootTimer;
  
  PlayerPainter({required this.aimAngle, required this.recoil, required this.weapon, required this.shootTimer});

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
      canvas.drawLine(Offset(cx, size.height * 0.2 + 15) + off, Offset(cx, size.height * 0.6) + off, p); 
      canvas.drawLine(Offset(cx, size.height * 0.6) + off, Offset(size.width * 0.15, size.height * 0.95) + off, p); 
      canvas.drawLine(Offset(cx, size.height * 0.6) + off, Offset(size.width * 0.65, size.height * 0.95) + off, p); 
    }

    drawBody(shadowPaint, const Offset(3, 5));
    canvas.drawCircle(Offset(cx, size.height * 0.2) + const Offset(3, 5), headRadius, Paint()..color = Colors.black.withValues(alpha: 0.7)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    drawBody(paint, Offset.zero);
    
    final headPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.grey[800]!, Colors.black],
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
      ).createShader(Rect.fromCircle(center: Offset(cx, size.height * 0.2), radius: headRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, size.height * 0.2), headRadius, headPaint);

    drawBody(highlightPaint, const Offset(-1.5, -1.5));

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(aimAngle);

    double w = size.width;
    double h = size.height;

    if (weapon == 'Bow' || weapon == 'Fire Bow') {
      final quiverShadow = Paint()..color = Colors.black.withValues(alpha: 0.6)..strokeWidth = 12..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawLine(Offset(-0.2 * w + 2, -0.2 * h + 4), Offset(-0.35 * w + 2, 0.25 * h + 4), quiverShadow);
      
      final quiverPaint = Paint()
         ..shader = LinearGradient(colors: [Colors.brown[600]!, Colors.brown[900]!]).createShader(Rect.fromPoints(Offset(-0.2 * w, -0.2 * h), Offset(-0.35 * w, 0.25 * h)))
         ..strokeWidth = 12
         ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(-0.2 * w, -0.2 * h), Offset(-0.35 * w, 0.25 * h), quiverPaint);
      
      final quiverHighlight = Paint()..color = Colors.white.withValues(alpha: 0.3)..strokeWidth = 2..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(-0.2 * w - 3, -0.2 * h), Offset(-0.35 * w - 3, 0.25 * h), quiverHighlight);

      final strapPaint = Paint()..color = Colors.amber[800]!..strokeWidth = 4..strokeCap = StrokeCap.square;
      canvas.drawLine(Offset(-0.23 * w, -0.1 * h), Offset(-0.28 * w, -0.1 * h), strapPaint);
      canvas.drawLine(Offset(-0.3 * w, 0.1 * h), Offset(-0.35 * w, 0.1 * h), strapPaint);
      
      void drawQuiverArrow(Offset start, Offset end) {
         canvas.drawLine(start, end, Paint()..color = Colors.brown[300]!..strokeWidth = 2.5);
         final fletchingPaint = Paint()..color = Colors.white..strokeWidth = 2;
         canvas.drawLine(start, start + const Offset(-6, -6), fletchingPaint);
         canvas.drawLine(start, start + const Offset(6, -6), fletchingPaint);
      }
      
      drawQuiverArrow(Offset(-0.25 * w, -0.3 * h), Offset(-0.22 * w, -0.2 * h));
      drawQuiverArrow(Offset(-0.2 * w, -0.35 * h), Offset(-0.18 * w, -0.15 * h));
      drawQuiverArrow(Offset(-0.15 * w, -0.3 * h), Offset(-0.14 * w, -0.15 * h));

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
             arrowAngle = -pi/2 + (0 - -pi/2) * p; 
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
        canvas.drawLine(start + const Offset(3, 5), end + const Offset(3, 5), shadowPaint);
        canvas.drawLine(start, end, paint);
        canvas.drawLine(start + const Offset(-1.5, -1.5), end + const Offset(-1.5, -1.5), highlightPaint);
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
      
      final bowShadow = Paint()..color = Colors.black.withValues(alpha: 0.6)..strokeWidth = 6..strokeCap = StrokeCap.round..style = PaintingStyle.stroke..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(bowPath.shift(const Offset(2, 4)), bowShadow);

      final bowPaint = Paint()
         ..shader = LinearGradient(colors: [Colors.brown[400]!, Colors.brown[800]!]).createShader(Rect.fromPoints(Offset(frontHandX, -0.3 * h), Offset(frontHandX, 0.3 * h)))
         ..strokeWidth = 6..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
      canvas.drawPath(bowPath, bowPaint);
      
      final stringPaint = Paint()..color = Colors.white70..strokeWidth = 1.5..style = PaintingStyle.stroke;
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
         
         final arrowShaft = Paint()..color = Colors.brown[300]!..strokeWidth = 3..strokeCap = StrokeCap.round;
         canvas.drawLine(Offset.zero, Offset(0.45 * w, 0), arrowShaft);
         
         final fletchingPaint = Paint()..color = Colors.white..strokeWidth = 2;
         canvas.drawLine(Offset.zero, Offset(0.05 * w, -0.03 * h), fletchingPaint);
         canvas.drawLine(Offset.zero, Offset(0.05 * w, 0.03 * h), fletchingPaint);
         
         final tipPaint = Paint()..color = weapon == 'Fire Bow' ? Colors.deepOrangeAccent : Colors.grey[400]!..strokeWidth = weapon == 'Fire Bow' ? 6 : 4..strokeCap = StrokeCap.round;
         canvas.drawLine(Offset(0.45 * w, 0), Offset(0.55 * w, 0), tipPaint);
         
         canvas.restore();
      }
    } else if (weapon == 'Battle Axe') {
      double swingAngle = recoil * (pi / 1.5); 
      
      canvas.save();
      canvas.rotate(swingAngle);
      
      canvas.drawLine(Offset.zero, Offset(0.3 * w, 0), paint); 
      canvas.drawLine(Offset.zero, Offset(0.2 * w, 0.1 * h), paint); 
      
      final handlePaint = Paint()..color = Colors.brown[600]!..strokeWidth = 6..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0.25 * w, -0.1 * h), Offset(0.25 * w, 0.4 * h), handlePaint);
      
      final bladePaint = Paint()..color = Colors.grey[400]!..style = PaintingStyle.fill;
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
      
      final handlePaint = Paint()..color = Colors.brown[800]!..strokeWidth = 8..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0.25 * w, -0.2 * h), Offset(0.25 * w, 0.6 * h), handlePaint);
      
      final headPaint = Paint()..color = Colors.grey[700]!..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0.25 * w, 0.6 * h), width: 0.4 * w, height: 0.2 * h), const Radius.circular(5)), headPaint);
      
      canvas.restore();
      
    } else if (weapon == 'Assault Rifle') {
      canvas.drawLine(Offset.zero, Offset(0.35 * w, 0.05 * h), paint); 
      canvas.drawLine(Offset.zero, Offset(0.15 * w, 0.1 * h), paint); 
      
      final gunPaint = Paint()..color = Colors.grey[900]!..strokeWidth = 12..strokeCap = StrokeCap.round;
      final barrelPaint = Paint()..color = Colors.grey[700]!..strokeWidth = 6..strokeCap = StrokeCap.round;
      
      double gunRecoil = recoil * -0.05 * w;
      canvas.drawLine(Offset(0.05 * w + gunRecoil, 0.1 * h), Offset(0.4 * w + gunRecoil, 0.05 * h), gunPaint);
      canvas.drawLine(Offset(0.4 * w + gunRecoil, 0.05 * h), Offset(0.7 * w + gunRecoil, 0.05 * h), barrelPaint);
      
      if (recoil > 0.5) {
        canvas.drawCircle(Offset(0.75 * w + gunRecoil, 0.05 * h), 12 * recoil, Paint()..color = Colors.orangeAccent);
      }
    } else if (weapon == 'Shotgun') {
      canvas.drawLine(Offset.zero, Offset(0.4 * w, 0.08 * h), paint); 
      canvas.drawLine(Offset.zero, Offset(0.2 * w, 0.15 * h), paint); 
      
      final gunPaint = Paint()..color = Colors.brown[900]!..strokeWidth = 14..strokeCap = StrokeCap.square;
      final barrelPaint = Paint()..color = Colors.grey[800]!..strokeWidth = 10..strokeCap = StrokeCap.round;
      
      double gunRecoil = recoil * -0.15 * w;
      canvas.drawLine(Offset(0.1 * w + gunRecoil, 0.15 * h), Offset(0.3 * w + gunRecoil, 0.08 * h), gunPaint);
      canvas.drawLine(Offset(0.3 * w + gunRecoil, 0.08 * h), Offset(0.65 * w + gunRecoil, 0.08 * h), barrelPaint);
      
      if (recoil > 0.5) {
        canvas.drawCircle(Offset(0.75 * w + gunRecoil, 0.08 * h), 20 * recoil, Paint()..color = Colors.yellowAccent);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PlayerPainter oldDelegate) {
    return oldDelegate.aimAngle != aimAngle || oldDelegate.recoil != recoil || oldDelegate.weapon != weapon || oldDelegate.shootTimer != shootTimer;
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
  ZombiePainter(this.health, this.maxHealth, this.baseColor, this.type, this.weapon, this.swingProgress, this.walkPhase, this.isDying);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    double healthRatio = health / maxHealth;
    final color = healthRatio > 0.35 ? baseColor.withValues(alpha: 0.3 + 0.7 * healthRatio) : Colors.red[900]!;
    
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
    
    canvas.drawCircle(headCenter + const Offset(2, 4), headRadius, Paint()..color = Colors.black.withValues(alpha: 0.7)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    
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
      final deadEyePaint = Paint()..color = Colors.black87..strokeWidth = 2..style = PaintingStyle.stroke;
      Offset leftEye = Offset(size.width * 0.4, size.height * 0.18 + bob);
      Offset rightEye = Offset(size.width * 0.6, size.height * 0.18 + bob);
      
      canvas.drawLine(leftEye + const Offset(-3, -3), leftEye + const Offset(3, 3), deadEyePaint);
      canvas.drawLine(leftEye + const Offset(-3, 3), leftEye + const Offset(3, -3), deadEyePaint);
      
      canvas.drawLine(rightEye + const Offset(-3, -3), rightEye + const Offset(3, 3), deadEyePaint);
      canvas.drawLine(rightEye + const Offset(-3, 3), rightEye + const Offset(3, -3), deadEyePaint);
    }

    _drawArmAndWeapon(canvas, size, paint, shadowPaint, highlightPaint);

    canvas.restore();
  }

  void _drawStickmanBody(Canvas canvas, Size size, Paint paint, Offset offset) {
    double bob = isDying ? 0 : sin(walkPhase * 2) * 3;
    double legSpread = isDying ? 0.6 : sin(walkPhase) * 0.4;
    
    Offset pelvis = Offset(size.width * 0.5, size.height * 0.65 + bob + (isDying ? 15 : 0));
    Offset neck = Offset(size.width * 0.5, size.height * 0.2 + 16 + bob + (isDying ? 15 : 0));

    canvas.drawLine(neck + offset, pelvis + offset, paint);
    
    Offset leftFoot = Offset(size.width * 0.5 - sin(legSpread) * size.width * 0.3, size.height * 0.95 + (isDying ? 5 : 0));
    Offset rightFoot = Offset(size.width * 0.5 + sin(legSpread) * size.width * 0.3, size.height * 0.95 + (isDying ? 5 : 0));
    
    canvas.drawLine(pelvis + offset, leftFoot + offset, paint);
    canvas.drawLine(pelvis + offset, rightFoot + offset, paint);
    
    if (weapon == 'sword' || weapon == 'axe' || weapon == 'knife') {
      canvas.drawLine(Offset(size.width * 0.5, size.height * 0.35 + bob + (isDying ? 15 : 0)) + offset, Offset(size.width * 0.8, size.height * 0.45 + bob + (isDying ? 25 : 0)) + offset, paint);
    } else {
      canvas.drawLine(Offset(size.width * 0.5, size.height * 0.35 + bob + (isDying ? 15 : 0)) + offset, Offset(size.width * 0.8, size.height * 0.5 + bob + (isDying ? 25 : 0)) + offset, paint);
    }
  }

  void _drawArmAndWeapon(Canvas canvas, Size size, Paint paint, Paint shadowPaint, Paint highlightPaint) {
    canvas.save();
    double bob = isDying ? 15 : sin(walkPhase * 2) * 3;
    double pivotX = size.width * 0.5;
    double pivotY = size.height * 0.35 + bob;
    
    double lungeAngle = (swingProgress > 0) ? sin((swingProgress / 0.3) * pi) * -0.2 : 0; 
    double swingAngle = (swingProgress > 0) ? sin((swingProgress / 0.3) * pi) * 1.5 : (isDying ? 0.8 : 0); 
    
    canvas.translate(pivotX, pivotY);
    canvas.rotate(swingAngle + lungeAngle); 
    canvas.translate(-pivotX, -pivotY);

    Offset armStart = Offset(size.width * 0.5, size.height * 0.35 + bob);
    Offset armEnd = Offset(size.width * 0.2, size.height * (weapon == 'bow' ? 0.5 : 0.6) + bob);
    
    canvas.drawLine(armStart + const Offset(2, 4), armEnd + const Offset(2, 4), shadowPaint);
    canvas.drawLine(armStart, armEnd, paint);
    canvas.drawLine(armStart + const Offset(-1.5, -1.5), armEnd + const Offset(-1.5, -1.5), highlightPaint);

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
    final bowPaint = Paint()..color = Colors.brown[600]!..strokeWidth = 5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final bowShadow = Paint()..color = Colors.black87..strokeWidth = 6..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final bowPath = Path();
    bowPath.moveTo(size.width * 0.2, size.height * 0.2);
    bowPath.quadraticBezierTo(size.width * 0.0, size.height * 0.5, size.width * 0.2, size.height * 0.8);
    
    canvas.drawPath(bowPath.shift(const Offset(2, 2)), bowShadow);
    canvas.drawPath(bowPath, bowPaint);

    final stringPaint = Paint()..color = Colors.white54..strokeWidth = 1.5;
    canvas.drawLine(Offset(size.width * 0.2, size.height * 0.2), Offset(size.width * 0.2, size.height * 0.8), stringPaint);
  }

  void _drawSword(Canvas canvas, Size size) {
    Offset hand = Offset(size.width * 0.2, size.height * 0.6);
    Offset tip = Offset(-size.width * 0.1, size.height * 0.85); 
    Offset pommel = Offset(size.width * 0.28, size.height * 0.53);

    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.6)..strokeWidth = 6..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawLine(hand + const Offset(2, 2), tip + const Offset(2, 2), shadowPaint);

    final bladePaint = Paint()
      ..shader = LinearGradient(colors: [Colors.purple[300]!, Colors.purple[700]!]).createShader(Rect.fromPoints(hand, tip))
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(hand, tip, bladePaint);
    
    canvas.drawLine(hand, tip, Paint()..color = Colors.white.withValues(alpha: 0.5)..strokeWidth = 2..strokeCap = StrokeCap.round);

    final guardPaint = Paint()..color = Colors.amber[700]!..strokeWidth = 5..strokeCap = StrokeCap.round;
    canvas.drawLine(hand + const Offset(-6, -4), hand + const Offset(6, 4), guardPaint);
    
    final handlePaint = Paint()..color = Colors.brown[800]!..strokeWidth = 4..strokeCap = StrokeCap.round;
    canvas.drawLine(hand, pommel, handlePaint);
  }

  void _drawAxe(Canvas canvas, Size size) {
    Offset hand = Offset(size.width * 0.2, size.height * 0.6);
    Offset tip = Offset(-size.width * 0.1, size.height * 0.85); 
    
    // Handle
    final handlePaint = Paint()..color = Colors.brown[800]!..strokeWidth = 6..strokeCap = StrokeCap.round;
    canvas.drawLine(hand + const Offset(0.2 * 30, -0.3 * 30), tip, handlePaint);
    
    // Axe Head
    final headPaint = Paint()..color = Colors.grey[400]!..style = PaintingStyle.fill;
    final headPath = Path();
    headPath.moveTo(-size.width * 0.0, size.height * 0.7);
    headPath.quadraticBezierTo(-size.width * 0.3, size.height * 0.65, -size.width * 0.2, size.height * 0.8);
    headPath.quadraticBezierTo(-size.width * 0.05, size.height * 0.85, -size.width * 0.0, size.height * 0.7);
    canvas.drawPath(headPath, headPaint);
    
    // Highlight
    canvas.drawPath(headPath, Paint()..color = Colors.white.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  void _drawKnife(Canvas canvas, Size size) {
    Offset hand = Offset(size.width * 0.2, size.height * 0.6);
    Offset tip = Offset(size.width * 0.05, size.height * 0.75); 
    
    // Handle
    final handlePaint = Paint()..color = Colors.grey[900]!..strokeWidth = 4..strokeCap = StrokeCap.round;
    canvas.drawLine(hand, Offset(size.width * 0.1, size.height * 0.65), handlePaint);
    
    // Blade
    final bladePaint = Paint()
      ..shader = LinearGradient(colors: [Colors.grey[300]!, Colors.grey[600]!]).createShader(Rect.fromPoints(Offset(size.width * 0.1, size.height * 0.65), tip))
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * 0.1, size.height * 0.65), tip, bladePaint);
    
    // Highlight
    canvas.drawLine(Offset(size.width * 0.1, size.height * 0.65), tip, Paint()..color = Colors.white.withValues(alpha: 0.5)..strokeWidth = 1..strokeCap = StrokeCap.round);
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
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.brown[700]!, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 15, offset: Offset(4, 4))],
          gradient: RadialGradient(colors: [Colors.grey[900]!, Colors.black87], radius: 0.8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Directional markers
            Positioned(top: 5, child: Icon(Icons.arrow_drop_up, color: Colors.brown[400], size: 24)),
            Positioned(bottom: 5, child: Icon(Icons.arrow_drop_down, color: Colors.brown[400], size: 24)),
            Positioned(left: 5, child: Icon(Icons.arrow_left, color: Colors.brown[400], size: 24)),
            Positioned(right: 5, child: Icon(Icons.arrow_right, color: Colors.brown[400], size: 24)),
            
            Transform.translate(
              offset: _position,
              child: Container(
                width: _radius,
                height: _radius,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.brown[600]!, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 10, offset: const Offset(2, 4)),
                    BoxShadow(color: Colors.brown[800]!.withOpacity(0.5), blurRadius: 5, spreadRadius: 1, offset: const Offset(-1, -1)),
                  ],
                  gradient: RadialGradient(colors: [Colors.grey[700]!, Colors.grey[900]!]),
                ),
                child: Center(
                  child: Container(
                    width: _radius * 0.4,
                    height: _radius * 0.4,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.brown[400]!, width: 1),
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

  LightningSkillPainter({required this.playerX, required this.playerY, required this.targets});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final random = Random();
    final lightningCore = Paint()..color = Colors.white..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final lightningGlow = Paint()..color = Colors.purpleAccent.withValues(alpha: 0.8)..strokeWidth = 10..style = PaintingStyle.stroke..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    for (var target in targets) {
      for (int i = 0; i < 2; i++) {
        Path lPath = Path();
        lPath.moveTo(playerX, playerY - 40);
        
        double currentX = playerX;
        double currentY = playerY - 40;
        
        int segments = 6;
        for (int j = 1; j <= segments; j++) {
           double nextX = playerX + (target.dx - playerX) * (j / segments) + (random.nextDouble() - 0.5) * 60;
           double nextY = (playerY - 40) + (target.dy - (playerY - 40)) * (j / segments) + (random.nextDouble() - 0.5) * 60;
           
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
           branch.moveTo(currentX - (target.dx - playerX)*0.2, currentY - (target.dy - playerY)*0.2);
           branch.lineTo(currentX + (random.nextDouble() - 0.5) * 100, currentY + (random.nextDouble() - 0.5) * 100);
           canvas.drawPath(branch, lightningGlow);
           canvas.drawPath(branch, lightningCore);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
