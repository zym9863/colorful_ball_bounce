import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import 'ball.dart';
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
  double speedDecay = 0.98; // 速度衰减系数
  double elasticity = 0.85; // 弹性系数
  double gravity = 0.5;     // 引力系数
  int ballCount = 100;      // 球体数量
  
  // 动画控制器
  late AnimationController _controller;
  
  // 上一帧时间
  late DateTime _lastTime;
  
  // 控制面板显示状态
  bool showControlPanel = true;
  
  @override
  void initState() {
    super.initState();
    
    // 创建初始球体
    _createBalls();
    
    // 初始化动画控制器
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    
    _lastTime = DateTime.now();
    
    // 启动动画循环
    _controller.repeat();
    _controller.addListener(_updateAnimation);
  }
  
  // 创建指定数量的球体
  void _createBalls() {
    balls.clear();
    for (int i = 0; i < ballCount; i++) {
      balls.add(Ball.random(containerRadius));
    }
  }
  
  void _updateAnimation() {
    final now = DateTime.now();
    final deltaTime = now.difference(_lastTime).inMilliseconds / 1000.0;
    _lastTime = now;
    
    // 更新容器旋转
    setState(() {
      rotationX += 0.01;
      rotationY += 0.007;
      
      // 更新所有球体
      for (final ball in balls) {
        // 应用物理参数
        ball.velocity *= speedDecay;
        // 应用引力 - 向下的力
        ball.velocity.y += gravity * deltaTime;
        
        ball.update(deltaTime, containerRadius, elasticity);
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 处理物理参数变化
  void _handleGravityChanged(double value) {
    setState(() {
      gravity = value;
    });
  }
  
  void _handleElasticityChanged(double value) {
    setState(() {
      elasticity = value;
    });
  }
  
  void _handleSpeedDecayChanged(double value) {
    setState(() {
      speedDecay = value;
    });
  }
  
  void _handleBallCountChanged(int value) {
    setState(() {
      ballCount = value;
      _createBalls();
    });
  }
  
  // 切换控制面板显示状态
  void _toggleControlPanel() {
    setState(() {
      showControlPanel = !showControlPanel;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 球体容器
        Center(
          child: Container(
            width: containerRadius * 2,
            height: containerRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4F46E5), width: 3.0, style: BorderStyle.solid),
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
              painter: BallPainter(
                balls: balls,
                containerRadius: containerRadius,
                rotationX: rotationX,
                rotationY: rotationY,
              ),
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

class BallPainter extends CustomPainter {
  final List<Ball> balls;
  final double containerRadius;
  final double rotationX;
  final double rotationY;
  
  BallPainter({
    required this.balls,
    required this.containerRadius,
    required this.rotationX,
    required this.rotationY,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // 绘制容器球体 - 使用虚线描边
    final containerPaint = Paint()
      ..color = const Color(0xFF4F46E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    // 绘制虚线圆
    final dashLength = 5.0;
    final gapLength = 3.0;
    final circumference = 2 * 3.14159265359 * containerRadius;
    final dashCount = (circumference / (dashLength + gapLength)).floor();
    
    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * (dashLength + gapLength) / containerRadius;
      final sweepAngle = dashLength / containerRadius;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: containerRadius),
        startAngle,
        sweepAngle,
        false,
        containerPaint,
      );
    }
    
    // 创建旋转矩阵
    final rotationMatrix = vector_math.Matrix4.identity()
      ..rotateX(rotationX)
      ..rotateY(rotationY);
    
    // 按照深度排序球体（从远到近）
    final sortedBalls = List<Ball>.from(balls);
    sortedBalls.sort((a, b) {
      final posA = rotationMatrix.transformed3(a.position);
      final posB = rotationMatrix.transformed3(b.position);
      return posB.z.compareTo(posA.z);
    });
    
    // 绘制所有球体及其轨迹
    for (final ball in sortedBalls) {
      _drawBallTrail(canvas, center, ball, rotationMatrix);
      _drawBall(canvas, center, ball, rotationMatrix);
    }
  }
  
  void _drawBallTrail(Canvas canvas, Offset center, Ball ball, vector_math.Matrix4 rotationMatrix) {
    if (ball.trail.length < 2) return;
    
    // 创建轨迹路径
    final path = Path();
    
    // 霓虹效果的轨迹
    final trailPaint = Paint()
      ..color = ball.color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0); // 添加发光效果
    
    // 计算第一个点的屏幕坐标
    final firstPos = rotationMatrix.transformed3(ball.trail.first);
    path.moveTo(
      center.dx + firstPos.x,
      center.dy + firstPos.y,
    );
    
    // 添加其余点到路径
    for (int i = 1; i < ball.trail.length; i++) {
      final pos = rotationMatrix.transformed3(ball.trail[i]);
      path.lineTo(
        center.dx + pos.x,
        center.dy + pos.y,
      );
      
      // 逐渐增加透明度和宽度
      final progress = i / ball.trail.length;
      trailPaint.color = ball.color.withOpacity(progress * 0.8);
      trailPaint.strokeWidth = 3.0 * progress;
    }
    
    // 绘制轨迹
    canvas.drawPath(path, trailPaint);
    
    // 添加额外的发光效果
    final glowPaint = Paint()
      ..color = ball.color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    
    canvas.drawPath(path, glowPaint);
  }
  
  void _drawBall(Canvas canvas, Offset center, Ball ball, vector_math.Matrix4 rotationMatrix) {
    // 应用旋转变换
    final transformedPosition = rotationMatrix.transformed3(ball.position);
    
    // 计算球在屏幕上的位置
    final screenX = center.dx + transformedPosition.x;
    final screenY = center.dy + transformedPosition.y;
    
    // 计算球的视觉大小（基于z坐标）
    final scale = _calculateScaleFactor(transformedPosition.z, containerRadius);
    var visualRadius = ball.radius * scale;
    
    // 计算球的亮度（基于z坐标）
    final brightness = _calculateBrightness(transformedPosition.z, containerRadius);
    
    // 碰撞特效 - 挤压变形和放大效果
    double scaleX = 1.0;
    double scaleY = 1.0;
    double collisionGlowOpacity = 0.0;
    
    if (ball.isColliding) {
      // 计算碰撞效果的强度 (0.0 到 1.0)
      final effectProgress = 1.0 - (ball.collisionTime / ball.collisionEffectDuration);
      
      // 挤压变形效果 - Y轴缩放至80%
      scaleY = 0.8 + (0.2 * (1.0 - effectProgress));
      scaleX = 1.0 + (0.2 * effectProgress); // X轴相应扩大
      
      // 碰撞时半径临时扩大20%
      visualRadius *= 1.0 + (0.2 * effectProgress);
      
      // 碰撞光晕不透明度
      collisionGlowOpacity = effectProgress * 0.8;
    }
    
    // 创建球的渐变填充 - 半透明玻璃质感
    final gradient = RadialGradient(
      colors: [
        Color.lerp(ball.color, Colors.white, 0.8)!,
        ball.color.withOpacity(0.7),
        Color.lerp(ball.color, Colors.black, 0.3)!.withOpacity(0.5),
      ],
      stops: const [0.1, 0.4, 1.0],
      center: const Alignment(-0.3, -0.3),
    );
    
    // 保存画布状态
    canvas.save();
    
    // 应用挤压变形
    canvas.translate(screenX, screenY);
    canvas.scale(scaleX, scaleY);
    canvas.translate(-screenX, -screenY);
    
    // 绘制球体
    final ballPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(
          center: Offset(screenX, screenY),
          radius: visualRadius,
        ),
      )
      ..color = ball.color.withOpacity(brightness)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5); // 轻微模糊增加玻璃感
    
    // 绘制主球体
    canvas.drawCircle(Offset(screenX, screenY), visualRadius, ballPaint);
    
    // 添加高光
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(screenX - visualRadius * 0.3, screenY - visualRadius * 0.3),
      visualRadius * 0.2,
      highlightPaint,
    );
    
    // 恢复画布状态
    canvas.restore();
    
    // 添加外发光效果
    final glowPaint = Paint()
      ..color = ball.color.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    
    canvas.drawCircle(Offset(screenX, screenY), visualRadius * 1.2, glowPaint);
    
    // 添加碰撞特效 - 珊瑚红光晕
    if (ball.isColliding) {
      final collisionPaint = Paint()
        ..color = const Color(0xFFFF6B6B).withOpacity(collisionGlowOpacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      
      canvas.drawCircle(Offset(screenX, screenY), visualRadius * 1.5, collisionPaint);
    }
  }
  
  // 根据z坐标计算缩放因子
  double _calculateScaleFactor(double z, double maxRadius) {
    // 将z范围从[-maxRadius, maxRadius]映射到[0.7, 1.3]
    return 1.0 + (z / maxRadius) * 0.3;
  }
  
  // 根据z坐标计算亮度
  double _calculateBrightness(double z, double maxRadius) {
    // 将z范围从[-maxRadius, maxRadius]映射到[0.5, 1.0]
    return 0.75 + (z / maxRadius) * 0.25;
  }
  
  @override
  bool shouldRepaint(BallPainter oldDelegate) {
    return oldDelegate.rotationX != rotationX || 
           oldDelegate.rotationY != rotationY ||
           oldDelegate.balls != balls;
  }
}