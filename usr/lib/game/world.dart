import 'dart:math';
import 'block.dart';

class World {
  final int width;
  final int height;
  late List<List<BlockType>> grid;

  World({this.width = 200, this.height = 64}) {
    _generateWorld();
  }

  void _generateWorld() {
    grid = List.generate(width, (x) => List.filled(height, BlockType.air));
    final rand = Random();
    
    // Simple procedural terrain generation
    int terrainHeight = height ~/ 2;
    for (int x = 0; x < width; x++) {
      // Random walk for terrain surface
      if (rand.nextDouble() < 0.3) {
        terrainHeight += rand.nextInt(3) - 1;
      }
      
      // Clamp terrain height
      if (terrainHeight < 10) terrainHeight = 10;
      if (terrainHeight > height - 10) terrainHeight = height - 10;
      
      for (int y = 0; y < height; y++) {
        if (y == height - 1) {
          grid[x][y] = BlockType.bedrock;
        } else if (y > terrainHeight + 5) {
          grid[x][y] = BlockType.stone;
        } else if (y > terrainHeight) {
          grid[x][y] = BlockType.dirt;
        } else if (y == terrainHeight) {
          grid[x][y] = BlockType.grass;
        }
      }
      
      // Generate Trees
      if (rand.nextDouble() < 0.08 && x > 2 && x < width - 2) {
        int treeHeight = 3 + rand.nextInt(3);
        // Trunk
        for (int i = 0; i < treeHeight; i++) {
          if (terrainHeight - 1 - i >= 0) {
            grid[x][terrainHeight - 1 - i] = BlockType.wood;
          }
        }
        // Leaves
        for (int lx = x - 1; lx <= x + 1; lx++) {
          for (int ly = terrainHeight - treeHeight - 2; ly <= terrainHeight - treeHeight; ly++) {
            if (lx >= 0 && lx < width && ly >= 0 && ly < height) {
              if (grid[lx][ly] == BlockType.air) {
                grid[lx][ly] = BlockType.leaves;
              }
            }
          }
        }
      }
    }
  }

  BlockType getBlock(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return BlockType.bedrock;
    return grid[x][y];
  }

  void setBlock(int x, int y, BlockType type) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;
    grid[x][y] = type;
  }
}
