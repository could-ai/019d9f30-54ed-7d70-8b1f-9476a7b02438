import 'world.dart';
import 'block.dart';

class Player {
  double x;
  double y;
  double vx = 0;
  double vy = 0;
  
  final double width = 0.8;
  final double height = 1.8;
  
  final double speed = 6.0;
  final double jumpForce = 9.0;
  final double gravity = 25.0;
  final double terminalVelocity = 20.0;
  
  bool isGrounded = false;

  Player({required this.x, required this.y});

  void update(double dt, World world, {bool moveLeft = false, bool moveRight = false, bool jump = false}) {
    // Horizontal Movement
    if (moveLeft) {
      vx = -speed;
    } else if (moveRight) {
      vx = speed;
    } else {
      vx = 0;
    }

    // Jumping
    if (jump && isGrounded) {
      vy = -jumpForce;
      isGrounded = false;
    }

    // Apply gravity
    vy += gravity * dt;
    if (vy > terminalVelocity) vy = terminalVelocity;

    // Apply X velocity and resolve collisions
    x += vx * dt;
    if (_checkCollision(world)) {
      if (vx > 0) {
        x = (x + width).floor() - width - 0.001;
      } else if (vx < 0) {
        x = x.floor() + 1.0;
      }
      vx = 0;
    }

    // Apply Y velocity and resolve collisions
    y += vy * dt;
    isGrounded = false;
    if (_checkCollision(world)) {
      if (vy > 0) {
        y = (y + height).floor() - height - 0.001;
        isGrounded = true;
      } else if (vy < 0) {
        y = y.floor() + 1.0;
      }
      vy = 0;
    }
    
    // Level Bounds check
    if (x < 0) x = 0;
    if (x > world.width - width) x = world.width - width;
    if (y < 0) y = 0;
    if (y > world.height - height) {
      y = world.height - height;
      isGrounded = true;
      vy = 0;
    }
  }

  bool _checkCollision(World world) {
    // Slightly shrink bounding box to avoid sliding stickiness
    int left = (x + 0.01).floor();
    int right = (x + width - 0.01).floor();
    int top = (y + 0.01).floor();
    int bottom = (y + height - 0.01).floor();

    for (int bx = left; bx <= right; bx++) {
      for (int by = top; by <= bottom; by++) {
        if (world.getBlock(bx, by) != BlockType.air) {
          return true;
        }
      }
    }
    return false;
  }
}
