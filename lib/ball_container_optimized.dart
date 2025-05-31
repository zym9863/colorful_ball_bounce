import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import 'ball_optimized.dart';
import 'control_panel.dart';

class BallContainer extends StatefulWidget {
  const BallContainer({super.key});

  @override
  State<BallContainer> createState() => _BallContainerState();
}

class _BallContainerState extends State<BallContainer> with SingleTickerProviderStateMixin {
  // 容器球体的半径
  final double containerRadius = 150.0;
  
  // 球体列表
  final List<Ball> balls = [];
  
  // 容器旋转角度
  double rotationX = 0.0;
  double rotationY = 0.0;
  
  // 物理参数
  double speedDecay = 0.98;
  double elasticity = 0.85;
  double gravity = 0.5;
  int ballCount = 50; // 减少默认球数量
  
  // 动画控制器
  late AnimationController _controller;
  
  // 上一帧时间
  late DateTime _lastTime;
  
  // 控制面板显示状态
  bool showControlPanel = true;
  
  // 性能优化：缓存计算结果
  final List<vector_math.Vector3> _transformedPositions = [];
  final List<double> _depthValues = [];
  final List<int> _sortedIndices = [];
  
  // 性能监控
  int _frameCount = 0;
  double _fps = 0.0;
  late DateTime _fpsLastTime;
  
  @override
  void initState() {
    super.initState();
    
    _createBalls();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    
    _lastTime = DateTime.now();
    _fpsLastTime = DateTime.now();
    
    // 使用更高效的动画循环
    _controller.repeat();
    _controller.addListener(_updateAnimation);
  }
  
  void _createBalls() {
    balls.clear();
    _transformedPositions.clear();
    _depthValues.clear();
    _sortedIndices.clear();
    
    for (int i = 0; i < ballCount; i++) {
      balls.add(Ball.random(containerRadius));
      _transformedPositions.add(vector_math.Vector3.zero());
      _depthValues.add(0.0);
      _sortedIndices.add(i);
    }
  }
  
  void _updateAnimation() {
    final now = DateTime.now();
    final deltaTime = now.difference(_lastTime).inMilliseconds / 1000.0;
    _lastTime = now;
    
    // 计算FPS
    _frameCount++;
    if (now.difference(_fpsLastTime).inMilliseconds >= 1000) {
      _fps = _frameCount / (now.difference(_fpsLastTime).inMilliseconds / 1000.0);
      _frameCount = 0;
      _fpsLastTime = now;
    }
    
    // 限制最大deltaTime以避免大幅跳跃
    final clampedDeltaTime = deltaTime.clamp(0.0, 0.033); // 最大30fps
    
    // 更新容器旋转
    rotationX += 0.01;
    rotationY += 0.007;
    
    // 创建旋转矩阵（一次性计算）
    final rotationMatrix = vector_math.Matrix4.identity()
      ..rotateX(rotationX)
      ..rotateY(rotationY);
    
    // 批量更新所有球体
    for (int i = 0; i < balls.length; i++) {
      final ball = balls[i];
      
      // 应用物理参数
      ball.velocity *= speedDecay;
      ball.velocity.y += gravity * clampedDeltaTime;
      
      ball.update(clampedDeltaTime, containerRadius, elasticity);
      
      // 预计算变换后的位置和深度
      _transformedPositions[i] = rotationMatrix.transformed3(ball.position);
      _depthValues[i] = _transformedPositions[i].z;
    }
    
    // 更新排序索引（使用更高效的排序）
    _updateSortedIndices();
    
    setState(() {
      // 只更新必要的状态
    });
  }
  
  // 高效的深度排序
  void _updateSortedIndices() {
    // 使用插入排序，对于大部分已排序的数据更高效
    for (int i = 1; i < _sortedIndices.length; i++) {
      final key = _sortedIndices[i];
      final keyDepth = _depthValues[key];
      int j = i - 1;
      
      while (j >= 0 && _depthValues[_sortedIndices[j]] < keyDepth) {
        _sortedIndices[j + 1] = _sortedIndices[j];
        j--;
      }
      _sortedIndices[j + 1] = key;
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleGravityChanged(double value) {
    gravity = value;
  }
  
  void _handleElasticityChanged(double value) {
    elasticity = value;
  }
  
  void _handleSpeedDecayChanged(double value) {
    speedDecay = value;
  }
  
  void _handleBallCountChanged(int value) {
    ballCount = value;
    _createBalls();
  }
  
  void _toggleControlPanel() {
    setState(() {
      showControlPanel = !showControlPanel;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 使用RepaintBoundary优化重绘
        RepaintBoundary(
          child: Center(
            child: Container(
              width: containerRadius * 2,
              height: containerRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4F46E5),
                  width: 3.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF818CF8).withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF818CF8).withOpacity(0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
              child: CustomPaint(
                painter: OptimizedBallPainter(
                  balls: balls,
                  transformedPositions: _transformedPositions,
                  sortedIndices: _sortedIndices,
                  containerRadius: containerRadius,
                ),
              ),
            ),
          ),
        ),
        
        // FPS显示
        Positioned(
          top: 50,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'FPS: ${_fps.toStringAsFixed(1)}',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        
        // 控制面板切换按钮
        Positioned(
          bottom: 16,
          left: 16,
          child: FloatingActionButton.small(
            onPressed: _toggleControlPanel,
            backgroundColor: const Color(0xFF4F46E5),
            child: Icon(
              showControlPanel ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
          ),
        ),
        
        // 控制面板
        if (showControlPanel)
          Positioned(
            bottom: 16,
            right: 16,
            child: ControlPanel(
              gravity: gravity,
              elasticity: elasticity,
              speedDecay: speedDecay,
              ballCount: ballCount,
              onGravityChanged: _handleGravityChanged,
              onElasticityChanged: _handleElasticityChanged,
              onSpeedDecayChanged: _handleSpeedDecayChanged,
              onBallCountChanged: _handleBallCountChanged,
            ),
          ),
      ],
    );
  }
}

class OptimizedBallPainter extends CustomPainter {
  final List<Ball> balls;
  final List<vector_math.Vector3> transformedPositions;
  final List<int> sortedIndices;
  final double containerRadius;
  
  // 缓存Paint对象以避免重复创建
  static final Paint _containerPaint = Paint()
    ..color = const Color(0xFF4F46E5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0;
    
  static final Paint _trailPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
    
  static final Paint _ballPaint = Paint()
    ..style = PaintingStyle.fill;
    
  static final Paint _highlightPaint = Paint()
    ..color = Colors.white.withOpacity(0.7)
    ..style = PaintingStyle.fill;
    
  static final Paint _glowPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
  
  OptimizedBallPainter({
    required this.balls,
    required this.transformedPositions,
    required this.sortedIndices,
    required this.containerRadius,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // 绘制容器边框（简化版本）
    canvas.drawCircle(center, containerRadius, _containerPaint);
    
    // 绘制球体（使用预计算的排序）
    for (final index in sortedIndices) {
      _drawBallOptimized(canvas, center, balls[index], transformedPositions[index]);
    }
  }
  
  void _drawBallOptimized(Canvas canvas, Offset center, Ball ball, vector_math.Vector3 transformedPos) {
    final screenX = center.dx + transformedPos.x;
    final screenY = center.dy + transformedPos.y;
    
    // 简化的视觉大小计算
    final scale = 1.0 + (transformedPos.z / containerRadius) * 0.3;
    final visualRadius = ball.radius * scale;
    
    // 简化的亮度计算
    final brightness = 0.75 + (transformedPos.z / containerRadius) * 0.25;
    
    final screenPos = Offset(screenX, screenY);
    
    // 简化的球体绘制 - 减少图层数量
    _ballPaint.color = ball.color.withOpacity(brightness.clamp(0.5, 1.0));
    canvas.drawCircle(screenPos, visualRadius, _ballPaint);
    
    // 只在特定条件下绘制高光
    if (visualRadius > 3.0) {
      canvas.drawCircle(
        Offset(screenX - visualRadius * 0.3, screenY - visualRadius * 0.3),
        visualRadius * 0.2,
        _highlightPaint,
      );
    }
    
    // 碰撞效果（简化版本）
    if (ball.isColliding) {
      final effectProgress = 1.0 - (ball.collisionTime / Ball.collisionEffectDuration);
      _glowPaint.color = const Color(0xFFFF6B6B).withOpacity(effectProgress * 0.6);
      canvas.drawCircle(screenPos, visualRadius * 1.3, _glowPaint);
    }
  }
  
  @override
  bool shouldRepaint(OptimizedBallPainter oldDelegate) {
    return true; // 总是重绘，但内部已优化
  }
}
