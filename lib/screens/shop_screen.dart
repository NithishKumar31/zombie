import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/game_state_provider.dart';
import '../utils/app_theme.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameStateProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/new_menu_bg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
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
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      _buildWeaponItem(context, 'Bow', 'Basic starter weapon', 0, Icons.architecture, gameState),
                      _buildWeaponItem(context, 'Battle Axe', 'Fast melee damage', 400, Icons.content_cut, gameState),
                      _buildWeaponItem(context, 'Assault Rifle', 'Automatic rapid fire', 500, Icons.hardware, gameState),
                      _buildWeaponItem(context, 'Shotgun', 'Deadly wide scatter shot', 750, Icons.adjust, gameState),
                      _buildWeaponItem(context, 'War Hammer', 'Massive AOE smash', 1000, Icons.construction, gameState),
                      _buildWeaponItem(context, 'Fire Bow', '3x Damage fiery arrows', 1500, Icons.local_fire_department, gameState),
                      
                      const SizedBox(height: 24),
                      _buildSectionHeader(context, 'ARMOR & HEALTH'),
                      _buildShopItem(context, 'Tactical Vest', 'Reduces damage by 25%', 300, Icons.security, gameState),
                      _buildShopItem(context, 'Medkit', 'Restores full health', 100, Icons.local_hospital, gameState),

                      const SizedBox(height: 24),
                      _buildSectionHeader(context, 'ABILITIES'),
                      _buildShopItem(context, 'Sprint Boost', 'Run 20% faster', 400, Icons.directions_run, gameState),
                      _buildShopItem(context, 'Adrenaline', 'Slow time for 5s', 1000, Icons.speed, gameState),
                    ],
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
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: _woodDecoration(),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back_ios, color: Color(0xFFBCAAA4), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'BACK',
                    style: GoogleFonts.oswald(
                      color: const Color(0xFFBCAAA4),
                      fontSize: 18,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Title with Chains
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildChain(),
                  const SizedBox(width: 140),
                  _buildChain(),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: _woodDecoration().copyWith(
                  border: Border.all(color: const Color(0xFF1F0D06), width: 4),
                ),
                child: Text(
                  'SHOP & UPGRADES',
                  style: GoogleFonts.specialElite(
                    color: const Color(0xFFD7CCC8),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          // Coins
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: _woodDecoration(),
            child: Row(
              children: [
                const Text('💀', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  '${gameState.coins}',
                  style: GoogleFonts.oswald(
                    color: const Color(0xFFFFCC80),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChain() {
    return Column(
      children: List.generate(2, (index) => const Icon(Icons.link, color: Colors.grey, size: 16)),
    );
  }

  BoxDecoration _woodDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF5D4037),
          Color(0xFF3E2723),
          Color(0xFF27150E),
        ],
      ),
      border: Border.all(color: const Color(0xFF1F0D06), width: 2),
      borderRadius: BorderRadius.circular(4),
      boxShadow: const [
        BoxShadow(color: Colors.black87, blurRadius: 4, offset: Offset(2, 4)),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Text(
          title,
          style: GoogleFonts.specialElite(
            color: const Color(0xFF8D6E63),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildRivet() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF3E2723),
        border: Border.all(color: Colors.black, width: 1),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 2)],
      ),
    );
  }

  Widget _buildWeaponItem(BuildContext context, String name, String desc, int price, IconData icon, GameStateProvider gameState) {
    bool isOwned = gameState.unlockedWeapons.contains(name);
    bool isEquipped = gameState.currentWeapon == name;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Stack(
        children: [
          Container(
            decoration: _woodDecoration(),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1F0D06),
                      border: Border.all(color: const Color(0xFF5D4037), width: 3),
                    ),
                    child: Icon(icon, size: 30, color: const Color(0xFF8D6E63)),
                  ),
                  const SizedBox(width: 16),
                  // Texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.toUpperCase(),
                          style: GoogleFonts.oswald(
                            color: const Color(0xFFEFEBE9),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          desc,
                          style: GoogleFonts.lato(
                            color: const Color(0xFFA1887F),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Button
                  GestureDetector(
                    onTap: () {
                      if (isEquipped) return;
                      if (isOwned) {
                        gameState.equipWeapon(name);
                      } else {
                        _purchaseWeapon(context, name, price, gameState);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isEquipped ? const Color(0xFF1B5E20) : const Color(0xFF27150E),
                        border: Border.all(
                          color: isEquipped ? const Color(0xFF4CAF50) : const Color(0xFF5D4037),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          isEquipped
                              ? const Icon(Icons.check, size: 16, color: Color(0xFFAED581))
                              : (isOwned ? const Icon(Icons.swap_horiz, size: 16, color: Color(0xFFFFCC80)) : const Text('💀', style: TextStyle(fontSize: 14))),
                          const SizedBox(width: 8),
                          Text(
                            isEquipped ? 'EQUIPPED' : (isOwned ? 'EQUIP' : price.toString()),
                            style: GoogleFonts.oswald(
                              color: isEquipped ? const Color(0xFFAED581) : const Color(0xFFFFCC80),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Rivets
          Positioned(top: 6, left: 6, child: _buildRivet()),
          Positioned(top: 6, right: 6, child: _buildRivet()),
          Positioned(bottom: 6, left: 6, child: _buildRivet()),
          Positioned(bottom: 6, right: 6, child: _buildRivet()),
        ],
      ),
    );
  }

  Widget _buildShopItem(BuildContext context, String name, String desc, int price, IconData icon, GameStateProvider gameState) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Stack(
        children: [
          Container(
            decoration: _woodDecoration(),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1F0D06),
                      border: Border.all(color: const Color(0xFF5D4037), width: 3),
                    ),
                    child: Icon(icon, size: 30, color: const Color(0xFF8D6E63)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.toUpperCase(),
                          style: GoogleFonts.oswald(
                            color: const Color(0xFFEFEBE9),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          desc,
                          style: GoogleFonts.lato(
                            color: const Color(0xFFA1887F),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _purchaseItem(context, name, price, gameState);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27150E),
                        border: Border.all(color: const Color(0xFF5D4037), width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('💀', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Text(
                            price.toString(),
                            style: GoogleFonts.oswald(
                              color: const Color(0xFFFFCC80),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Rivets
          Positioned(top: 6, left: 6, child: _buildRivet()),
          Positioned(top: 6, right: 6, child: _buildRivet()),
          Positioned(bottom: 6, left: 6, child: _buildRivet()),
          Positioned(bottom: 6, right: 6, child: _buildRivet()),
        ],
      ),
    );
  }

  void _purchaseWeapon(BuildContext context, String item, int price, GameStateProvider provider) async {
    bool success = await provider.spendCoins(price);
    if (!context.mounted) return;

    if (success) {
      provider.unlockWeapon(item);
      provider.equipWeapon(item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unlocked $item!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins!'), backgroundColor: Colors.red),
      );
    }
  }

  void _purchaseItem(BuildContext context, String item, int price, GameStateProvider provider) async {
    bool success = await provider.spendCoins(price);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchased $item!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins!'), backgroundColor: Colors.red),
      );
    }
  }
}

