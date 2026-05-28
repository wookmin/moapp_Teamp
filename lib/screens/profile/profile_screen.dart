import 'package:flutter/material.dart';

import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const int _freshnessScore = 84;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      bottomNavigationBar: const AppBottomNavigationBar(
        currentRoute: '/profile',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        children: const [
          _ProfileHeaderCard(),
          SizedBox(height: 16),
          _FreshnessScoreCard(score: _freshnessScore),
          SizedBox(height: 30),
          _SectionLabel('계정 관리'),
          SizedBox(height: 12),
          _ProfileMenuTile(icon: Icons.kitchen_outlined, title: '냉장고 설정'),
          _ProfileMenuTile(
            icon: Icons.notifications_active_outlined,
            title: '알림 설정',
          ),
          _ProfileMenuTile(icon: Icons.bookmark_border_rounded, title: '저장된 팁'),
          _ProfileMenuTile(icon: Icons.settings_outlined, title: '앱 설정'),
          _ProfileMenuTile(
            icon: Icons.logout_rounded,
            title: '로그아웃',
            isDestructive: true,
          ),
          SizedBox(height: 22),
          _CommunityCard(),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 30),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const _ProfileAvatar(),
          const SizedBox(height: 20),
          Text(
            'Elena Greenwell',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '지속 가능한 요리 애호가',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProfileChip(label: '프로 멤버', color: Color(0xFF9BF3BA)),
              _ProfileChip(label: '에코 워리어', color: Color(0xFFCDE9F5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF7CEBAA), width: 4),
              color: const Color(0xFFEFF8F2),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 58,
              color: colorScheme.primary,
            ),
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 3),
              ),
              child: Icon(
                Icons.verified_rounded,
                size: 15,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF0E6E49),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FreshnessScoreCard extends StatelessWidget {
  const _FreshnessScoreCard({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 30),
      decoration: BoxDecoration(
        color: const Color(0xFF37B879),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text(
            '$score%',
            style: theme.textTheme.displaySmall?.copyWith(
              color: const Color(0xFF064936),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '신선도 점수',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF0E6E49).withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.onPrimary.withValues(alpha: 0.82),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = isDestructive
        ? const Color(0xFFD9502B)
        : colorScheme.primary;
    final background = isDestructive
        ? const Color(0xFFFFF2EB)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.42);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: () {
            if (isDestructive) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          },
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accent, size: 24),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDestructive
                          ? const Color(0xFF743A2B)
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDestructive
                      ? const Color(0xFFE2A58F)
                      : colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE4DF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            bottom: -36,
            child: Icon(
              Icons.spa_outlined,
              size: 120,
              color: colorScheme.primary.withValues(alpha: 0.23),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '커뮤니티와 함께 성장하기',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '5,000명 이상의 이웃과 함께 팁과 남은 농산물을 나눠보세요.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/community', (route) => false),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(136, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('그룹 둘러보기'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
