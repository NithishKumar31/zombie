import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../utils/app_theme.dart';
import 'level_selector_screen.dart';
import 'shop_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                // The exact image the user provided
                Image.asset(
                  'assets/images/welcome_screen_bg.jpg',
                  width: 1920,
                  height: 1080,
                  fit: BoxFit.fill,
                ),
                
                // --- INVISIBLE HITBOXES ---
                
                // PLAY
                Positioned(
                  left: 600, 
                  top: 480, 
                  width: 720, 
                  height: 110,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelSelectorScreen()));
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
                
                // SHOP & UPGRADES
                Positioned(
                  left: 600, 
                  top: 610, 
                  width: 720, 
                  height: 110,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
                
                // SETTINGS
                Positioned(
                  left: 600, 
                  top: 740, 
                  width: 720, 
                  height: 110,
                  child: GestureDetector(
                    onTap: () {
                      _showSettingsDialog(context);
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
                
                // ACHIEVEMENTS
                Positioned(
                  left: 600, 
                  top: 870, 
                  width: 720, 
                  height: 110,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.backgroundColor,
          title: const Text('SETTINGS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<GameStateProvider>(
                builder: (context, state, child) {
                  return SwitchListTile(
                    title: const Text('Sound Effects', style: TextStyle(color: Colors.white)),
                    value: state.soundEnabled,
                    activeColor: Colors.redAccent,
                    onChanged: (val) => state.toggleSound(),
                  );
                },
              ),
              Consumer<GameStateProvider>(
                builder: (context, state, child) {
                  return SwitchListTile(
                    title: const Text('Music', style: TextStyle(color: Colors.white)),
                    value: state.musicEnabled,
                    activeColor: Colors.redAccent,
                    onChanged: (val) => state.toggleMusic(),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CLOSE', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }
}
