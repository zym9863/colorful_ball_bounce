import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import 'package:random_color/random_color.dart';

/// 表示一个3D空间中的球体
class Ball {
  /// 球的位置向量
  vector_math.Vector3 position;
  
  /// 球的速度向量
  vector_math.Vector3 velocity;
  
  /// 球的半径
  double radius;
  
  /// 球的颜色
  Color color;
  
  /// 球的轨迹点列表，用于绘制轨迹
  List<vector_math.Vector3> trail = [];
  
  /// 轨迹的最大长度
  final int maxTrailLength = 20;
  
  /// 创建一个新的球体
  Ball({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.color,
  });
  
  /// 根据随机参数创建一个球体
  static Ball random(double containerRadius) {
    final random = Random();
    final randomColor = RandomColor();
    
    // 在球体内随机生成位置
    final theta = random.nextDouble() * 2 * pi;
    final phi = random.nextDouble() * pi;
    final r = random.nextDouble() * containerRadius * 0.8; // 确保在容器内部
    
    final x = r * sin(phi) * cos(theta);
    final y = r * sin(phi) * sin(theta);
    final z = r * cos(phi);
    
    // 随机速度
    final speedFactor = 2.0;
    final vx = (random.nextDouble() * 2 - 1) * speedFactor;
    final vy = (random.nextDouble() * 2 - 1) * speedFactor;
    final vz = (random.nextDouble() * 2 - 1) * speedFactor;
    
    return Ball(
      position: vector_math.Vector3(x, y, z),
      velocity: vector_math.Vector3(vx, vy, vz),
      radius: 2.0 + random.nextDouble() * 3.0, // 随机半径在2.0到5.0之间
      color: randomColor.randomColor(colorBrightness: ColorBrightness.light),
    );
  }
  
  /// 碰撞状态 - 用于实现碰撞特效
  bool isColliding = false;
  double collisionTime = 0.0;
  double collisionEffectDuration = 0.3; // 碰撞特效持续时间（秒）
  
  /// 更新球的位置和轨迹
  void update(double deltaTime, double containerRadius, double elasticity) {
    // 更新位置
    position += velocity * deltaTime;
    
    // 添加当前位置到轨迹
    trail.add(position.clone());
    
    // 限制轨迹长度
    if (trail.length > maxTrailLength) {
      trail.removeAt(0);
    }
    
    // 更新碰撞状态
    if (isColliding) {
      collisionTime += deltaTime;
      if (collisionTime >= collisionEffectDuration) {
        isColliding = false;
        collisionTime = 0.0;
      }
    }
    
    // 检测与容器的碰撞
    final distance = position.length;
    if (distance + radius > containerRadius) {
      // 计算法线向量（从球心指向容器中心的单位向量）
      final normal = -position.normalized();
      
      // 反射速度向量并应用弹性系数
      velocity = velocity.reflected(normal) * elasticity;
      
      // 将球体位置调整到容器内部
      position = normal * (containerRadius - radius);
      
      // 触发碰撞特效
      isColliding = true;
      collisionTime = 0.0;
    }
  }
}