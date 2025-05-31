import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import 'package:random_color/random_color.dart';

/// 优化的3D球体类
class Ball {
  /// 球的位置向量
  vector_math.Vector3 position;
  
  /// 球的速度向量
  vector_math.Vector3 velocity;
  
  /// 球的半径
  double radius;
  
  /// 球的颜色
  Color color;
  
  /// 简化的轨迹系统 - 只保留少量轨迹点
  List<vector_math.Vector3> trail = [];
  final int maxTrailLength = 8; // 减少轨迹长度
  
  /// 碰撞状态优化
  bool isColliding = false;
  double collisionTime = 0.0;
  static const double collisionEffectDuration = 0.3;
  
  /// 轨迹更新计数器
  int _trailUpdateCounter = 0;
  
  /// 预分配的临时向量，避免频繁内存分配
  static final vector_math.Vector3 _tempVector = vector_math.Vector3.zero();
  static final vector_math.Vector3 _tempNormal = vector_math.Vector3.zero();
  
  Ball({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.color,
  });
  
  /// 优化的随机球体创建
  static Ball random(double containerRadius) {
    final random = Random();
    final randomColor = RandomColor();
    
    // 使用更高效的球面坐标生成
    final theta = random.nextDouble() * 2 * pi;
    final cosPhiRange = 2.0 * random.nextDouble() - 1.0; // [-1, 1]
    final phi = acos(cosPhiRange);
    final r = random.nextDouble() * containerRadius * 0.7; // 确保在容器内部
    
    final sinPhi = sin(phi);
    final x = r * sinPhi * cos(theta);
    final y = r * sinPhi * sin(theta);
    final z = r * cos(phi);
    
    // 减少初始速度范围
    final speedFactor = 1.5;
    final vx = (random.nextDouble() * 2 - 1) * speedFactor;
    final vy = (random.nextDouble() * 2 - 1) * speedFactor;
    final vz = (random.nextDouble() * 2 - 1) * speedFactor;
    
    return Ball(
      position: vector_math.Vector3(x, y, z),
      velocity: vector_math.Vector3(vx, vy, vz),
      radius: 2.0 + random.nextDouble() * 2.0, // 减小球体大小范围
      color: randomColor.randomColor(
        colorBrightness: ColorBrightness.light,
        colorSaturation: ColorSaturation.highSaturation,
      ),
    );
  }
  
  /// 优化的更新方法
  void update(double deltaTime, double containerRadius, double elasticity) {
    // 使用预分配的临时向量避免内存分配
    _tempVector.setFrom(velocity);
    _tempVector.scale(deltaTime);
    position.add(_tempVector);
    
    // 优化轨迹更新 - 降低更新频率
    _trailUpdateCounter++;
    if (_trailUpdateCounter % 2 == 0) { // 每两帧更新一次轨迹
      trail.add(position.clone());
      if (trail.length > maxTrailLength) {
        trail.removeAt(0);
      }
    }
    
    // 更新碰撞状态
    if (isColliding) {
      collisionTime += deltaTime;
      if (collisionTime >= collisionEffectDuration) {
        isColliding = false;
        collisionTime = 0.0;
      }
    }
    
    // 优化的碰撞检测
    final distanceSquared = position.length2; // 使用平方避免开方运算
    final collisionRadiusSquared = (containerRadius - radius) * (containerRadius - radius);
    
    if (distanceSquared > collisionRadiusSquared) {
      // 计算实际距离（只在需要时）
      final distance = sqrt(distanceSquared);
      
      // 计算法线向量（重用临时向量）
      _tempNormal.setFrom(position);
      _tempNormal.normalize();
      _tempNormal.negate();
      
      // 反射速度向量
      final dotProduct = velocity.dot(_tempNormal);
      _tempVector.setFrom(_tempNormal);
      _tempVector.scale(2.0 * dotProduct);
      velocity.sub(_tempVector);
      velocity.scale(elasticity);
      
      // 调整位置到容器内部
      _tempNormal.scale(containerRadius - radius);
      position.setFrom(_tempNormal);
      
      // 触发碰撞特效
      isColliding = true;
      collisionTime = 0.0;
    }
  }
  
  /// 清理资源
  void dispose() {
    trail.clear();
  }
}
