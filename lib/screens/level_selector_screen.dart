import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/game_state_provider.dart';
import 'game_screen.dart';

class LevelSelectorScreen extends StatefulWidget {
  const LevelSelectorScreen({super.key});

  @override
  State<LevelSelectorScreen> createState() => _LevelSelectorScreenState();
}

class _LevelSelectorScreenState extends State<LevelSelectorScreen> {
  int _currentPage = 0;
  final int _totalPages = 10; // 100 levels / 10 per page

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameStateProvider>();
    
    // Coordinates based on the precise layout of the provided 1920x1080 background image
    final List<Offset> cardOffsets = [
      // Row 1
      const Offset(195, 215),
      const Offset(507, 215),
      const Offset(819, 215),
      const Offset(1131, 215),
      const Offset(1443, 215),
      // Row 2
      const Offset(195, 585),
      const Offset(507, 585),
      const Offset(819, 585),
      const Offset(1131, 585),
      const Offset(1443, 585),
    ];
    
    const double cardWidth = 270;
    const double cardHeight = 330;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            width: 1920,
            height: 1080,
            child: Stack(
              children: [
                // 1. EXACT BACKGROUND IMAGE
                Image.asset(
                  'assets/images/level_select_bg.jpg',
                  width: 1920,
                  height: 1080,
                  fit: BoxFit.fill,
                ),
                
                // 2. BACK BUTTON HITBOX (Top Left)
                Positioned(
                  left: 60, top: 40, width: 150, height: 100,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                
                // 3. LEVEL CARDS (Patched and Dynamic)
                ...List.generate(10, (index) {
                  int levelNumber = (_currentPage * 10) + index + 1;
                  bool isUnlocked = levelNumber <= gameState.highestLevelUnlocked;
                  
                  // Pick the crop rect for the card background
                  // If unlocked, always use Card 1 (which has the glowing amber border and gold star ribbon)
                  // If locked, use a variety of the locked cards (Cards 2 to 10)
                  Rect backgroundCropRect;
                  if (isUnlocked) {
                    backgroundCropRect = Rect.fromLTWH(cardOffsets[0].dx, cardOffsets[0].dy, cardWidth, cardHeight);
                  } else {
                    int lockedCardIndex = (levelNumber % 9) + 1; // Maps to index 1 through 9
                    backgroundCropRect = Rect.fromLTWH(cardOffsets[lockedCardIndex].dx, cardOffsets[lockedCardIndex].dy, cardWidth, cardHeight);
                  }
                  
                  return Positioned(
                    left: cardOffsets[index].dx,
                    top: cardOffsets[index].dy,
                    width: cardWidth,
                    height: cardHeight,
                    child: GestureDetector(
                      onTap: isUnlocked ? () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(level: levelNumber)));
                      } : null,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // EXACT TILE BACKGROUND: Crop the appropriate card from the image and display it here
                          ClipRect(
                            child: SizedBox(
                              width: cardWidth,
                              height: cardHeight,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: -backgroundCropRect.left,
                                    top: -backgroundCropRect.top,
                                    child: Image.asset(
                                      'assets/images/level_select_bg.jpg',
                                      width: 1920,
                                      height: 1080,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // PATCH: Hide the existing baked-in number with a matching dark wood gradient
                          Positioned(
                            top: 80, // Below the ribbon
                            bottom: 25, // Above the bottom inner border
                            left: 30, // Inside the left nails
                            right: 30, // Inside the right nails
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF3B2519), // Match the inner wood shadow
                                    Color(0xFF331D12),
                                    Color(0xFF28140B),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          
                          // DYNAMIC CONTENT (Numbers, Stars, Locks)
                          Positioned(
                            top: 95,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Level Number
                                Text(
                                  levelNumber.toString().padLeft(2, '0'),
                                  style: GoogleFonts.oswald(
                                    color: isUnlocked ? const Color(0xFFF0E6D2) : Colors.white54,
                                    fontSize: 65,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                    shadows: isUnlocked ? const [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))] : null,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // Stars / Lock
                                if (isUnlocked)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(3, (i) => const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 2.0),
                                      child: Icon(Icons.star, color: Color(0xFFE8B62C), size: 28, shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1))]),
                                    )),
                                  )
                                else
                                  const Icon(Icons.lock, color: Colors.white54, size: 36),
                                  
                                const SizedBox(height: 15),
                                
                                // "LEVEL X" Text
                                Text(
                                  'LEVEL $levelNumber',
                                  style: GoogleFonts.oswald(
                                    color: isUnlocked ? const Color(0xFFC7A87A) : Colors.white38,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                
                // 4. PAGINATION ARROWS (To support all 100 levels across 10 pages)
                if (_currentPage > 0)
                  Positioned(
                    left: 50,
                    top: 500,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.amber, size: 70, shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 2))]),
                      onPressed: () {
                        setState(() { _currentPage--; });
                      },
                    ),
                  ),
                  
                if (_currentPage < _totalPages - 1)
                  Positioned(
                    right: 40,
                    top: 500,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: Colors.amber, size: 70, shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 2))]),
                      onPressed: () {
                        setState(() { _currentPage++; });
                      },
                    ),
                  ),
                  
                // 5. PROGRESS BAR OVERLAY (Dynamic progress)
                Positioned(
                  left: 200,
                  top: 978,
                  width: 1390,
                  height: 34,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (gameState.highestLevelUnlocked * 3) / 300,
                        backgroundColor: const Color(0xFF120B06), // Covers the existing empty bar
                        color: const Color(0xFFDB9922), // Gold bar fill
                      ),
                    ),
                  ),
                ),
                
                // 6. PROGRESS TEXT OVERLAY (Dynamic text)
                Positioned(
                  left: 1610,
                  top: 970,
                  width: 100,
                  height: 40,
                  child: Container(
                    color: const Color(0xFF28180E), // Wood color patch to cover the baked-in "3/300" text
                    alignment: Alignment.center,
                    child: Text(
                      '${gameState.highestLevelUnlocked * 3}/300',
                      style: GoogleFonts.oswald(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
