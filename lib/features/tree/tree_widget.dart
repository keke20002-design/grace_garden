import 'package:flutter/material.dart';

class TreeWidget extends StatefulWidget {
  final int stage; // 0~4
  final double size;
  final bool animate; // 성장 애니메이션 트리거

  const TreeWidget({
    super.key,
    required this.stage,
    this.size = 120,
    this.animate = false,
  });

  @override
  State<TreeWidget> createState() => _TreeWidgetState();
}

class _TreeWidgetState extends State<TreeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  static const stageEmojis = ['🫘', '🌱', '🌿', '🌳', '🍎'];
  static const stageColors = [
    Color(0xFF8B6914),
    Color(0xFF4CAF50),
    Color(0xFF388E3C),
    Color(0xFF2E7D32),
    Color(0xFF1B5E20),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.animate) _controller.forward();
  }

  @override
  void didUpdateWidget(TreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage.clamp(0, 4);
    final color = stageColors[stage];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // 성장 시 빛나는 후광 효과
                if (_controller.isAnimating || _controller.value > 0)
                  Container(
                    width: widget.size * (1 + _glowAnim.value * 0.4),
                    height: widget.size * (1 + _glowAnim.value * 0.4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(
                        alpha: 0.15 * (1 - _glowAnim.value),
                      ),
                    ),
                  ),
                // 메인 나무 컨테이너
                Transform.scale(
                  scale: _scaleAnim.value,
                  child: child,
                ),
              ],
            );
          },
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stageEmojis[stage],
                style: TextStyle(fontSize: widget.size * 0.45),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _StageProgressBar(stage: stage),
      ],
    );
  }
}

class _StageProgressBar extends StatelessWidget {
  final int stage;
  const _StageProgressBar({required this.stage});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final isActive = i <= stage;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: isActive ? 10 : 8,
              height: isActive ? 10 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
                boxShadow: isActive
                    ? [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.4), blurRadius: 4)]
                    : null,
              ),
            ),
            if (i < 4)
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 16,
                height: 2,
                color: i < stage ? colorScheme.primary : colorScheme.outlineVariant,
              ),
          ],
        );
      }),
    );
  }
}

// QT 완료 시 나타나는 축하 오버레이
class TreeGrowthOverlay extends StatefulWidget {
  final int newStage;
  final VoidCallback onDone;

  const TreeGrowthOverlay({
    super.key,
    required this.newStage,
    required this.onDone,
  });

  @override
  State<TreeGrowthOverlay> createState() => _TreeGrowthOverlayState();
}

class _TreeGrowthOverlayState extends State<TreeGrowthOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), widget.onDone);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const stageNames = ['씨앗', '새싹', '어린나무', '성목', '열매나무'];
    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TreeWidget(
                stage: widget.newStage,
                size: 160,
                animate: true,
              ),
              const SizedBox(height: 24),
              Text(
                '🎉 나무가 성장했어요!',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stageNames[widget.newStage.clamp(0, 4)],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
