import 'package:flutter/material.dart';

import '../../models/profile_data.dart';
import '../../repositories/app_repositories.dart';
import '../../services/notification_center_service.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/shimmer_card.dart';
import '../../widgets/app_shell.dart';
import '../community/saved_tips_screen.dart';
import '../notifications/notification_center_screen.dart';
import 'nickname_setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.embedded = false, this.isActive = true});

  final bool embedded;
  final bool isActive;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<ProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      setState(_refreshProfile);
    }
  }

  void _refreshProfile() {
    _profileFuture = AppRepositories.profile.fetchProfile();
  }

  Future<void> _onNotificationTap() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationCenterScreen()),
    );
  }

  Future<void> _openNicknameSettings() async {
    final status = await AppRepositories.profile.fetchNicknameStatus();
    if (!mounted) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NicknameSetupScreen(status: status)),
    );
    if (changed == true && mounted) {
      setState(_refreshProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      bottomNavigationBar: widget.embedded
          ? null
          : const AppBottomNavigationBar(currentRoute: '/profile'),
      body: FutureBuilder<ProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _ProfileLoadingView();
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
                _ProfileHeaderCard(
                  profile: profile,
                  onTap: _openNicknameSettings,
                ),
                const SizedBox(height: 16),
                _FreshnessScoreCard(score: profile.freshnessScore),
                const SizedBox(height: 30),
                _SectionLabel('계정 관리'),
                const SizedBox(height: 12),
                ...profile.menuItems.map(
                  (menu) => _ProfileMenuTile(
                    menu: menu,
                    onNotificationTap: _onNotificationTap,
                  ),
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
  const _ProfileHeaderCard({required this.profile, required this.onTap});
  final ProfileData profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  _initialFor(profile.name),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      profile.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (profile.badges.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: profile.badges
                            .take(2)
                            .map((label) => _ProfileChip(label: label))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initialFor(String name) {
    final clean = name.trim();
    return clean.isEmpty ? '?' : clean.characters.first.toUpperCase();
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
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '냉장고 신선도',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (score / 100).clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Text(
            '$score%',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w900,
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
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({required this.menu, this.onNotificationTap});

  final ProfileMenuItem menu;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = menu.isDestructive
        ? const Color(0xFFF04452)
        : colorScheme.primary;

    final leadingIcon = menu.actionKey == 'notifications'
        ? AnimatedBuilder(
            animation: NotificationCenterService.instance,
            builder: (context, child) => Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(_iconFor(menu.actionKey), color: accent),
                if (NotificationCenterService.instance.hasUnread)
                  const Positioned(
                    top: -2,
                    right: -2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFFF04452),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(dimension: 9),
                    ),
                  ),
              ],
            ),
          )
        : Icon(_iconFor(menu.actionKey), color: accent);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        minTileHeight: 58,
        leading: leadingIcon,
        title: Text(menu.title),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          if (menu.actionKey == 'notifications') {
            onNotificationTap?.call();
            return;
          }
          if (!context.mounted) return;
          _handleTap(context);
        },
      ),
    );
  }

  void _handleTap(BuildContext context) {
    switch (menu.actionKey) {
      case 'signOut':
        AppRepositories.auth.signOut().then((_) {
          if (context.mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        });
      case 'expiry':
        Navigator.of(context).pushNamed('/expiry-management');
      case 'shopping':
        AppShell.selectTab(context, 3);
      case 'saved_tips':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SavedTipsScreen()),
        );
      default:
        break;
    }
  }

  IconData _iconFor(String actionKey) {
    return switch (actionKey) {
      'fridge' => Icons.kitchen_outlined,
      'expiry' => Icons.kitchen_outlined,
      'shopping' => Icons.shopping_bag_outlined,
      'notifications' => Icons.notifications_outlined,
      'saved_tips' => Icons.bookmark_border_rounded,
      'settings' => Icons.settings_outlined,
      'signOut' => Icons.logout_rounded,
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
        borderRadius: BorderRadius.circular(16),
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
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
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
            onPressed: () => AppShell.selectTab(context, 2),
            child: const Text('그룹 둘러보기'),
          ),
        ],
      ),
    );
  }
}

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      children: const [
        ShimmerCard(height: 210, borderRadius: 28),
        SizedBox(height: 16),
        ShimmerCard(height: 120, borderRadius: 28),
        SizedBox(height: 30),
        ShimmerCard(height: 18, borderRadius: 9),
        SizedBox(height: 12),
        ShimmerCard(height: 64, borderRadius: 16),
        SizedBox(height: 12),
        ShimmerCard(height: 64, borderRadius: 16),
        SizedBox(height: 12),
        ShimmerCard(height: 64, borderRadius: 16),
      ],
    );
  }
}
