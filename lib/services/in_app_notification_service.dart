import 'package:flutter/material.dart';

/// 인앱 알림 카드 서비스.
/// 외부 패키지 없이 Flutter 내장 OverlayEntry + AnimationController 사용.
/// 화면 상단에서 카드가 하나씩 슬라이드 인 → 자동으로 사라짐.
class InAppNotificationService {
  InAppNotificationService._();
  static final InAppNotificationService instance =
      InAppNotificationService._();

  Future<void> showExpiryNotifications(List<ExpiryInfo> foods) async {
    if (foods.isEmpty) {
      _showCard(
        title: '유통기한 임박 식재료가 없어요',
        subtitle: '냉장고 상태가 양호합니다 👍',
        color: const Color(0xFF059669),
        index: 0,
        total: 1,
      );
      return;
    }

    for (int i = 0; i < foods.length; i++) {
      await Future.delayed(Duration(milliseconds: i == 0 ? 0 : 400));
      final food = foods[i];
      final isExpired = food.daysLeft < 0;
      final isWarning = food.daysLeft > 0 && food.daysLeft <= 2;
      final color = isExpired
          ? const Color(0xFFF04452)
          : isWarning
              ? const Color(0xFFFF8800)
              : const Color(0xFF059669);
      final subtitle = isExpired
          ? '이미 유통기한이 지났어요. 확인해보세요!'
          : food.daysLeft == 0
              ? '오늘이 유통기한이에요. 빠르게 드세요!'
              : '${food.daysLeft}일 후 만료돼요. 서둘러 드세요.';
      _showCard(
        title: food.name,
        subtitle: subtitle,
        color: color,
        index: i,
        total: foods.length,
      );
    }
  }

  void _showCard({
    required String title,
    required String subtitle,
    required Color color,
    required int index,
    required int total,
  }) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _NotificationCard(
        title: title,
        subtitle: subtitle,
        color: color,
        index: index,
        total: total,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }

  /// NavigatorKey를 외부에서 주입받아 Overlay 접근에 사용.
  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }
}

class ExpiryInfo {
  const ExpiryInfo({required this.name, required this.daysLeft});
  final String name;
  final int daysLeft;
}

Future<void> showExpiryInAppNotifications(
  List<dynamic> foods, {
  int daysThreshold = 0,
}) async {
  final infos = foods
      .where((f) => (f.daysLeft as int) <= daysThreshold)
      .map((f) => ExpiryInfo(
            name: f.name as String,
            daysLeft: f.daysLeft as int,
          ))
      .toList()
    ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

  await InAppNotificationService.instance.showExpiryNotifications(infos);
}

/// 슬라이드 인/아웃 애니메이션이 적용된 알림 카드 위젯
class _NotificationCard extends StatefulWidget {
  const _NotificationCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.index,
    required this.total,
    required this.onDismiss,
  });

  final String title;
  final String subtitle;
  final Color color;
  final int index;
  final int total;
  final VoidCallback onDismiss;

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // 4초 후 자동으로 슬라이드 아웃
    Future.delayed(const Duration(seconds: 4), _dismiss);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final counter =
        widget.total > 1 ? '  ${widget.index + 1}/${widget.total}' : '';
    final topPadding = MediaQuery.of(context).padding.top + 12;

    return Positioned(
      top: topPadding + (widget.index * 8),
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.kitchen_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.title}$counter',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.close, color: Colors.white60, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}