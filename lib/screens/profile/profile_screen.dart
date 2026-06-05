import 'package:flutter/material.dart';

import '../../models/profile_data.dart';
import '../../repositories/app_repositories.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/empty_state_view.dart';
import '../community/saved_tips_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      bottomNavigationBar: const AppBottomNavigationBar(
        currentRoute: '/profile',
      ),
      body: FutureBuilder<ProfileData>(
        future: AppRepositories.profile.fetchProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile =
              snapshot.data ??
              const ProfileData(name: '', subtitle: '', freshnessScore: 0);

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            children: [
              if (!profile.hasConnectedData)
                const EmptyStateView(
                  icon: Icons.person_outline,
                  title: '프로필을 불러오는 중이에요',
                  message: '잠시 후 다시 시도해주세요.',
                )
              else ...[
                _ProfileHeaderCard(profile: profile),
                const SizedBox(height: 16),
                _FreshnessScoreCard(score: profile.freshnessScore),
                const SizedBox(height: 30),
                _SectionLabel('계정 관리'),
                const SizedBox(height: 12),
                ...profile.menuItems.map(
                  (menu) => _ProfileMenuTile(menu: menu),
                ),
              ],
              const SizedBox(height: 22),
              const _RulebookCard(),
              const SizedBox(height: 14),
              const _CommunityCard(),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.profile});

  final ProfileData profile;

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
      ),
      child: Column(
        children: [
          Icon(Icons.person_rounded, size: 72, color: colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (profile.badges.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: profile.badges
                  .map((label) => _ProfileChip(label: label))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF9BF3BA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}

class _FreshnessScoreCard extends StatelessWidget {
  const _FreshnessScoreCard({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          const Text('신선도 점수'),
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
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({required this.menu});

  final ProfileMenuItem menu;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = menu.isDestructive
        ? const Color(0xFFD9502B)
        : colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: ListTile(
        leading: Icon(_iconFor(menu.actionKey), color: accent),
        title: Text(menu.title),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () async {
          if (menu.actionKey == 'signOut') {
            await AppRepositories.auth.signOut();
            if (context.mounted) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          } else if (menu.actionKey == 'expiry') {
            Navigator.of(context).pushNamed('/expiry-management');
          } else if (menu.actionKey == 'shopping') {
            Navigator.of(context).pushNamed('/shopping-recommendations');
          } else if (menu.actionKey == 'saved_tips') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SavedTipsScreen()),
            );
          }
        },
      ),
    );
  }

  IconData _iconFor(String actionKey) {
    return switch (actionKey) {
      'fridge' => Icons.kitchen_outlined,
      'notifications' => Icons.notifications_active_outlined,
      'saved_tips' => Icons.bookmark_border_rounded,
      'settings' => Icons.settings_outlined,
      'logout' => Icons.logout_rounded,
      _ => Icons.chevron_right_rounded,
    };
  }
}

class _RulebookCard extends StatelessWidget {
  const _RulebookCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '보관 룰북',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '식재료별 보관법과 소비 기준을 검색해요.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                Navigator.of(context).pushNamed('/storage-rulebook'),
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: '보관 룰북 열기',
          ),
        ],
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
      child: Column(
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
            '커뮤니티 데이터가 연결되면 내가 저장한 팁과 참여 그룹을 함께 보여줄 수 있습니다.',
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
            child: const Text('그룹 둘러보기'),
          ),
        ],
      ),
    );
  }
}
