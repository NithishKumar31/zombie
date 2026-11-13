import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/game_state_provider.dart';
import '../utils/audio_service.dart';
import '../utils/weapon_registry.dart';
import 'game_screen.dart';

class LevelSelectorScreen extends StatefulWidget {
  const LevelSelectorScreen({super.key});

  @override
  State<LevelSelectorScreen> createState() => _LevelSelectorScreenState();
}

class _LevelSelectorScreenState extends State<LevelSelectorScreen> with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  final int _totalPages = 20; // 200 sectors / 10 per page
  late AnimationController _ambientController;
  final ScrollController _tabScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Auto-navigate to player's current front line on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final gameState = context.read<GameStateProvider>();
      int targetPage = ((gameState.highestLevelUnlocked - 1) ~/ 10).clamp(0, _totalPages - 1);
      if (targetPage != _currentPage) {
        setState(() => _currentPage = targetPage);
        _scrollToActiveTab(targetPage);
      }
    });
  }

  void _scrollToActiveTab(int pageIndex) {
    if (_tabScrollController.hasClients) {
      double targetOffset = (pageIndex * 155.0) - 220;
      _tabScrollController.animateTo(
        targetOffset.clamp(0.0, _tabScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  // Zone Theme metadata per page (Gritty Apocalyptic Biomes with High-Contrast Cyber Neon Palette)
  _ZoneMetadata _getZoneMetadata(int pageIndex) {
    switch (pageIndex ~/ 2) {
      case 0:
        return const _ZoneMetadata(
          zoneName: 'ZONE I: THE FORSAKEN GRAVEYARD',
          zoneSubtitle: 'GROUND ZERO // CRYPT INFESTATION',
          accentColor: Color(0xFF00E5FF), // Cold Plasma Cyan
          secondaryColor: Color(0xFF0091EA),
          threatTier: 'TIER I : OUTBREAK',
          hazardCode: 'CYBER-01',
        );
      case 1:
        return const _ZoneMetadata(
          zoneName: 'ZONE II: THE HAUNTED WOODS',
          zoneSubtitle: 'TOXIC BIOME // ACID RAIN FOREST',
          accentColor: Color(0xFF00E676), // Toxic Emerald
          secondaryColor: Color(0xFF00A854),
          threatTier: 'TIER II : LETHAL',
          hazardCode: 'ACID-02',
        );
      case 2:
        return const _ZoneMetadata(
          zoneName: 'ZONE III: RUINED METROPOLIS',
          zoneSubtitle: 'COLLAPSED HIGHWAY // ASH CORRIDORS',
          accentColor: Color(0xFFFF9100), // Scorched Amber
          secondaryColor: Color(0xFFFF6D00),
          threatTier: 'TIER III : CRITICAL',
          hazardCode: 'RUIN-03',
        );
      case 3:
        return const _ZoneMetadata(
          zoneName: 'ZONE IV: SUBTERRANEAN FACILITY',
          zoneSubtitle: 'CONTAINMENT BREACH // LAB ZERO',
          accentColor: Color(0xFFE040FB), // Mutated Neon Violet
          secondaryColor: Color(0xFF9C27B0),
          threatTier: 'TIER IV : QUARANTINE',
          hazardCode: 'BREACH-04',
        );
      case 4:
        return const _ZoneMetadata(
          zoneName: 'ZONE V: ABANDONED POWER PLANT',
          zoneSubtitle: 'RADIATION LEAK // GLOWING SWARM',
          accentColor: Color(0xFFEEFF41), // Lethal Yellow
          secondaryColor: Color(0xFFC0CA33),
          threatTier: 'TIER V : IRRADIATED',
          hazardCode: 'RAD-05',
        );
      case 5:
        return const _ZoneMetadata(
          zoneName: 'ZONE VI: THE BLOOD CATACOMBS',
          zoneSubtitle: 'ANCIENT CRYPT // SACRIFICIAL ALTAR',
          accentColor: Color(0xFFFF1744), // Crimson Gore
          secondaryColor: Color(0xFFD50000),
          threatTier: 'TIER VI : NIGHTMARE',
          hazardCode: 'GORE-06',
        );
      case 6:
        return const _ZoneMetadata(
          zoneName: 'ZONE VII: CYBERNETIC BUNKER',
          zoneSubtitle: 'CYBORG EXPERIMENTS // MECHA HORDE',
          accentColor: Color(0xFF00B0FF), // Pure Mecha Azure
          secondaryColor: Color(0xFF00838F),
          threatTier: 'TIER VII : MECHANICAL',
          hazardCode: 'MECHA-07',
        );
      case 7:
        return const _ZoneMetadata(
          zoneName: 'ZONE VIII: INFERNAL VOLCANO',
          zoneSubtitle: 'MAGMA CRATER // HELLFIRE HORDE',
          accentColor: Color(0xFFFF5722), // Molten Magma
          secondaryColor: Color(0xFFD84315),
          threatTier: 'TIER VIII : HELLFIRE',
          hazardCode: 'LAVA-08',
        );
      case 8:
        return const _ZoneMetadata(
          zoneName: 'ZONE IX: THE SHADOW VOID',
          zoneSubtitle: 'DIMENSIONAL RIFT // ELDRITCH TERROR',
          accentColor: Color(0xFF7C4DFF), // Cosmic Violet
          secondaryColor: Color(0xFF536DFE),
          threatTier: 'TIER IX : ELDRITCH',
          hazardCode: 'VOID-09',
        );
      default:
        return const _ZoneMetadata(
          zoneName: 'ZONE X: THE OMEGA CITADEL',
          zoneSubtitle: 'EXTINCTION CORE // FINAL PURGE',
          accentColor: Color(0xFFFFD54F), // Imperial Omega Gold
          secondaryColor: Color(0xFFFFB300),
          threatTier: 'OMEGA : EXTINCTION',
          hazardCode: 'OMEGA-10',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameStateProvider>();
    int highestSector = gameState.highestLevelUnlocked;
    final zone = _getZoneMetadata(_currentPage);

    return Scaffold(
      backgroundColor: const Color(0xFF05070B),
      body: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: SizedBox(
            width: 1920,
            height: 1080,
            child: Stack(
              children: [
                // 1. Gritty Apocalypse Bunker Wallpaper
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/apocalypse_level_bg.jpg',
                    fit: BoxFit.cover,
                  ),
                ),

                // 2. Cyber Deep Obsidian Vignette Atmosphere
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.25,
                        colors: [
                          const Color(0xFF0D1627).withValues(alpha: 0.55),
                          const Color(0xFF070B14).withValues(alpha: 0.85),
                          const Color(0xFF04060A).withValues(alpha: 0.98),
                        ],
                        stops: const [0.15, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Dynamic Apocalypse Floating Embers & Blood Mist
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _ambientController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ApocalypseEmbersPainter(
                          progress: _ambientController.value,
                          zoneColor: zone.accentColor,
                        ),
                      );
                    },
                  ),
                ),

                // 4. Subtle Scratch / Hazard Overlay
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _DistressedOverlayPainter(),
                    ),
                  ),
                ),

                // 5. TOP TACTICAL COMMAND HEADER
                Positioned(
                  top: 26,
                  left: 60,
                  right: 60,
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 400),
                    child: _buildTopHeaderBar(context, gameState, zone),
                  ),
                ),

                // 6. WEATHERED SECTOR BARRICADE TABS
                Positioned(
                  top: 146,
                  left: 70,
                  right: 70,
                  child: FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    duration: const Duration(milliseconds: 450),
                    child: _buildWeatheredSectorTabs(highestSector),
                  ),
                ),

                // 7. SLEEK MODERN CYBERPUNK SECTOR GRID (2x5 Grid)
                Positioned(
                  top: 216,
                  left: 70,
                  right: 70,
                  bottom: 100,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 0.98,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      int levelNumber = (_currentPage * 10) + index + 1;
                      bool isUnlocked = levelNumber <= highestSector;
                      bool isNextTarget = levelNumber == highestSector;
                      WeaponInfo? weaponReward = WeaponRegistry.getWeaponUnlockedAtLevel(levelNumber);

                      return _buildGrittySectorCard(
                        context,
                        levelNumber: levelNumber,
                        isUnlocked: isUnlocked,
                        isNextTarget: isNextTarget,
                        weaponReward: weaponReward,
                        index: index,
                        gameState: gameState,
                        zone: zone,
                      );
                    },
                  ),
                ),

                // 8. HEAVY STEEL PAGINATION CHEVRONS
                if (_currentPage > 0)
                  Positioned(
                    left: 10,
                    top: 520,
                    child: _buildPaginationChevron(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: 'PREVIOUS SECTORS',
                      accentColor: zone.accentColor,
                      onTap: () {
                        setState(() => _currentPage--);
                        _scrollToActiveTab(_currentPage);
                        if (gameState.soundEnabled) {
                          AudioService().playSoundEffect('arrow.wav');
                        }
                      },
                    ),
                  ),

                if (_currentPage < _totalPages - 1)
                  Positioned(
                    right: 10,
                    top: 520,
                    child: _buildPaginationChevron(
                      icon: Icons.arrow_forward_ios_rounded,
                      tooltip: 'NEXT SECTORS',
                      accentColor: zone.accentColor,
                      onTap: () {
                        setState(() => _currentPage++);
                        _scrollToActiveTab(_currentPage);
                        if (gameState.soundEnabled) {
                          AudioService().playSoundEffect('arrow.wav');
                        }
                      },
                    ),
                  ),

                // 9. BOTTOM SURVIVOR DOCK & CONTAINMENT STATUS
                Positioned(
                  left: 70,
                  right: 70,
                  bottom: 22,
                  child: FadeInUp(
                    delay: const Duration(milliseconds: 250),
                    child: _buildBottomContainmentDock(context, gameState, zone),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // TOP HEADER BAR (SURVIVAL COMMAND INTERFACE)
  Widget _buildTopHeaderBar(BuildContext context, GameStateProvider gameState, _ZoneMetadata zone) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // RETURN TO BASECAMP BUTTON
        GestureDetector(
          onTap: () {
            if (gameState.soundEnabled) {
              AudioService().playSoundEffect('arrow.wav');
            }
            Navigator.pop(context);
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF141C2B),
                    Color(0xFF0C121C),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.65),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF00E5FF), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'EVAC BASECAMP',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
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

        // CENTER APOCALYPTIC MISSION BANNER
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Biohazard Caution Ticker
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF0C1322).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: zone.accentColor.withValues(alpha: 0.8), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: zone.accentColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, color: zone.accentColor, size: 16),
                  const SizedBox(width: 7),
                  Text(
                    '☣ OUTBREAK DISPATCH // ${zone.zoneName}',
                    style: GoogleFonts.shareTechMono(
                      color: zone.accentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: zone.accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      zone.hazardCode,
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Main Cyberpunk Title
            Text(
              'SELECT MISSION',
              style: GoogleFonts.orbitron(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: Colors.white,
                shadows: [
                  BoxShadow(
                    color: zone.accentColor.withValues(alpha: 0.8),
                    blurRadius: 28,
                  ),
                  const Shadow(
                    color: Color(0xFF030A14),
                    blurRadius: 12,
                    offset: Offset(3, 4),
                  ),
                  const Shadow(
                    color: Colors.black,
                    blurRadius: 6,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ],
        ),

        // RIGHT INTEL: SURVIVOR BOUNTY & OUTBREAK THREAT
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Skull Kills Trophy Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1B1B14),
                    Color(0xFF0F0F0A),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.75), width: 1.3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('💀', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '${gameState.coins}',
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFFFFD54F),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'KILLS',
                    style: GoogleFonts.shareTechMono(
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // Sector Intel Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0D172A),
                    Color(0xFF070E1A),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: zone.accentColor.withValues(alpha: 0.75), width: 1.3),
                boxShadow: [
                  BoxShadow(
                    color: zone.accentColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_rounded, color: zone.accentColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'SECTOR 0${gameState.highestLevelUnlocked}',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // WEATHERED SECTOR TABS (SURVIVOR BARRICADES)
  Widget _buildWeatheredSectorTabs(int highestSector) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF090D17).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 14,
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: _tabScrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_totalPages, (pageIndex) {
            int startSec = (pageIndex * 10) + 1;
            int endSec = (pageIndex * 10) + 10;
            bool isSelected = _currentPage == pageIndex;
            bool isReachable = startSec <= highestSector;
            final pageZone = _getZoneMetadata(pageIndex);

            Color tabTextColor;
            if (isSelected) {
              tabTextColor = pageZone.accentColor.computeLuminance() > 0.4 ? Colors.black : Colors.white;
            } else if (isReachable) {
              tabTextColor = const Color(0xFFE2E8F0);
            } else {
              tabTextColor = Colors.white30;
            }

            return GestureDetector(
              onTap: () {
                setState(() => _currentPage = pageIndex);
                _scrollToActiveTab(pageIndex);
                final gs = context.read<GameStateProvider>();
                if (gs.soundEnabled) {
                  AudioService().playSoundEffect('arrow.wav');
                }
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9.5),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              pageZone.accentColor,
                              pageZone.secondaryColor,
                            ],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isReachable ? const Color(0xFF111927) : const Color(0xFF080C14)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : (isReachable
                              ? pageZone.accentColor.withValues(alpha: 0.45)
                              : Colors.white12),
                      width: isSelected ? 1.8 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: pageZone.accentColor.withValues(alpha: 0.55),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isReachable)
                        const Padding(
                          padding: EdgeInsets.only(right: 7),
                          child: Icon(Icons.lock_outline_rounded, size: 15, color: Colors.white30),
                        )
                      else if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: Icon(Icons.warning_amber_rounded, size: 15, color: tabTextColor),
                        ),
                      Text(
                        'SECTORS ${startSec.toString().padLeft(2, '0')}–${endSec.toString().padLeft(2, '0')}',
                        style: GoogleFonts.shareTechMono(
                          color: tabTextColor,
                          fontSize: 14.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // SLEEK MODERN CYBERPUNK SECTOR CARD
  Widget _buildGrittySectorCard(
    BuildContext context, {
    required int levelNumber,
    required bool isUnlocked,
    required bool isNextTarget,
    required WeaponInfo? weaponReward,
    required int index,
    required GameStateProvider gameState,
    required _ZoneMetadata zone,
  }) {
    bool isCompleted = levelNumber < gameState.highestLevelUnlocked;
    int zombieCount = 10 + (levelNumber * 5);

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 160 + (index * 25)),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Transform.scale(
          scale: val,
          child: child,
        );
      },
      child: _CyberSectorCardInteractive(
        isUnlocked: isUnlocked,
        isNextTarget: isNextTarget,
        isCompleted: isCompleted,
        accentColor: zone.accentColor,
        ambientController: _ambientController,
        onTap: isUnlocked
            ? () {
                if (gameState.soundEnabled) {
                  AudioService().playSoundEffect('lightning.wav');
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GameScreen(level: levelNumber)),
                );
              }
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.lock_rounded, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 8),
                        Text(
                          'SECTOR ${levelNumber.toString().padLeft(2, '0')} LOCKED! Clear Sector ${(levelNumber - 1).toString().padLeft(2, '0')} first.',
                          style: GoogleFonts.shareTechMono(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF0F172A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. TOP BAR: Sector Identifier & Status Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sector Code Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131D2E),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isNextTarget
                            ? const Color(0xFF00E5FF).withOpacity(0.85)
                            : (isCompleted ? const Color(0xFF00E676).withOpacity(0.7) : Colors.white12),
                        width: 1.1,
                      ),
                    ),
                    child: Text(
                      'SEC ${levelNumber.toString().padLeft(2, '0')}',
                      style: GoogleFonts.orbitron(
                        color: isNextTarget
                            ? const Color(0xFF00E5FF)
                            : (isCompleted ? const Color(0xFF00E676) : const Color(0xFF94A3B8)),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  // Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? (isNextTarget
                              ? const Color(0xFF00E5FF).withOpacity(0.18)
                              : const Color(0xFF00E676).withOpacity(0.18))
                          : const Color(0xFF1E293B).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isUnlocked
                            ? (isNextTarget ? const Color(0xFF00E5FF) : const Color(0xFF00E676))
                            : const Color(0xFF334155),
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isNextTarget)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF00E5FF),
                              boxShadow: [
                                BoxShadow(color: Color(0xFF00E5FF), blurRadius: 6),
                              ],
                            ),
                          )
                        else if (isCompleted)
                          const Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: Icon(Icons.check, size: 13, color: Color(0xFF00E676)),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFF64748B)),
                          ),
                        Text(
                          isUnlocked
                              ? (isNextTarget ? 'ACTIVE TARGET' : 'PURGED')
                              : 'LOCKED',
                          style: GoogleFonts.shareTechMono(
                            color: isUnlocked
                                ? (isNextTarget ? const Color(0xFF00E5FF) : const Color(0xFF00E676))
                                : const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 2. CENTER SECTION: Crisp Orbitron Stencil Number & Cyber Weapon Cache
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    levelNumber.toString().padLeft(2, '0'),
                    style: GoogleFonts.orbitron(
                      color: isUnlocked
                          ? (isNextTarget ? Colors.white : const Color(0xFFE8F5E9))
                          : const Color(0xFF64748B),
                      fontSize: 62,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: 4,
                      shadows: isUnlocked
                          ? [
                              BoxShadow(
                                color: (isNextTarget ? const Color(0xFF00E5FF) : const Color(0xFF00E676))
                                    .withOpacity(0.75),
                                blurRadius: 26,
                              ),
                              const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 2)),
                            ]
                          : [
                              const Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 1)),
                            ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // WEAPON CACHE OR ENEMY INTEL BADGE
                  if (weaponReward != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF221A08).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFFD54F), width: 1.3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD54F).withOpacity(0.35),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(weaponReward.icon, color: const Color(0xFFFFD54F), size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'CACHE: ${weaponReward.name.toUpperCase()}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.shareTechMono(
                                color: const Color(0xFFFFD54F),
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101724),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white12, width: 1.0),
                      ),
                      child: Text(
                        '$zombieCount HOSTILES • +${zombieCount * 10} 💀',
                        style: GoogleFonts.shareTechMono(
                          color: isUnlocked ? const Color(0xFF90A4AE) : Colors.white24,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                ],
              ),

              // 3. BOTTOM ROW: 3-Star Rating + Compact Tactile Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 3-Star Rating
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: Icon(
                          Icons.star_rounded,
                          color: isCompleted
                              ? const Color(0xFFFFD54F)
                              : (isNextTarget
                                  ? const Color(0xFFFFD54F).withOpacity(0.4)
                                  : const Color(0xFF243042)),
                          size: 24,
                          shadows: isCompleted
                              ? [const Shadow(color: Color(0xFFFFD54F), blurRadius: 12)]
                              : [],
                        ),
                      ),
                    ),
                  ),

                  // Compact Modern Cyber Action Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: isUnlocked
                          ? (isNextTarget
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF00E5FF),
                                    Color(0xFF0091EA),
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF00E676),
                                    Color(0xFF00A854),
                                  ],
                                ))
                          : null,
                      color: isUnlocked ? null : const Color(0xFF101726),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isUnlocked
                            ? (isNextTarget ? const Color(0xFFE0F7FA) : const Color(0xFFE8F5E9))
                            : const Color(0xFF1E293B),
                        width: 1.2,
                      ),
                      boxShadow: isNextTarget
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withOpacity(0.55),
                                blurRadius: 14,
                              ),
                            ]
                          : (isCompleted
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF00E676).withOpacity(0.35),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUnlocked
                              ? (isNextTarget ? Icons.play_arrow_rounded : Icons.replay_rounded)
                              : Icons.lock_outline_rounded,
                          size: 17,
                          color: isUnlocked ? Colors.black : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isUnlocked
                              ? (isNextTarget ? 'DEPLOY' : 'REPLAY')
                              : 'LOCKED',
                          style: GoogleFonts.orbitron(
                            color: isUnlocked ? Colors.black : const Color(0xFF64748B),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
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
    );
  }

  // HEAVY PAGINATION CHEVRON
  Widget _buildPaginationChevron({
    required IconData icon,
    required String tooltip,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 50,
          height: 96,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF141C2B),
                Color(0xFF0C121C),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accentColor.withValues(alpha: 0.65), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 14,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, color: accentColor, size: 28),
          ),
        ),
      ),
    );
  }

  // BOTTOM SURVIVOR PROGRESS DOCK
  Widget _buildBottomContainmentDock(BuildContext context, GameStateProvider gameState, _ZoneMetadata zone) {
    int clearedCount = gameState.highestLevelUnlocked - 1;
    double progress = (clearedCount / 200).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF090D17).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Stars Collected
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 26),
              const SizedBox(width: 10),
              Text(
                'MEDALS SECURED:',
                style: GoogleFonts.shareTechMono(
                  color: Colors.white70,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${clearedCount * 3} / 600',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFFFFD54F),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(width: 32),

          // Center: Toxic Containment Progress Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL CAMPAIGN PURGE PROGRESS',
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white60,
                        fontSize: 12.5,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      '$clearedCount / 200 SECTORS (${(progress * 100).toInt()}%)',
                      style: GoogleFonts.shareTechMono(
                        color: zone.accentColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: const Color(0xFF111927),
                    valueColor: AlwaysStoppedAnimation<Color>(zone.accentColor),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 32),

          // Right: Jump to Active Front Line
          GestureDetector(
            onTap: () {
              int targetPage = ((gameState.highestLevelUnlocked - 1) ~/ 10).clamp(0, _totalPages - 1);
              setState(() => _currentPage = targetPage);
              _scrollToActiveTab(targetPage);
              if (gameState.soundEnabled) {
                AudioService().playSoundEffect('arrow.wav');
              }
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00E5FF),
                      Color(0xFF0091EA),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0F7FA), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location_rounded, color: Colors.black, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'LOCATE FRONT LINE',
                      style: GoogleFonts.orbitron(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// INTERACTIVE CARD CONTAINER WITH STEEL RIVETS & CORNER HARDWARE
class _CyberSectorCardInteractive extends StatefulWidget {
  final bool isUnlocked;
  final bool isNextTarget;
  final bool isCompleted;
  final Color accentColor;
  final AnimationController ambientController;
  final Widget child;
  final VoidCallback onTap;

  const _CyberSectorCardInteractive({
    required this.isUnlocked,
    required this.isNextTarget,
    required this.isCompleted,
    required this.accentColor,
    required this.ambientController,
    required this.child,
    required this.onTap,
  });

  @override
  State<_CyberSectorCardInteractive> createState() => _CyberSectorCardInteractiveState();
}

class _CyberSectorCardInteractiveState extends State<_CyberSectorCardInteractive> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color glowColor;

    if (!widget.isUnlocked) {
      borderColor = _isHovered ? const Color(0xFF38BDF8) : const Color(0xFF1E293B);
      glowColor = const Color(0xFF38BDF8).withOpacity(_isHovered ? 0.35 : 0.0);
    } else if (widget.isNextTarget) {
      borderColor = _isHovered ? Colors.white : const Color(0xFF00E5FF);
      glowColor = const Color(0xFF00E5FF).withOpacity(_isHovered ? 0.80 : 0.45);
    } else {
      borderColor = _isHovered ? Colors.white : const Color(0xFF00E676).withOpacity(0.75);
      glowColor = const Color(0xFF00E676).withOpacity(_isHovered ? 0.55 : 0.20);
    }

    return MouseRegion(
      cursor: widget.isUnlocked ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          transform: _isHovered
              ? Matrix4.translationValues(0.0, -5.0, 0.0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isUnlocked
                  ? (widget.isNextTarget
                      ? [
                          const Color(0xFF101B2E).withOpacity(0.95),
                          const Color(0xFF080F1C).withOpacity(0.98),
                        ]
                      : [
                          const Color(0xFF0B1B15).withOpacity(0.94),
                          const Color(0xFF06100D).withOpacity(0.97),
                        ])
                  : [
                      const Color(0xFF0D121B).withOpacity(0.92),
                      const Color(0xFF070B12).withOpacity(0.96),
                    ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: (widget.isNextTarget || _isHovered) ? 1.8 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor,
                blurRadius: _isHovered ? 20 : 10,
                spreadRadius: _isHovered ? 2 : 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 4 Sleek Cyber Corner Brackets
              _CyberCornerBracket(isTop: true, isLeft: true, color: borderColor.withOpacity(0.6)),
              _CyberCornerBracket(isTop: true, isLeft: false, color: borderColor.withOpacity(0.6)),
              _CyberCornerBracket(isTop: false, isLeft: true, color: borderColor.withOpacity(0.6)),
              _CyberCornerBracket(isTop: false, isLeft: false, color: borderColor.withOpacity(0.6)),

              // Card Inner Content
              widget.child,
            ],
          ),
        ),
      ),
    );
  }
}

// SLEEK CYBER CORNER BRACKET WIDGET
class _CyberCornerBracket extends StatelessWidget {
  final bool isTop;
  final bool isLeft;
  final Color color;

  const _CyberCornerBracket({
    required this.isTop,
    required this.isLeft,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: isTop ? 5 : null,
      bottom: !isTop ? 5 : null,
      left: isLeft ? 5 : null,
      right: !isLeft ? 5 : null,
      child: CustomPaint(
        size: const Size(8, 8),
        painter: _CornerBracketPainter(
          isTop: isTop,
          isLeft: isLeft,
          color: color,
        ),
      ),
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;
  final Color color;

  _CornerBracketPainter({
    required this.isTop,
    required this.isLeft,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (isTop && isLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(0, 0);
      path.lineTo(0, size.height);
    } else if (isTop && !isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!isTop && isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// METADATA CLASS FOR ZONE THEMES
class _ZoneMetadata {
  final String zoneName;
  final String zoneSubtitle;
  final Color accentColor;
  final Color secondaryColor;
  final String threatTier;
  final String hazardCode;

  const _ZoneMetadata({
    required this.zoneName,
    required this.zoneSubtitle,
    required this.accentColor,
    required this.secondaryColor,
    required this.threatTier,
    required this.hazardCode,
  });
}

class ApocalypseEmbersPainter extends CustomPainter {
  final double progress;
  final Color zoneColor;
  final List<ApocalypseEmber> embers = List.generate(42, (index) {
    final random = Random(index * 991);
    return ApocalypseEmber(
      startX: random.nextDouble(),
      speed: 0.35 + random.nextDouble() * 0.75,
      size: 1.5 + random.nextDouble() * 4.0,
      isFire: random.nextDouble() > 0.3,
      swayFreq: 1.5 + random.nextDouble() * 3.0,
      swayAmp: 0.02 + random.nextDouble() * 0.04,
    );
  });

  ApocalypseEmbersPainter({
    required this.progress,
    required this.zoneColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    for (var ember in embers) {
      double currentY = (1.0 - ((progress * ember.speed + ember.startX) % 1.0)) * size.height;
      double currentX = (ember.startX + sin(progress * ember.swayFreq * 2 * pi) * ember.swayAmp) * size.width;

      double opacity = sin((currentY / size.height) * pi).clamp(0.0, 1.0);
      Color color = ember.isFire
          ? const Color(0xFFFF3D00).withValues(alpha: opacity * 0.55)
          : zoneColor.withValues(alpha: opacity * 0.45);

      final paint = Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ember.size * 0.7);

      canvas.drawCircle(Offset(currentX, currentY), ember.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ApocalypseEmbersPainter oldDelegate) => true;
}

class ApocalypseEmber {
  final double startX;
  final double speed;
  final double size;
  final bool isFire;
  final double swayFreq;
  final double swayAmp;

  ApocalypseEmber({
    required this.startX,
    required this.speed,
    required this.size,
    required this.isFire,
    required this.swayFreq,
    required this.swayAmp,
  });
}

// DISTRESSED OVERLAY PAINTER (SCRATCHES & HAZARD ACCENTS)
class _DistressedOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top-left and top-right subtle hazard corner chevrons
    final hazardPaint = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (double i = 0; i < 60; i += 12) {
      canvas.drawLine(Offset(i, 0), Offset(0, i), hazardPaint);
      canvas.drawLine(Offset(size.width - i, 0), Offset(size.width, i), hazardPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
