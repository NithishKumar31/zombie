import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/game_state_provider.dart';
import '../utils/audio_service.dart';
import 'game_screen.dart';
import 'level_selector_screen.dart';
import 'shop_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameStateProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF07080B),
      body: Stack(
        children: [
          // 1. Spooky High-Atmosphere Graveyard Background Wallpaper
          Positioned.fill(
            child: Image.asset(
              'assets/images/spooky_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Heavy Cinematic Vignette & Radial Darkening
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.25,
                  colors: [
                    const Color(0xFF0F0B18).withValues(alpha: 0.55),
                    const Color(0xFF09060F).withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.96),
                  ],
                  stops: const [0.2, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // 3. Floating Atmospheric Embers
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                return CustomPaint(
                  painter: MenuEmbersPainter(progress: _ambientController.value),
                );
              },
            ),
          ),

          // 4. Main Menu Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // TOP TACTICAL HUD BAR
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: _buildTopHudBar(context, gameState),
                      ),

                      const SizedBox(height: 30),

                      // EPIC HERO TITLE CREST
                      FadeInDown(
                        delay: const Duration(milliseconds: 200),
                        duration: const Duration(milliseconds: 700),
                        child: _buildHeroTitle(context, gameState),
                      ),

                      const SizedBox(height: 38),

                      // PRIMARY DEPLOY BUTTONS (CAMPAIGN & NIGHTMARE ENDLESS)
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        duration: const Duration(milliseconds: 600),
                        child: _buildPrimaryDeploySection(context, gameState),
                      ),

                      const SizedBox(height: 20),

                      // SECONDARY TACTICAL ACTION CARDS (ARMORY, SECTORS, SETTINGS, SERVICE RECORD)
                      FadeInUp(
                        delay: const Duration(milliseconds: 550),
                        duration: const Duration(milliseconds: 600),
                        child: _buildSecondaryActionGrid(context, gameState),
                      ),

                      const SizedBox(height: 28),

                      // FOOTER PROTOCOL WATERMARK
                      FadeIn(
                        delay: const Duration(milliseconds: 700),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00E676),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'APOCALYPSE PROTOCOL V2.8 // LOCAL SERVER ACTIVE',
                              style: GoogleFonts.shareTechMono(
                                color: Colors.white30,
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
            ),
          ),
        ],
      ),
    );
  }

  // TOP HUD BAR
  Widget _buildTopHudBar(BuildContext context, GameStateProvider gameState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10131C).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Operative Status   
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E676),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0xFF00E676), blurRadius: 8, spreadRadius: 2),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'OPERATIVE ONLINE',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'ACTIVE ZONE: SECTOR 0${gameState.highestLevelUnlocked}',
                    style: GoogleFonts.shareTechMono(
                      color: const Color(0xFF00E5FF),
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: Skull Balance & Arsenal Count & Audio Toggles
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Skull Coins
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E170A).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.6), width: 1.2),
                ),
                child: Row(
                  children: [
                    const Text('💀', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      '${gameState.coins}',
                      style: GoogleFonts.orbitron(
                        color: const Color(0xFFFFD54F),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Arsenal Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1E25).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5), width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: Color(0xFF00E5FF), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${gameState.unlockedWeapons.length}/18 WEAPONS',
                      style: GoogleFonts.shareTechMono(
                        color: const Color(0xFF00E5FF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Nightmare Wave Record Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF240B13).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFF1744).withValues(alpha: 0.6), width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.military_tech_rounded, color: Color(0xFFFF5252), size: 15),
                    const SizedBox(width: 6),
                    Text(
                      'WAVE 0${gameState.highestEndlessWave}',
                      style: GoogleFonts.orbitron(
                        color: const Color(0xFFFF8A80),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Audio Controls
              IconButton(
                icon: Icon(
                  gameState.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: gameState.soundEnabled ? const Color(0xFF00E5FF) : Colors.white38,
                  size: 20,
                ),
                tooltip: gameState.soundEnabled ? 'Mute SFX' : 'Enable SFX',
                onPressed: () => gameState.toggleSound(),
              ),
              IconButton(
                icon: Icon(
                  gameState.musicEnabled ? Icons.music_note_rounded : Icons.music_off_rounded,
                  color: gameState.musicEnabled ? const Color(0xFF00E676) : Colors.white38,
                  size: 20,
                ),
                tooltip: gameState.musicEnabled ? 'Mute Music' : 'Enable Music',
                onPressed: () => gameState.toggleMusic(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // HERO TITLE & CYBERNETIC CREST
  Widget _buildHeroTitle(BuildContext context, GameStateProvider gameState) {
    return Column(
      children: [
        // Glowing 3D Headline
        Column(
          children: [
            Text(
              'ZOMBIE',
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                fontSize: 68,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 14,
                shadows: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                    blurRadius: 30,
                  ),
                  const Shadow(
                    color: Colors.black,
                    blurRadius: 10,
                    offset: Offset(4, 4),
                  ),
                ],
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFF1744), Color(0xFFFF9100), Color(0xFFFFD600)],
              ).createShader(bounds),
              child: Text(
                'SURVIVAL',
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  fontSize: 82,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 12,
                  shadows: [
                    BoxShadow(
                      color: const Color(0xFFFF5252).withValues(alpha: 0.8),
                      blurRadius: 40,
                    ),
                    const Shadow(
                      color: Colors.black,
                      blurRadius: 12,
                      offset: Offset(4, 4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Cyber Divider
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, const Color(0xFF00E5FF).withValues(alpha: 0.8)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'SECTOR PURGE INITIATIVE',
                style: GoogleFonts.shareTechMono(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              width: 140,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF00E5FF).withValues(alpha: 0.8), Colors.transparent],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // PRIMARY DUAL DEPLOYMENT SECTION (CAMPAIGN PURGE & NIGHTMARE HORDE)
  Widget _buildPrimaryDeploySection(BuildContext context, GameStateProvider gameState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isNarrow = constraints.maxWidth < 750;
        if (isNarrow) {
          return Column(
            children: [
              _buildPrimaryDeployCard(context, gameState),
              const SizedBox(height: 14),
              _buildEndlessDeployCard(context, gameState),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: _buildPrimaryDeployCard(context, gameState)),
            const SizedBox(width: 16),
            Expanded(child: _buildEndlessDeployCard(context, gameState)),
          ],
        );
      },
    );
  }

  // 1. Campaign Sector Deploy Card
  Widget _buildPrimaryDeployCard(BuildContext context, GameStateProvider gameState) {
    return _InteractiveMenuCard(
      height: 110,
      gradientColors: const [Color(0xFF00E5FF), Color(0xFF0091EA)],
      borderColor: const Color(0xFF80D8FF),
      boxGlowColor: const Color(0xFF00E5FF).withValues(alpha: 0.5),
      onTap: () {
        if (gameState.soundEnabled) {
          AudioService().playSoundEffect('lightning.wav');
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(level: gameState.highestLevelUnlocked),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.25),
                border: Border.all(color: Colors.white70, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.4),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        'CAMPAIGN PURGE',
                        style: GoogleFonts.orbitron(
                          color: Colors.black,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'SEC 0${gameState.highestLevelUnlocked}',
                          style: GoogleFonts.orbitron(
                            color: const Color(0xFF00E5FF),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'LOADOUT: ${gameState.currentWeapon.toUpperCase()}',
                    style: GoogleFonts.shareTechMono(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.black,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // 2. Nightmare Endless Horde Mode Deploy Card
  Widget _buildEndlessDeployCard(BuildContext context, GameStateProvider gameState) {
    return _InteractiveMenuCard(
      height: 110,
      gradientColors: const [Color(0xFFFF1744), Color(0xFFB71C1C)],
      borderColor: const Color(0xFFFF8A80),
      boxGlowColor: const Color(0xFFFF1744).withValues(alpha: 0.55),
      onTap: () {
        if (gameState.soundEnabled) {
          AudioService().playSoundEffect('lightning.wav');
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const GameScreen(level: 0, isEndless: true),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.3),
                border: Border.all(color: Colors.white70, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.4),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: const Icon(
                Icons.crisis_alert,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        'NIGHTMARE HORDE',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'WAVE 0${gameState.highestEndlessWave}',
                          style: GoogleFonts.orbitron(
                            color: const Color(0xFFFF5252),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ENDLESS SURVIVAL // INFINITE HORDE',
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // SECONDARY TACTICAL ACTION GRID (ARMORY, SECTORS, SETTINGS, SERVICE RECORD)
  Widget _buildSecondaryActionGrid(BuildContext context, GameStateProvider gameState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isNarrow = constraints.maxWidth < 700;
        return isNarrow
            ? Column(
                children: [
                  _buildArmoryCard(context, gameState),
                  const SizedBox(height: 14),
                  _buildSectorsCard(context, gameState),
                  const SizedBox(height: 14),
                  _buildSettingsCard(context, gameState),
                  const SizedBox(height: 14),
                  _buildServiceRecordCard(context, gameState),
                ],
              )
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildArmoryCard(context, gameState)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSectorsCard(context, gameState)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildSettingsCard(context, gameState)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildServiceRecordCard(context, gameState)),
                    ],
                  ),
                ],
              );
      },
    );
  }

  // 1. Armory Card
  Widget _buildArmoryCard(BuildContext context, GameStateProvider gameState) {
    return _InteractiveMenuCard(
      height: 90,
      gradientColors: [
        const Color(0xFF181D26).withValues(alpha: 0.95),
        const Color(0xFF10131A).withValues(alpha: 0.95),
      ],
      borderColor: const Color(0xFF00E5FF).withValues(alpha: 0.4),
      boxGlowColor: const Color(0xFF00E5FF).withValues(alpha: 0.15),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShopScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0A1F26),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.6), width: 1.5),
              ),
              child: const Icon(Icons.shield_outlined, color: Color(0xFF00E5FF), size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ARMORY & SUPPLIES',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'EQUIPPED: ${gameState.currentWeapon.toUpperCase()} (${gameState.unlockedWeapons.length}/18 UNLOCKED)',
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white54,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 24),
          ],
        ),
      ),
    );
  }

  // 2. Mission Sectors Card
  Widget _buildSectorsCard(BuildContext context, GameStateProvider gameState) {
    return _InteractiveMenuCard(
      height: 90,
      gradientColors: [
        const Color(0xFF181D26).withValues(alpha: 0.95),
        const Color(0xFF10131A).withValues(alpha: 0.95),
      ],
      borderColor: const Color(0xFF00E676).withValues(alpha: 0.4),
      boxGlowColor: const Color(0xFF00E676).withValues(alpha: 0.15),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LevelSelectorScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0A2218),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.6), width: 1.5),
              ),
              child: const Icon(Icons.grid_view_rounded, color: Color(0xFF00E676), size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SECTOR SELECT',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'REVISIT & PURGE SECTORS 01 - 200',
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white54,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 24),
          ],
        ),
      ),
    );
  }

  // 3. System Settings Card
  Widget _buildSettingsCard(BuildContext context, GameStateProvider gameState) {
    return _InteractiveMenuCard(
      height: 90,
      gradientColors: [
        const Color(0xFF181D26).withValues(alpha: 0.95),
        const Color(0xFF10131A).withValues(alpha: 0.95),
      ],
      borderColor: const Color(0xFFFFB300).withValues(alpha: 0.4),
      boxGlowColor: const Color(0xFFFFB300).withValues(alpha: 0.15),
      onTap: () => _showSettingsDialog(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF241C0A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.6), width: 1.5),
              ),
              child: const Icon(Icons.tune_rounded, color: Color(0xFFFFB300), size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SYSTEM SETTINGS',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'AUDIO, MUSIC & GRAPHICS CONFIG',
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white54,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 24),
          ],
        ),
      ),
    );
  }

  // 4. Service Record Card
  Widget _buildServiceRecordCard(BuildContext context, GameStateProvider gameState) {
    return _InteractiveMenuCard(
      height: 90,
      gradientColors: [
        const Color(0xFF181D26).withValues(alpha: 0.95),
        const Color(0xFF10131A).withValues(alpha: 0.95),
      ],
      borderColor: const Color(0xFFFF4081).withValues(alpha: 0.4),
      boxGlowColor: const Color(0xFFFF4081).withValues(alpha: 0.15),
      onTap: () => _showServiceRecordDialog(context, gameState),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF260D1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF4081).withValues(alpha: 0.6), width: 1.5),
              ),
              child: const Icon(Icons.insights_rounded, color: Color(0xFFFF4081), size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SERVICE RECORD',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'CONFIRMED KILLS & OPERATIVE INTEL',
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white54,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 24),
          ],
        ),
      ),
    );
  }

  // SYSTEM SETTINGS DIALOG
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10131A).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 30,
                      ),
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SYSTEM CONFIGURATION',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'COMBAT AUDIO & VISUAL PROTOCOLS',
                          style: GoogleFonts.shareTechMono(
                            color: const Color(0xFF00E5FF),
                            fontSize: 11,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Consumer<GameStateProvider>(
                          builder: (context, state, child) {
                            return SwitchListTile(
                              title: Text(
                                'AUDIO SOUND EFFECTS',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              subtitle: Text(
                                'Gunfire, zombie shrieks, explosions',
                                style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 13),
                              ),
                              value: state.soundEnabled,
                              activeThumbColor: const Color(0xFF00E5FF),
                              activeTrackColor: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                              onChanged: (val) => state.toggleSound(),
                            );
                          },
                        ),
                        const Divider(color: Colors.white12, height: 24),
                        Consumer<GameStateProvider>(
                          builder: (context, state, child) {
                            return SwitchListTile(
                              title: Text(
                                'AMBIENT SOUNDTRACK',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              subtitle: Text(
                                'Cinematic apocalyptic background score',
                                style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 13),
                              ),
                              value: state.musicEnabled,
                              activeThumbColor: const Color(0xFF00E676),
                              activeTrackColor: const Color(0xFF00E676).withValues(alpha: 0.4),
                              onChanged: (val) => state.toggleMusic(),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'CONFIRM SETTINGS',
                                style: GoogleFonts.orbitron(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
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
          ),
        );
      },
    );
  }

  // SERVICE RECORD DIALOG
  void _showServiceRecordDialog(BuildContext context, GameStateProvider gameState) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10131A).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF4081).withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 30,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF4081).withValues(alpha: 0.2),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shield, color: Color(0xFFFF4081), size: 24),
                            const SizedBox(width: 10),
                            Text(
                              'OPERATIVE DOSSIER',
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'CONFIDENTIAL SURVIVOR RECORDS',
                          style: GoogleFonts.shareTechMono(
                            color: const Color(0xFFFF4081),
                            fontSize: 11,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildStatRow('HIGHEST SECTOR REACHED', 'SECTOR 0${gameState.highestLevelUnlocked}', const Color(0xFF00E5FF)),
                        const Divider(color: Colors.white12, height: 20),
                        _buildStatRow('NIGHTMARE HORDE RECORD', 'WAVE 0${gameState.highestEndlessWave} (${gameState.endlessHighScore} PTS)', const Color(0xFFFF5252)),
                        const Divider(color: Colors.white12, height: 20),
                        _buildStatRow('SCRAP BOUNTY EARNED', '${gameState.coins} 💀', const Color(0xFFFFD54F)),
                        const Divider(color: Colors.white12, height: 20),
                        _buildStatRow('WEAPONS UNLOCKED', '${gameState.unlockedWeapons.length} / 18', const Color(0xFF00E676)),
                        const Divider(color: Colors.white12, height: 20),
                        _buildStatRow('AIRDROPS & CRATES SECURED', '${gameState.tacticalCratesCollected} CACHES', const Color(0xFF00E5FF)),
                        const Divider(color: Colors.white12, height: 20),
                        _buildStatRow('CURRENT LOADOUT', gameState.currentWeapon.toUpperCase(), Colors.white),
                        const Divider(color: Colors.white12, height: 20),
                        _buildStatRow('OPERATIVE STATUS', 'RANK S+ SPECIALIST', const Color(0xFFFF4081)),
                        const SizedBox(height: 30),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2430),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24, width: 1.2),
                            ),
                            child: Center(
                              child: Text(
                                'CLOSE DOSSIER',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
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
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            color: Colors.white60,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// INTERACTIVE CARD WIDGET
class _InteractiveMenuCard extends StatefulWidget {
  final double height;
  final List<Color> gradientColors;
  final Color borderColor;
  final Color boxGlowColor;
  final Widget child;
  final VoidCallback onTap;

  const _InteractiveMenuCard({
    required this.height,
    required this.gradientColors,
    required this.borderColor,
    required this.boxGlowColor,
    required this.child,
    required this.onTap,
  });

  @override
  State<_InteractiveMenuCard> createState() => _InteractiveMenuCardState();
}

class _InteractiveMenuCardState extends State<_InteractiveMenuCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? Colors.white : widget.borderColor,
              width: _isHovered ? 2.0 : 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.boxGlowColor,
                blurRadius: _isHovered ? 24 : 12,
                spreadRadius: _isHovered ? 2 : 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// FLOATING EMBERS PAINTER FOR MENU
class MenuEmbersPainter extends CustomPainter {
  final double progress;
  final List<MenuEmber> embers = List.generate(40, (index) {
    final random = Random(index * 997);
    return MenuEmber(
      startX: random.nextDouble(),
      speed: 0.3 + random.nextDouble() * 0.7,
      size: 1.5 + random.nextDouble() * 3.5,
      isCyan: random.nextBool(),
      swayFreq: 1.5 + random.nextDouble() * 3.0,
      swayAmp: 0.02 + random.nextDouble() * 0.04,
    );
  });

  MenuEmbersPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    for (var ember in embers) {
      double currentY = (1.0 - ((progress * ember.speed + ember.startX) % 1.0)) * size.height;
      double currentX = (ember.startX + sin(progress * ember.swayFreq * 2 * pi) * ember.swayAmp) * size.width;

      double opacity = sin((currentY / size.height) * pi).clamp(0.0, 1.0);
      Color color = ember.isCyan
          ? const Color(0xFF00E5FF).withValues(alpha: opacity * 0.55)
          : const Color(0xFFFF5252).withValues(alpha: opacity * 0.55);

      final paint = Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ember.size * 0.6);

      canvas.drawCircle(Offset(currentX, currentY), ember.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MenuEmbersPainter oldDelegate) => true;
}

class MenuEmber {
  final double startX;
  final double speed;
  final double size;
  final bool isCyan;
  final double swayFreq;
  final double swayAmp;

  MenuEmber({
    required this.startX,
    required this.speed,
    required this.size,
    required this.isCyan,
    required this.swayFreq,
    required this.swayAmp,
  });
}
