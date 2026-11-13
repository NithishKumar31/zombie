import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/game_state_provider.dart';
import '../utils/audio_service.dart';
import '../utils/weapon_registry.dart';
import 'game_screen.dart';
import 'shop_screen.dart';

class RewardScreen extends StatefulWidget {
  final int level;
  final int coinsEarned;
  final int xpEarned;

  const RewardScreen({
    super.key,
    required this.level,
    required this.coinsEarned,
    required this.xpEarned,
  });

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _particlesController;

  @override
  void initState() {
    super.initState();
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        final gameState = context.read<GameStateProvider>();
        gameState.completeGameLevel(
          widget.level,
          widget.coinsEarned,
          widget.xpEarned,
        );
        if (gameState.soundEnabled) {
          AudioService().playSoundEffect('lightning.wav');
        }
      }
    });
  }

  @override
  void dispose() {
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameStateProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF08090C),
      body: Stack(
        children: [
          // 1. Apocalyptic Graveyard Background Wallpaper
          Positioned.fill(
            child: Image.asset(
              'assets/images/spooky_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Heavy Atmospheric Vignette & Color Grading
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    const Color(0xFF0D0F16).withValues(alpha: 0.65),
                    const Color(0xFF07080B).withValues(alpha: 0.88),
                    Colors.black.withValues(alpha: 0.96),
                  ],
                  stops: const [0.2, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // 3. Floating Golden & Cyan Victory Embers Particle Layer
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particlesController,
              builder: (context, child) {
                return CustomPaint(
                  painter: VictoryEmbersPainter(progress: _particlesController.value),
                );
              },
            ),
          ),

          // 4. Main Scrollable Content Container
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top Tactical Sector Badge
                      FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14171E).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00E676),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Color(0xFF00E676), blurRadius: 6, spreadRadius: 1),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'SECTOR 0${widget.level} // AREA PURGED & SECURED',
                                style: GoogleFonts.shareTechMono(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 3-Star Victory Crest
                      FadeInDown(
                        delay: const Duration(milliseconds: 200),
                        duration: const Duration(milliseconds: 600),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Transform.rotate(
                              angle: -0.15,
                              child: _buildStar(size: 38, isAccent: false),
                            ),
                            const SizedBox(width: 12),
                            Transform.translate(
                              offset: const Offset(0, -8),
                              child: _buildStar(size: 56, isAccent: true),
                            ),
                            const SizedBox(width: 12),
                            Transform.rotate(
                              angle: 0.15,
                              child: _buildStar(size: 38, isAccent: false),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Epic Victory Title
                      ZoomIn(
                        duration: const Duration(milliseconds: 700),
                        child: Column(
                          children: [
                            Text(
                              'MISSION',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.orbitron(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 10,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                                    blurRadius: 20,
                                  ),
                                  const Shadow(color: Colors.black, blurRadius: 8, offset: Offset(2, 2)),
                                ],
                              ),
                            ),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF69F0AE), Color(0xFF00B0FF)],
                              ).createShader(bounds),
                              child: Text(
                                'ACCOMPLISHED',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.orbitron(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 8,
                                  shadows: [
                                    Shadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                                      blurRadius: 30,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Tactical Divider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 90,
                                  height: 1.5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.transparent, const Color(0xFF00E5FF).withValues(alpha: 0.8)],
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Icon(Icons.shield, color: Color(0xFF00E5FF), size: 16),
                                ),
                                Container(
                                  width: 90,
                                  height: 1.5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [const Color(0xFF00E5FF).withValues(alpha: 0.8), Colors.transparent],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'SURVIVOR EXTRACTION PROTOCOL COMPLETE',
                              style: GoogleFonts.shareTechMono(
                                color: Colors.white54,
                                fontSize: 11,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Holographic Rewards Cards (Coins & XP)
                      LayoutBuilder(
                        builder: (context, boxConstraints) {
                          bool isNarrow = boxConstraints.maxWidth < 620;
                          return isNarrow
                              ? Column(
                                  children: [
                                    FadeInLeft(
                                      delay: const Duration(milliseconds: 300),
                                      child: _buildRewardCard(
                                        title: 'SCRAP BOUNTY',
                                        subtitle: 'SURVIVAL REWARD',
                                        amount: widget.coinsEarned,
                                        prefix: '+',
                                        suffix: ' 💀',
                                        icon: Icons.monetization_on_rounded,
                                        themeColor: const Color(0xFFFFB300),
                                        bgGradient: [
                                          const Color(0xFF261D09).withValues(alpha: 0.9),
                                          const Color(0xFF14120B).withValues(alpha: 0.9),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    FadeInRight(
                                      delay: const Duration(milliseconds: 400),
                                      child: _buildRewardCard(
                                        title: 'OPERATOR MASTERY',
                                        subtitle: 'COMBAT EXPERIENCE',
                                        amount: widget.xpEarned,
                                        prefix: '+',
                                        suffix: ' XP',
                                        icon: Icons.stars_rounded,
                                        themeColor: const Color(0xFF00E5FF),
                                        bgGradient: [
                                          const Color(0xFF081C26).withValues(alpha: 0.9),
                                          const Color(0xFF071118).withValues(alpha: 0.9),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: FadeInLeft(
                                        delay: const Duration(milliseconds: 300),
                                        child: _buildRewardCard(
                                          title: 'SCRAP BOUNTY',
                                          subtitle: 'SURVIVAL REWARD',
                                          amount: widget.coinsEarned,
                                          prefix: '+',
                                          suffix: ' 💀',
                                          icon: Icons.monetization_on_rounded,
                                          themeColor: const Color(0xFFFFB300),
                                          bgGradient: [
                                            const Color(0xFF261D09).withValues(alpha: 0.9),
                                            const Color(0xFF14120B).withValues(alpha: 0.9),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: FadeInRight(
                                        delay: const Duration(milliseconds: 400),
                                        child: _buildRewardCard(
                                          title: 'OPERATOR MASTERY',
                                          subtitle: 'COMBAT EXPERIENCE',
                                          amount: widget.xpEarned,
                                          prefix: '+',
                                          suffix: ' XP',
                                          icon: Icons.stars_rounded,
                                          themeColor: const Color(0xFF00E5FF),
                                          bgGradient: [
                                            const Color(0xFF081C26).withValues(alpha: 0.9),
                                            const Color(0xFF071118).withValues(alpha: 0.9),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Sector Unlock & Status Ribbon
                      FadeInUp(
                        delay: const Duration(milliseconds: 600),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10131A).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildTacticalStatus(
                                label: 'SECTOR CLEAR',
                                value: 'RANK S+',
                                color: const Color(0xFF00E676),
                              ),
                              Container(width: 1, height: 26, color: Colors.white12),
                              _buildTacticalStatus(
                                label: 'NEXT SECTOR',
                                value: 'UNLOCKED 🔓',
                                color: const Color(0xFF00E5FF),
                              ),
                              Container(width: 1, height: 26, color: Colors.white12),
                              _buildTacticalStatus(
                                label: 'TOTAL BALANCE',
                                value: '${gameState.coins} 💀',
                                color: const Color(0xFFFFD54F),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // NEW WEAPON UNLOCKED HERO BANNER (if next level unlocks a weapon)
                      if (WeaponRegistry.getWeaponUnlockedAtLevel(widget.level + 1) != null)
                        FadeInUp(
                          delay: const Duration(milliseconds: 650),
                          child: _buildNewWeaponUnlockedCard(
                            context,
                            WeaponRegistry.getWeaponUnlockedAtLevel(widget.level + 1)!,
                            widget.level + 1,
                          ),
                        )
                      else if (WeaponRegistry.getNextWeaponToUnlock(widget.level + 1) != null)
                        FadeInUp(
                          delay: const Duration(milliseconds: 650),
                          child: _buildNextWeaponTeaser(
                            context,
                            WeaponRegistry.getNextWeaponToUnlock(widget.level + 1)!,
                            widget.level + 1,
                          ),
                        ),

                      const SizedBox(height: 28),

                      // Interactive Navigation Dock (Continue, Supply Shop, Level Select)
                      FadeInUp(
                        delay: const Duration(milliseconds: 700),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 14,
                          alignment: WrapAlignment.center,
                          children: [
                            // 1. Primary Action: NEXT SECTOR / CONTINUE
                            GestureDetector(
                              onTap: () {
                                if (widget.level < 200) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GameScreen(level: widget.level + 1),
                                    ),
                                  );
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.level < 200 ? 'NEXT SECTOR' : 'CONTINUE',
                                        style: GoogleFonts.orbitron(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 3,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(
                                        Icons.fast_forward_rounded,
                                        color: Colors.black,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // 2. Secondary Action: SURVIVOR SUPPLY (SHOP)
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ShopScreen()),
                                );
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF14171E).withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFFFB300).withValues(alpha: 0.8),
                                      width: 1.8,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFB300).withValues(alpha: 0.25),
                                        blurRadius: 14,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.shopping_bag_outlined,
                                        color: Color(0xFFFFB300),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'SURVIVOR SUPPLY',
                                        style: GoogleFonts.orbitron(
                                          color: const Color(0xFFFFB300),
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

                            // 3. Tertiary Action: LEVEL MAP / EVACUATE
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF14171E).withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white24, width: 1.2),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.map_outlined, color: Colors.white70, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'MAP',
                                        style: GoogleFonts.orbitron(
                                          color: Colors.white70,
                                          fontSize: 14,
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
          ),
        ],
      ),
    );
  }

  Widget _buildStar({required double size, required bool isAccent}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isAccent ? const Color(0xFFFFD54F) : const Color(0xFFFFB300)).withValues(alpha: isAccent ? 0.6 : 0.3),
            blurRadius: isAccent ? 25 : 15,
            spreadRadius: isAccent ? 4 : 1,
          ),
        ],
      ),
      child: Icon(
        Icons.star_rounded,
        size: size,
        color: isAccent ? const Color(0xFFFFD54F) : const Color(0xFFFFB300),
      ),
    );
  }

  Widget _buildRewardCard({
    required String title,
    required String subtitle,
    required int amount,
    required String prefix,
    required String suffix,
    required IconData icon,
    required Color themeColor,
    required List<Color> bgGradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: themeColor.withValues(alpha: 0.6), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 20,
          ),
          BoxShadow(
            color: themeColor.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon with glowing neon aura
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F1218),
              border: Border.all(color: themeColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: themeColor, size: 34),
            ),
          ),
          const SizedBox(width: 18),
          // Texts & Animated Counter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: amount.toDouble()),
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, child) {
                    return Text(
                      '$prefix${val.toInt()}$suffix',
                      style: GoogleFonts.orbitron(
                        color: themeColor,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: themeColor.withValues(alpha: 0.6),
                            blurRadius: 14,
                          ),
                          const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
                        ],
                      ),
                    );
                  },
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.oswald(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalStatus({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.oswald(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildNewWeaponUnlockedCard(BuildContext context, WeaponInfo weapon, int nextLevel) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00332C).withValues(alpha: 0.9),
            const Color(0xFF001B2E).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E676), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF072118),
              border: Border.all(color: const Color(0xFF00E676), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E676).withValues(alpha: 0.5),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Icon(weapon.icon, size: 36, color: const Color(0xFF00E676)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '⚡ NEW ARSENAL UNLOCKED',
                        style: GoogleFonts.shareTechMono(
                          color: const Color(0xFF00E676),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'SECTOR 0$nextLevel READY',
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  weapon.name.toUpperCase(),
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weapon.desc,
                  style: GoogleFonts.rajdhani(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'EQUIPPED',
              style: GoogleFonts.orbitron(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextWeaponTeaser(BuildContext context, WeaponInfo weapon, int nextLevel) {
    int levelsRemaining = weapon.unlockLevel - nextLevel;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF12151D).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, color: Color(0xFF00E5FF), size: 16),
          const SizedBox(width: 10),
          Text(
            'NEXT ARSENAL DROP: ${weapon.name.toUpperCase()} (UNLOCKS AT SECTOR 0${weapon.unlockLevel} • $levelsRemaining SECTORS AWAY)',
            style: GoogleFonts.shareTechMono(
              color: const Color(0xFF00E5FF),
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class VictoryEmbersPainter extends CustomPainter {
  final double progress;
  final List<Ember> embers = List.generate(35, (index) {
    final random = Random(index * 1337);
    return Ember(
      startX: random.nextDouble(),
      speed: 0.4 + random.nextDouble() * 0.8,
      size: 2.0 + random.nextDouble() * 4.5,
      isCyan: random.nextBool(),
      swayFrequency: 2.0 + random.nextDouble() * 4.0,
      swayAmplitude: 0.03 + random.nextDouble() * 0.05,
    );
  });

  VictoryEmbersPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    for (var ember in embers) {
      double currentY = (1.0 - ((progress * ember.speed + ember.startX) % 1.0)) * size.height;
      double currentX = (ember.startX + sin(progress * ember.swayFrequency * 2 * pi) * ember.swayAmplitude) * size.width;

      double opacity = sin((currentY / size.height) * pi).clamp(0.0, 1.0);
      Color emberColor = ember.isCyan
          ? const Color(0xFF00E5FF).withValues(alpha: opacity * 0.6)
          : const Color(0xFFFFB300).withValues(alpha: opacity * 0.7);

      final paint = Paint()
        ..color = emberColor
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ember.size * 0.8);

      canvas.drawCircle(Offset(currentX, currentY), ember.size, paint);
      canvas.drawCircle(Offset(currentX, currentY), ember.size * 0.4, Paint()..color = Colors.white.withValues(alpha: opacity * 0.9));
    }
  }

  @override
  bool shouldRepaint(covariant VictoryEmbersPainter oldDelegate) => true;
}

class Ember {
  final double startX;
  final double speed;
  final double size;
  final bool isCyan;
  final double swayFrequency;
  final double swayAmplitude;

  Ember({
    required this.startX,
    required this.speed,
    required this.size,
    required this.isCyan,
    required this.swayFrequency,
    required this.swayAmplitude,
  });
}
