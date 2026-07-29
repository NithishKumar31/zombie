import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math' as math;
import '../providers/game_state_provider.dart';
import '../utils/app_theme.dart';

enum BoardType { title, reward, button }

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

class _RewardScreenState extends State<RewardScreen> {
  @override
  void initState() {
    super.initState();
    // Update the state provider automatically after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if(mounted) {
         context.read<GameStateProvider>().completeGameLevel(widget.level, widget.coinsEarned, widget.xpEarned);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // fallback
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/reward_bg.png',
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.4),
            colorBlendMode: BlendMode.darken,
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
          ),
          
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ZoomIn(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 340,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(padding: const EdgeInsets.only(left: 30), child: _buildChain()),
                              Padding(padding: const EdgeInsets.only(right: 30), child: _buildChain()),
                            ],
                          ),
                        ),
                        CustomPaint(
                          painter: GrungeBoardPainter(boardType: BoardType.title),
                          child: Container(
                            width: 340,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(top: 5, left: 10, child: _buildRivet()),
                              Positioned(bottom: 5, left: 10, child: _buildRivet()),
                              Positioned(top: 5, right: 10, child: _buildRivet()),
                              Positioned(bottom: 5, right: 10, child: _buildRivet()),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'MISSION',
                                      style: TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFDCD8C0),
                                        letterSpacing: 4,
                                        fontFamily: 'serif',
                                        shadows: [Shadow(color: Colors.black, blurRadius: 5, offset: Offset(2, 2))],
                                      ),
                                    ),
                                    const Text(
                                      'ACCOMPLISHED',
                                      style: TextStyle(
                                        fontSize: 35,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF5E8C51),
                                        letterSpacing: 2,
                                        fontFamily: 'serif',
                                        shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    child: _buildRewardRow(Icons.attach_money, 'COINS', widget.coinsEarned, const Color(0xFFD3A336)),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  FadeInUp(
                    delay: const Duration(milliseconds: 1000),
                    child: _buildRewardRow(Icons.star, 'XP', widget.xpEarned, const Color(0xFF5683A3)),
                  ),

                  const SizedBox(height: 50),

                  FadeIn(
                    delay: const Duration(milliseconds: 1500),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: CustomPaint(
                        painter: GrungeBoardPainter(boardType: BoardType.button),
                        child: Container(
                          width: 280,
                          height: 65,
                        child: Stack(
                          children: [
                            Positioned(top: 5, left: 5, child: _buildRivet()),
                            Positioned(bottom: 5, left: 5, child: _buildRivet()),
                            Positioned(top: 5, right: 5, child: _buildRivet()),
                            Positioned(bottom: 5, right: 5, child: _buildRivet()),
                            const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('«', style: TextStyle(color: Color(0xFFD6C8A1), fontSize: 24, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 15),
                                  Text(
                                    'CONTINUE',
                                    style: TextStyle(
                                      color: Color(0xFFD6C8A1),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                      fontFamily: 'serif',
                                      shadows: [Shadow(color: Colors.black, blurRadius: 5, offset: Offset(2, 2))],
                                    ),
                                  ),
                                  SizedBox(width: 15),
                                  Text('»', style: TextStyle(color: Color(0xFFD6C8A1), fontSize: 24, fontWeight: FontWeight.bold)),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardRow(IconData icon, String label, int amount, Color dimColor) {
    return CustomPaint(
      painter: GrungeBoardPainter(boardType: BoardType.reward),
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Stack(
        children: [
          Positioned(top: 0, left: 5, child: _buildRivet()),
          Positioned(bottom: 0, left: 5, child: _buildRivet()),
          Positioned(top: 0, right: 5, child: _buildRivet()),
          Positioned(bottom: 0, right: 5, child: _buildRivet()),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black87,
                    border: Border.all(color: const Color(0xFF5A4634), width: 3), // rusty border
                    boxShadow: const [
                      BoxShadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
                      BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(-1, -1)),
                    ],
                  ),
                  child: Icon(icon, color: dimColor, size: 35),
                ),
                const SizedBox(width: 30),
                SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: const TextStyle(color: Color(0xFFB0A890), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2, fontFamily: 'serif')),
                      Text('+$amount', style: TextStyle(color: dimColor, fontSize: 36, fontWeight: FontWeight.w900, shadows: const [Shadow(color: Colors.black, blurRadius: 5, offset: Offset(2, 2))])),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
      ),
    );
  }

  Widget _buildRivet() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFF8B7355), // rust color
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black87, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 3),
        ],
        gradient: const RadialGradient(
          colors: [Color(0xFFA89F91), Color(0xFF4A3C31)],
          center: Alignment(-0.3, -0.3),
        ),
      ),
    );
  }

  Widget _buildChain() {
    return SizedBox(
      height: 24 + 3 * 18.0, // 4 items, shifted by 18 each
      width: 16,
      child: Stack(
        children: List.generate(4, (index) => Positioned(
          top: index * 18.0,
          child: Container(
            width: 16,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 4),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF5C4033), // rusty brown
              gradient: const LinearGradient(
                colors: [Color(0xFF8B7355), Color(0xFF3E2723)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))],
            ),
            child: Center(
              child: Container(
                 width: 6, height: 14,
                 decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)) // inner hole
              )
            ),
          ),
        )),
      ),
    );
  }
}

class GrungeBoardPainter extends CustomPainter {
  final BoardType boardType;
  GrungeBoardPainter({this.boardType = BoardType.title});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    
    final random = math.Random(42); 
    
    // Draw base shape with slightly irregular edges
    final path = Path();
    path.moveTo(0, 0);
    // top edge
    for (double x = 0; x <= size.width; x += 10) {
      path.lineTo(x, (random.nextDouble() - 0.5) * 6);
    }
    path.lineTo(size.width, 0);
    // right edge
    for (double y = 0; y <= size.height; y += 10) {
      path.lineTo(size.width + (random.nextDouble() - 0.5) * 6, y);
    }
    path.lineTo(size.width, size.height);
    // bottom edge
    for (double x = size.width; x >= 0; x -= 10) {
      path.lineTo(x, size.height + (random.nextDouble() - 0.5) * 6);
    }
    path.lineTo(0, size.height);
    // left edge
    for (double y = size.height; y >= 0; y -= 10) {
      path.lineTo((random.nextDouble() - 0.5) * 6, y);
    }
    path.close();

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path.shift(const Offset(0, 12)), shadowPaint);

    final basePaint = Paint();
    
    List<Color> gradientColors;
    if (boardType == BoardType.title) {
      gradientColors = [const Color(0xFF4A3B2C), const Color(0xFF2C241B), const Color(0xFF3D2F21)];
    } else if (boardType == BoardType.reward) {
      gradientColors = [const Color(0xFF33271D), const Color(0xFF1F1812), const Color(0xFF2A2017)];
    } else { // button
      gradientColors = [const Color(0xFF6B3A2C), const Color(0xFF4A251A), const Color(0xFF5C2F22)];
    }

    basePaint.shader = LinearGradient(
      colors: gradientColors,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(path, basePaint);

    // Draw scratches/grain
    final scratchPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = 0; i < 60; i++) {
      scratchPaint.color = (random.nextBool() ? Colors.black : Colors.white).withOpacity(random.nextDouble() * 0.15);
      double startY = random.nextDouble() * size.height;
      double endY = startY + (random.nextDouble() - 0.5) * 15;
      
      // Horizontal grain for wood
      double startX = random.nextDouble() * size.width * 0.6;
      double endX = startX + random.nextDouble() * size.width * 0.4 + size.width * 0.1;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), scratchPaint);
    }
    
    // Add blood splatters for title board
    if (boardType == BoardType.title) {
      final splatterPaint = Paint()..color = const Color(0xFF5C1A1A).withOpacity(0.7);
      for(int i=0; i<15; i++) {
        double cx = random.nextDouble() * size.width;
        double cy = random.nextDouble() * size.height;
        double r = random.nextDouble() * 4 + 1;
        canvas.drawCircle(Offset(cx, cy), r, splatterPaint);
        // little droplets
        for(int j=0; j<3; j++) {
           canvas.drawCircle(Offset(cx + (random.nextDouble()-0.5)*15, cy + (random.nextDouble()-0.5)*15), r*0.3, splatterPaint);
        }
      }
    }

    // Edge highlight/shadow for 3D effect
    canvas.drawPath(path, Paint()..color = Colors.black.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 4);
    canvas.drawPath(path, Paint()..color = Colors.white.withOpacity(0.15)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    
    // inner rusty edge for rewards
    if (boardType == BoardType.reward) {
       final innerPath = Path();
       innerPath.addRect(Rect.fromLTWH(4, 4, size.width-8, size.height-8));
       canvas.drawPath(innerPath, Paint()..color = const Color(0xFF3E2723)..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
