import 'package:flutter/material.dart';

class ControlPanel extends StatelessWidget {
  final double gravity;
  final double elasticity;
  final double speedDecay;
  final int ballCount;
  final Function(double) onGravityChanged;
  final Function(double) onElasticityChanged;
  final Function(double) onSpeedDecayChanged;
  final Function(int) onBallCountChanged;

  const ControlPanel({
    super.key,
    required this.gravity,
    required this.elasticity,
    required this.speedDecay,
    required this.ballCount,
    required this.onGravityChanged,
    required this.onElasticityChanged,
    required this.onSpeedDecayChanged,
    required this.onBallCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: const Color(0xFF818CF8).withOpacity(0.3),
          width: 1.0,
        ),
        // 添加毛玻璃效果
        backgroundBlendMode: BlendMode.overlay,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          const Text(
            '物理参数控制',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // 粒子数量显示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF2E1065).withOpacity(0.7),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: const Color(0xFF818CF8).withOpacity(0.5),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.bubble_chart,
                  color: Color(0xFF818CF8),
                  size: 20.0,
                ),
                const SizedBox(width: 8.0),
                Text(
                  '粒子数量: $ballCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          
          // 粒子数量滑块
          _buildSlider(
            label: '粒子数量',
            value: ballCount.toDouble(),
            min: 10,
            max: 200,
            divisions: 19,
            activeColor: const Color(0xFF818CF8),
            onChanged: (value) => onBallCountChanged(value.round()),
          ),
          
          // 引力滑块
          _buildSlider(
            label: '引力',
            value: gravity,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            activeColor: const Color(0xFF4F46E5),
            onChanged: onGravityChanged,
          ),
          
          // 弹性系数滑块
          _buildSlider(
            label: '弹性系数',
            value: elasticity,
            min: 0.5,
            max: 1.0,
            divisions: 10,
            activeColor: const Color(0xFF4F46E5),
            onChanged: onElasticityChanged,
          ),
          
          // 速度衰减滑块
          _buildSlider(
            label: '速度衰减',
            value: speedDecay,
            min: 0.9,
            max: 1.0,
            divisions: 10,
            activeColor: const Color(0xFF4F46E5),
            onChanged: onSpeedDecayChanged,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Color activeColor,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14.0,
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: activeColor,
            inactiveTrackColor: activeColor.withOpacity(0.3),
            thumbColor: Colors.white,
            overlayColor: activeColor.withOpacity(0.2),
            trackHeight: 4.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 8.0),
      ],
    );
  }
}