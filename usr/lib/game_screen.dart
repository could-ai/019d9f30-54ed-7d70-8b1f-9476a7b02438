import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';

import 'game/world.dart';
import 'game/player.dart';
import 'game/block.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late World world;
  late Player player;
  late Ticker ticker;
  Duration lastTime = Duration.zero;

  bool moveLeft = false;
  bool moveRight = false;
  bool jump = false;
  
  BlockType selectedBlock = BlockType.dirt;
  final double blockSize = 40.0;

  @override
  void initState() {
    super.initState();
    world = World();
    
    // Find spawn point at x=100
    int spawnX = 100;
    int spawnY = 0;
    for (int y = 0; y < world.height; y++) {
      if (world.getBlock(spawnX, y) != BlockType.air) {
        spawnY = y - 2;
        break;
      }
    }
    
    player = Player(x: spawnX.toDouble(), y: spawnY.toDouble());

    ticker = createTicker(_tick);
    ticker.start();
  }

  void _tick(Duration elapsed) {
    if (lastTime == Duration.zero) {
      lastTime = elapsed;
      return;
    }
    double dt = (elapsed - lastTime).inMicroseconds / 1000000.0;
    lastTime = elapsed;
    
    if (dt > 0.1) dt = 0.1; // Cap dt

    setState(() {
      player.update(dt, world, moveLeft: moveLeft, moveRight: moveRight, jump: jump);
    });
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details, Size screenSize) {
    double cameraX = player.x * blockSize - screenSize.width / 2 + (player.width * blockSize) / 2;
    double cameraY = player.y * blockSize - screenSize.height / 2 + (player.height * blockSize) / 2;

    double worldTapX = details.localPosition.dx + cameraX;
    double worldTapY = details.localPosition.dy + cameraY;

    int bx = (worldTapX / blockSize).floor();
    int by = (worldTapY / blockSize).floor();

    if (world.getBlock(bx, by) == BlockType.air) {
      // Place block
      double dist = sqrt(pow(player.x + player.width/2 - bx, 2) + pow(player.y + player.height/2 - by, 2));
      if (dist < 6.0) {
        bool inPlayer = bx >= player.x.floor() && bx <= (player.x + player.width).floor() &&
                        by >= player.y.floor() && by <= (player.y + player.height).floor();
        if (!inPlayer) {
          world.setBlock(bx, by, selectedBlock);
        }
      }
    } else {
      // Break block
      double dist = sqrt(pow(player.x + player.width/2 - bx, 2) + pow(player.y + player.height/2 - by, 2));
      if (dist < 6.0 && world.getBlock(bx, by) != BlockType.bedrock) {
        world.setBlock(bx, by, BlockType.air);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              GestureDetector(
                onTapDown: (details) => _handleTapDown(details, Size(constraints.maxWidth, constraints.maxHeight)),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: GamePainter(world: world, player: player, blockSize: blockSize),
                ),
              ),
              _buildUI(),
            ],
          );
        }
      ),
    );
  }

  Widget _buildUI() {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHotbarItem(BlockType.dirt),
                  _buildHotbarItem(BlockType.grass),
                  _buildHotbarItem(BlockType.stone),
                  _buildHotbarItem(BlockType.wood),
                  _buildHotbarItem(BlockType.leaves),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0, left: 32.0, right: 32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    _buildControlButton(Icons.arrow_left, (val) => moveLeft = val),
                    const SizedBox(width: 20),
                    _buildControlButton(Icons.arrow_right, (val) => moveRight = val),
                  ],
                ),
                _buildControlButton(Icons.arrow_upward, (val) => jump = val),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotbarItem(BlockType type) {
    bool isSelected = selectedBlock == type;
    return GestureDetector(
      onTap: () => setState(() => selectedBlock = type),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black45,
          border: Border.all(color: isSelected ? Colors.white : Colors.grey, width: isSelected ? 3 : 1),
        ),
        child: CustomPaint(
          painter: BlockPainter(type),
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, Function(bool) onStateChanged) {
    return Listener(
      onPointerDown: (_) => onStateChanged(true),
      onPointerUp: (_) => onStateChanged(false),
      onPointerCancel: (_) => onStateChanged(false),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 40, color: Colors.white),
      ),
    );
  }
}

class BlockPainter extends CustomPainter {
  final BlockType type;
  BlockPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rect = Offset.zero & size;
    
    switch (type) {
      case BlockType.dirt:
        paint.color = const Color(0xFF795548);
        canvas.drawRect(rect, paint);
        break;
      case BlockType.grass:
        paint.color = const Color(0xFF795548);
        canvas.drawRect(rect, paint);
        paint.color = const Color(0xFF4CAF50);
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.3), paint);
        break;
      case BlockType.stone:
        paint.color = const Color(0xFF9E9E9E);
        canvas.drawRect(rect, paint);
        break;
      case BlockType.wood:
        paint.color = const Color(0xFF3E2723);
        canvas.drawRect(rect, paint);
        break;
      case BlockType.leaves:
        paint.color = const Color(0xFF2E7D32).withOpacity(0.8);
        canvas.drawRect(rect, paint);
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GamePainter extends CustomPainter {
  final World world;
  final Player player;
  final double blockSize;

  GamePainter({required this.world, required this.player, required this.blockSize});

  @override
  void paint(Canvas canvas, Size size) {
    // Background sky
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF81D4FA));

    // Camera center
    double cameraX = player.x * blockSize - size.width / 2 + (player.width * blockSize) / 2;
    double cameraY = player.y * blockSize - size.height / 2 + (player.height * blockSize) / 2;

    int startX = max(0, (cameraX / blockSize).floor());
    int endX = min(world.width - 1, ((cameraX + size.width) / blockSize).ceil());
    int startY = max(0, (cameraY / blockSize).floor());
    int endY = min(world.height - 1, ((cameraY + size.height) / blockSize).ceil());

    final paint = Paint();

    for (int x = startX; x <= endX; x++) {
      for (int y = startY; y <= endY; y++) {
        BlockType type = world.getBlock(x, y);
        if (type == BlockType.air) continue;

        double screenX = x * blockSize - cameraX;
        double screenY = y * blockSize - cameraY;
        Rect rect = Rect.fromLTWH(screenX, screenY, blockSize, blockSize);

        switch (type) {
          case BlockType.dirt:
            paint.color = const Color(0xFF795548);
            canvas.drawRect(rect, paint);
            break;
          case BlockType.grass:
            paint.color = const Color(0xFF795548);
            canvas.drawRect(rect, paint);
            paint.color = const Color(0xFF4CAF50);
            canvas.drawRect(Rect.fromLTWH(screenX, screenY, blockSize, blockSize * 0.3), paint);
            break;
          case BlockType.stone:
            paint.color = const Color(0xFF9E9E9E);
            canvas.drawRect(rect, paint);
            break;
          case BlockType.wood:
            paint.color = const Color(0xFF3E2723);
            canvas.drawRect(rect, paint);
            break;
          case BlockType.leaves:
            paint.color = const Color(0xFF2E7D32).withOpacity(0.9);
            canvas.drawRect(rect, paint);
            break;
          case BlockType.bedrock:
            paint.color = const Color(0xFF212121);
            canvas.drawRect(rect, paint);
            break;
          case BlockType.air:
            break;
        }
        
        // Optional: Simple block border
        paint.color = Colors.black12;
        paint.style = PaintingStyle.stroke;
        canvas.drawRect(rect, paint);
        paint.style = PaintingStyle.fill;
      }
    }

    // Draw Player
    double pScreenX = player.x * blockSize - cameraX;
    double pScreenY = player.y * blockSize - cameraY;
    
    // Head
    paint.color = const Color(0xFFFFCC80); 
    canvas.drawRect(Rect.fromLTWH(pScreenX, pScreenY, player.width * blockSize, 0.4 * blockSize), paint);
    
    // Body/Shirt
    paint.color = const Color(0xFF00BCD4); 
    canvas.drawRect(Rect.fromLTWH(pScreenX, pScreenY + 0.4 * blockSize, player.width * blockSize, 0.8 * blockSize), paint);
    
    // Pants
    paint.color = const Color(0xFF3F51B5); 
    canvas.drawRect(Rect.fromLTWH(pScreenX, pScreenY + 1.2 * blockSize, player.width * blockSize, 0.6 * blockSize), paint);
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}
