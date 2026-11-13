
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/game_state_provider.dart';
import '../utils/app_theme.dart';
import '../utils/weapon_registry.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameStateProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/spooky_bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              AppTheme.backgroundColor.withOpacity(0.85),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, gameState),
              Expanded(
                child: FadeInUp(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildSectionHeaderWithStatus(
                          context,
                          'MISSION ARSENAL',
                          statusText: 'SECTOR 0${gameState.highestLevelUnlocked} • ${gameState.unlockedWeapons.length}/18 UNLOCKED',
                        ),
                        Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          alignment: WrapAlignment.center,
                          children: WeaponRegistry.allWeapons
                              .map((w) => _buildWeaponItem(context, w, gameState))
                              .toList(),
                        ),
                        const SizedBox(height: 32),
                        _buildSectionHeader(context, 'ARMOR & HEALTH'),
                        Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildShopItem(context, 'Tactical Vest', 'Reduces damage by 25%', 300, Icons.security, gameState),
                            _buildShopItem(context, 'Medkit', 'Restores full health', 100, Icons.local_hospital, gameState),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildSectionHeader(context, 'ABILITIES'),
                        Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildShopItem(context, 'Sprint Boost', 'Run 20% faster', 400, Icons.directions_run, gameState),
                            _buildShopItem(context, 'Adrenaline', 'Slow time for 5s', 1000, Icons.speed, gameState),
                            _buildShopItem(context, 'Auto Turret', 'Places a stationary turret (3 uses)', 800, Icons.gps_fixed, gameState),
                            _buildShopItem(context, 'Health Regen', 'Regenerate health over time', 600, Icons.favorite, gameState),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, GameStateProvider gameState) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: _buildGlassCard(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              borderRadius: 12,
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'BACK',
                    style: GoogleFonts.orbitron(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Title
          _buildGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            borderColor: AppTheme.primaryColor,
            borderRadius: 16,
            child: Text(
              'SURVIVOR SUPPLY',
              style: GoogleFonts.orbitron(
                color: AppTheme.textPrimaryColor,
                fontSize: 38,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                shadows: [
                  Shadow(color: AppTheme.primaryColor, blurRadius: 15),
                  const Shadow(
                    color: Colors.black,
                    blurRadius: 5,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
          // Coins & Supply Airdrop
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGlassCard(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                borderRadius: 12,
                child: Row(
                  children: [
                    const Text('💀', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      '${gameState.coins}',
                      style: GoogleFonts.orbitron(
                        color: AppTheme.accentColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Supply Airdrop (+1,000 Coins)
              GestureDetector(
                onTap: () {
                  gameState.addCoins(1000);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.card_giftcard, color: Colors.amberAccent),
                          const SizedBox(width: 10),
                          Text(
                            'AIRDROP SECURED! +1,000 SKULL COINS ADDED!',
                            style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF1E2430),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: _buildGlassCard(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  borderColor: Colors.amberAccent,
                  borderRadius: 12,
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle, color: Colors.amberAccent, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '+1,000 💀',
                        style: GoogleFonts.orbitron(
                          color: Colors.amberAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 16.0,
    Color? borderColor,
  }) {
    borderColor ??= AppTheme.primaryColor.withOpacity(0.5);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: borderColor.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor.withOpacity(0.7),
              border: Border.all(color: borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.0),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Text(
          title,
          style: GoogleFonts.orbitron(
            color: AppTheme.accentColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            shadows: [
              Shadow(color: AppTheme.accentColor.withOpacity(0.5), blurRadius: 10),
              const Shadow(color: Colors.black, blurRadius: 5, offset: Offset(2, 2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeaderWithStatus(
    BuildContext context,
    String title, {
    required String statusText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.orbitron(
              color: AppTheme.accentColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              shadows: [
                Shadow(color: AppTheme.accentColor.withValues(alpha: 0.5), blurRadius: 10),
                const Shadow(color: Colors.black, blurRadius: 5, offset: Offset(2, 2)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1E2A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_open, color: Color(0xFF00E5FF), size: 14),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFF00E5FF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeaponItem(
    BuildContext context,
    WeaponInfo weapon,
    GameStateProvider gameState,
  ) {
    bool isLevelLocked = weapon.unlockLevel > gameState.highestLevelUnlocked;
    bool isOwned = gameState.unlockedWeapons.contains(weapon.name);
    bool isEquipped = gameState.currentWeapon == weapon.name;

    return Container(
      width: 290,
      child: _buildGlassCard(
        padding: const EdgeInsets.all(20.0),
        borderColor: isEquipped
            ? AppTheme.primaryColor
            : (isLevelLocked
                ? Colors.redAccent.withValues(alpha: 0.3)
                : (isOwned ? AppTheme.accentColor.withValues(alpha: 0.5) : Colors.white24)),
        borderRadius: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Level requirement badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isLevelLocked
                    ? Colors.red.withValues(alpha: 0.2)
                    : const Color(0xFF00E5FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLevelLocked
                      ? Colors.redAccent.withValues(alpha: 0.5)
                      : const Color(0xFF00E5FF).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLevelLocked ? Icons.lock_outline : Icons.check_circle_outline,
                    size: 13,
                    color: isLevelLocked ? Colors.redAccent : const Color(0xFF00E5FF),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isLevelLocked
                        ? 'SECTOR ${weapon.unlockLevel} REQUIRED'
                        : 'UNLOCKED AT SECTOR ${weapon.unlockLevel}',
                    style: GoogleFonts.shareTechMono(
                      color: isLevelLocked ? Colors.redAccent : const Color(0xFF00E5FF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLevelLocked ? const Color(0xFF140D10) : AppTheme.backgroundColor,
                border: Border.all(
                  color: isEquipped
                      ? AppTheme.primaryColor
                      : (isLevelLocked ? Colors.redAccent.withValues(alpha: 0.4) : Colors.white30),
                  width: 2,
                ),
                boxShadow: isEquipped
                    ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.6), blurRadius: 15, spreadRadius: 2)]
                    : [],
              ),
              child: Icon(
                isLevelLocked ? Icons.lock : weapon.icon,
                size: 38,
                color: isEquipped
                    ? AppTheme.primaryColor
                    : (isLevelLocked ? Colors.redAccent.withValues(alpha: 0.7) : Colors.white),
                shadows: [if (isEquipped) Shadow(color: AppTheme.primaryColor, blurRadius: 10)],
              ),
            ),
            const SizedBox(height: 14),

            // Weapon Name
            Text(
              weapon.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: isLevelLocked ? Colors.white54 : AppTheme.textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              isLevelLocked
                  ? 'Locked ordinance. Complete Sector ${weapon.unlockLevel - 1} to unlock.'
                  : weapon.desc,
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(
                color: isLevelLocked ? Colors.white38 : AppTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),

            // Action Button
            GestureDetector(
              onTap: () {
                if (isLevelLocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.lock, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Text(
                            'SECTOR 0${weapon.unlockLevel} REQUIRED! Complete previous sectors to unlock ${weapon.name}.',
                            style: GoogleFonts.orbitron(fontSize: 12),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF261016),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                if (isEquipped) return;
                gameState.equipWeapon(weapon.name);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${weapon.name.toUpperCase()} EQUIPPED FOR NEXT MISSION!',
                      style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: AppTheme.successColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLevelLocked
                        ? [Colors.black54, Colors.black45]
                        : (isEquipped
                            ? [AppTheme.primaryColor.withValues(alpha: 0.8), AppTheme.primaryColor.withValues(alpha: 0.4)]
                            : [const Color(0xFF00E5FF).withValues(alpha: 0.8), const Color(0xFF0091EA).withValues(alpha: 0.5)]),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isLevelLocked
                        ? Colors.white24
                        : (isEquipped ? AppTheme.primaryColor : const Color(0xFF00E5FF)),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    if (!isLevelLocked)
                      BoxShadow(
                        color: (isEquipped ? AppTheme.primaryColor : const Color(0xFF00E5FF)).withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isLevelLocked
                          ? Icons.lock
                          : (isEquipped ? Icons.check : Icons.swap_horiz),
                      size: 18,
                      color: isLevelLocked ? Colors.white38 : (isEquipped ? Colors.white : Colors.black),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isLevelLocked
                          ? 'SECTOR ${weapon.unlockLevel}'
                          : (isEquipped ? 'EQUIPPED' : 'EQUIP'),
                      style: GoogleFonts.orbitron(
                        color: isLevelLocked ? Colors.white38 : (isEquipped ? Colors.white : Colors.black),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopItem(
    BuildContext context,
    String name,
    String desc,
    int price,
    IconData icon,
    GameStateProvider gameState,
  ) {
    return Container(
      width: 280,
      child: _buildGlassCard(
        padding: const EdgeInsets.all(20.0),
        borderColor: AppTheme.accentColor.withOpacity(0.3),
        borderRadius: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.backgroundColor,
                border: Border.all(color: AppTheme.accentColor, width: 2),
                boxShadow: [
                  BoxShadow(color: AppTheme.accentColor.withOpacity(0.4), blurRadius: 15, spreadRadius: 2),
                ],
              ),
              child: Icon(
                icon,
                size: 40,
                color: Colors.white,
                shadows: [Shadow(color: AppTheme.accentColor, blurRadius: 10)],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: AppTheme.textPrimaryColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(
                color: AppTheme.textSecondaryColor,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                _purchaseItem(context, name, price, gameState);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.backgroundColor.withOpacity(0.9), Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(color: AppTheme.accentColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: AppTheme.accentColor.withOpacity(0.3), blurRadius: 8),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('💀', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      price.toString(),
                      style: GoogleFonts.orbitron(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _purchaseItem(
    BuildContext context,
    String item,
    int price,
    GameStateProvider provider,
  ) async {
    bool success = await provider.spendCoins(price);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchased $item!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough coins!'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }
}
