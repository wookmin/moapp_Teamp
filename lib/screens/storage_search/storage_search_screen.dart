import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/food_item.dart';
import '../../models/shared_fridge.dart';
import '../../models/storage_type.dart';
import '../../repositories/app_repositories.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/food_icon.dart';
import 'shared_fridge_invite_screen.dart';

class StorageSearchScreen extends StatefulWidget {
  const StorageSearchScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<StorageSearchScreen> createState() => _StorageSearchScreenState();
}

class _StorageSearchScreenState extends State<StorageSearchScreen> {
  final Stream<List<FoodItem>> _foodsStream =
      AppRepositories.expiry.watchExpiryItems();
  late Future<List<SharedFridge>> _sharedFridgesFuture;
  Future<List<FoodItem>>? _sharedFoodsFuture;
  SharedFridge? _selectedSharedFridge;
  int _selectedFridge = 0;

  @override
  void initState() {
    super.initState();
    _sharedFridgesFuture = AppRepositories.sharedFridges.fetchMySharedFridges();
  }

  Future<void> _openAddFood() async {
    await Navigator.of(context).pushNamed('/add-food');
  }

  void _refreshSharedFridges() {
    setState(() {
      _sharedFridgesFuture = AppRepositories.sharedFridges
          .fetchMySharedFridges();
    });
  }

  void _openSharedFridge(SharedFridge fridge) {
    setState(() {
      _selectedSharedFridge = fridge;
      _sharedFoodsFuture = AppRepositories.sharedFridges.fetchFoodItems(
        fridge.ownerUid,
      );
    });
  }

  void _closeSharedFridge() {
    setState(() {
      _selectedSharedFridge = null;
      _sharedFoodsFuture = null;
    });
  }

  void _refreshSharedFoods() {
    final fridge = _selectedSharedFridge;
    if (fridge == null) return;
    setState(() {
      _sharedFoodsFuture = AppRepositories.sharedFridges.fetchFoodItems(
        fridge.ownerUid,
      );
    });
  }

  Future<void> _shareMyFridge() async {
    final role = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '초대 권한 선택',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('함께 관리'),
                  subtitle: const Text('재료를 보고 추가할 수 있어요.'),
                  onTap: () => Navigator.of(context).pop('editor'),
                ),
                ListTile(
                  leading: const Icon(Icons.visibility_outlined),
                  title: const Text('보기만 가능'),
                  subtitle: const Text('재료와 소비기한만 확인할 수 있어요.'),
                  onTap: () => Navigator.of(context).pop('viewer'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (role == null || !mounted) return;

    try {
      final invite = await AppRepositories.sharedFridges.createInvite(
        role: role,
      );
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          subject: '${invite.fridgeName} 초대',
          text:
              '${invite.fridgeName}를 함께 볼 수 있도록 초대했어요.\n'
              '장보고 앱의 친구 냉장고에서 아래 초대 코드를 입력해주세요.\n\n'
              '초대 코드: ${invite.code}\n'
              '유효 기간: 7일',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      _showMessage(
        message.contains('permission-denied')
            ? '초대 코드를 만들 권한이 없어요. 잠시 후 다시 시도해주세요.'
            : '초대 코드를 만들지 못했어요: $message',
      );
    }
  }

  Future<void> _pasteInviteLink() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _InviteLinkDialog(),
    );
    if (code == null || !mounted) return;

    try {
      final invite = await AppRepositories.sharedFridges.fetchInviteByCode(
        code,
      );
      if (!mounted) return;
      await Navigator.of(context).pushNamed(
        '/shared-fridge-invite',
        arguments: SharedFridgeInviteArguments(
          ownerUid: invite.ownerUid,
          code: invite.code,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        error
            .toString()
            .replaceFirst('Bad state: ', '')
            .replaceFirst('StateError: ', ''),
      );
    }
    if (mounted) _refreshSharedFridges();
  }

  Future<void> _addSharedFood() async {
    final fridge = _selectedSharedFridge;
    if (fridge == null || !fridge.canEdit) return;

    final nameController = TextEditingController();
    DateTime expiryDate = DateTime.now().add(const Duration(days: 7));
    final result = await showDialog<_SharedFoodDraft>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('공유 재료 추가'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: '재료명'),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: const Text('소비기한'),
                    subtitle: Text(_formatDate(expiryDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 30),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                        initialDate: expiryDate,
                      );
                      if (picked != null) {
                        setDialogState(() => expiryDate = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      Navigator.of(context).pop(
                        _SharedFoodDraft(name: name, expiryDate: expiryDate),
                      );
                    }
                  },
                  child: const Text('추가'),
                ),
              ],
            );
          },
        );
      },
    );
    nameController.dispose();
    if (result == null || !mounted) return;

    try {
      await AppRepositories.sharedFridges.addFoodItem(
        ownerUid: fridge.ownerUid,
        name: result.name,
        expiryDate: result.expiryDate,
        storageType: StorageType.unknown,
      );
      if (mounted) _refreshSharedFoods();
    } catch (error) {
      if (!mounted) return;
      _showMessage('공유 재료를 추가하지 못했어요: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      bottomNavigationBar: widget.embedded
          ? null
          : const AppBottomNavigationBar(currentRoute: '/storage-search'),
      floatingActionButton: _selectedFridge == 0
          ? FloatingActionButton.extended(
              onPressed: _openAddFood,
              heroTag: 'storage-add-food',
              icon: const Icon(Icons.add_rounded),
              label: const Text('추가하기'),
            )
          : _selectedSharedFridge?.canEdit == true
          ? FloatingActionButton.extended(
              onPressed: _addSharedFood,
              heroTag: 'storage-add-shared-food',
              icon: const Icon(Icons.add_rounded),
              label: const Text('공유 재료 추가'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _FridgeHeader(onAddPressed: _openAddFood),
          const SizedBox(height: 18),
          SegmentedButton<int>(
            selected: {_selectedFridge},
            onSelectionChanged: (selection) {
              setState(() => _selectedFridge = selection.first);
            },
            segments: const [
              ButtonSegment<int>(
                value: 0,
                icon: Icon(Icons.kitchen_outlined),
                label: Text('내 냉장고'),
              ),
              ButtonSegment<int>(
                value: 1,
                icon: Icon(Icons.people_alt_outlined),
                label: Text('친구 냉장고'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_selectedFridge == 0)
            Column(
              children: [
                _ShareMyFridgeCard(onShare: _shareMyFridge),
                const SizedBox(height: 18),
                StreamBuilder<List<FoodItem>>(
                  stream: _foodsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return EmptyStateView(
                        icon: Icons.cloud_off_rounded,
                        title: '냉장고를 불러오지 못했어요',
                        message: snapshot.error.toString().replaceFirst(
                          'Exception: ',
                          '',
                        ),
                      );
                    }

                    final foods = snapshot.data ?? const <FoodItem>[];
                    return _MyFridge(foods: foods, onAddPressed: _openAddFood);
                  },
                ),
              ],
            )
          else
            _SharedFridgeView(
              fridgesFuture: _sharedFridgesFuture,
              selectedFridge: _selectedSharedFridge,
              foodsFuture: _sharedFoodsFuture,
              onRefresh: _refreshSharedFridges,
              onPasteInvite: _pasteInviteLink,
              onOpen: _openSharedFridge,
              onClose: _closeSharedFridge,
              onAddFood: _addSharedFood,
            ),
        ],
      ),
    );
  }
}

class _InviteLinkDialog extends StatefulWidget {
  const _InviteLinkDialog();

  @override
  State<_InviteLinkDialog> createState() => _InviteLinkDialogState();
}

class _InviteLinkDialogState extends State<_InviteLinkDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('초대 코드 입력'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        maxLength: 8,
        decoration: const InputDecoration(
          hintText: '예: A7K9M2QX',
          helperText: '친구에게 받은 8자리 코드를 입력하세요.',
          counterText: '',
        ),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _normalizedCode.length == 8
              ? () => Navigator.of(context).pop(_normalizedCode)
              : null,
          child: const Text('확인'),
        ),
      ],
    );
  }

  String get _normalizedCode => _controller.text
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

class _FridgeHeader extends StatelessWidget {
  const _FridgeHeader({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '냉장고',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '보관 중인 재료와 남은 소비기한을 한눈에 확인하세요.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filled(
          onPressed: onAddPressed,
          icon: const Icon(Icons.add_rounded),
          tooltip: '식재료 추가',
        ),
      ],
    );
  }
}

class _ShareMyFridgeCard extends StatelessWidget {
  const _ShareMyFridgeCard({required this.onShare});

  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colors.surface,
            child: Icon(Icons.people_alt_outlined, color: colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '내 냉장고를 친구와 공유',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '지금 보이는 재료를 그대로 함께 볼 수 있어요.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: onShare,
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: '초대 링크 공유',
          ),
        ],
      ),
    );
  }
}

class _MyFridge extends StatelessWidget {
  const _MyFridge({required this.foods, required this.onAddPressed});

  final List<FoodItem> foods;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final sortedFoods = [...foods]
      ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

    return Column(
      children: [
        if (foods.isNotEmpty) ...[
          _FridgeSummary(foods: foods),
          const SizedBox(height: 18),
        ],
        _FridgeCabinet(foods: sortedFoods, onAddPressed: onAddPressed),
        if (foods.isEmpty) ...[
          const SizedBox(height: 18),
          EmptyStateView(
            icon: Icons.kitchen_outlined,
            title: '아직 냉장고가 비어 있어요',
            message: '재료를 추가하면 냉장고 안에 하나씩 채워집니다.',
            action: FilledButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_rounded),
              label: const Text('식재료 추가'),
            ),
          ),
        ] else ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '재료를 누르면 소비기한을 자세히 볼 수 있어요.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FridgeSummary extends StatelessWidget {
  const _FridgeSummary({required this.foods});

  final List<FoodItem> foods;

  @override
  Widget build(BuildContext context) {
    final urgent = foods.where((food) => food.isUrgent).length;
    final expired = foods.where((food) => food.daysLeft < 0).length;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _SummaryValue(label: '전체', value: foods.length),
          const SizedBox(width: 22),
          _SummaryValue(label: '임박', value: urgent),
          const SizedBox(width: 22),
          _SummaryValue(label: '만료', value: expired),
          const Spacer(),
          Icon(Icons.view_week_rounded, color: colorScheme.onPrimaryContainer),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onPrimaryContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: theme.textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FridgeCabinet extends StatelessWidget {
  const _FridgeCabinet({
    required this.foods,
    required this.onAddPressed,
    this.canAdd = true,
  });

  final List<FoodItem> foods;
  final VoidCallback onAddPressed;
  final bool canAdd;

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: _EmptyFridge(onAddPressed: canAdd ? onAddPressed : null),
        ),
      );
    }

    final expired = foods.where((food) => food.daysLeft < 0).toList();
    final urgent = foods
        .where((food) => food.daysLeft >= 0 && food.daysLeft <= 2)
        .toList();
    final fresh = foods.where((food) => food.daysLeft > 2).toList();

    return Column(
      children: [
        if (expired.isNotEmpty)
          _FoodStatusGroup(
            title: '기한 만료',
            description: '상태를 확인하고 바로 정리하세요',
            foods: expired,
            color: const Color(0xFFC64132),
          ),
        if (urgent.isNotEmpty)
          _FoodStatusGroup(
            title: '곧 먹어야 해요',
            description: '48시간 안에 사용할 재료예요',
            foods: urgent,
            color: const Color(0xFFAD7200),
          ),
        if (fresh.isNotEmpty)
          _FoodStatusGroup(
            title: '여유 있어요',
            description: '남은 기간이 짧은 순서로 보여드려요',
            foods: fresh,
            color: Theme.of(context).colorScheme.primary,
          ),
      ],
    );
  }
}

class _FoodStatusGroup extends StatelessWidget {
  const _FoodStatusGroup({
    required this.title,
    required this.description,
    required this.foods,
    required this.color,
  });

  final String title;
  final String description;
  final List<FoodItem> foods;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleMedium),
              const Spacer(),
              Text(
                '${foods.length}개',
                style: theme.textTheme.labelMedium?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < foods.length; i++) ...[
                  _FoodToken(food: foods[i]),
                  if (i != foods.length - 1)
                    const Divider(indent: 68, endIndent: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodToken extends StatelessWidget {
  const _FoodToken({required this.food});

  final FoodItem food;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(food);

    return InkWell(
      onTap: () => _showFoodDetail(context, food),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                foodIconFor(food.name, category: food.category),
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${food.storageType.label} · ${food.expiryLabel}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              food.statusLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

class _EmptyFridge extends StatelessWidget {
  const _EmptyFridge({required this.onAddPressed});

  final VoidCallback? onAddPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.kitchen_outlined, size: 54, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            '빈 냉장고',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '재료를 추가해 냉장고를 채워보세요.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (onAddPressed != null)
            FilledButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_rounded),
              label: const Text('추가하기'),
            ),
        ],
      ),
    );
  }
}

class _SharedFridgeView extends StatelessWidget {
  const _SharedFridgeView({
    required this.fridgesFuture,
    required this.selectedFridge,
    required this.foodsFuture,
    required this.onRefresh,
    required this.onPasteInvite,
    required this.onOpen,
    required this.onClose,
    required this.onAddFood,
  });

  final Future<List<SharedFridge>> fridgesFuture;
  final SharedFridge? selectedFridge;
  final Future<List<FoodItem>>? foodsFuture;
  final VoidCallback onRefresh;
  final VoidCallback onPasteInvite;
  final ValueChanged<SharedFridge> onOpen;
  final VoidCallback onClose;
  final VoidCallback onAddFood;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fridge = selectedFridge;

    if (fridge != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: '친구 냉장고 목록',
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fridge.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _roleLabel(fridge.role),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<FoodItem>>(
            future: foodsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return EmptyStateView(
                  icon: Icons.cloud_off_rounded,
                  title: '친구 냉장고를 불러오지 못했어요',
                  message: snapshot.error.toString(),
                );
              }

              final foods = snapshot.data ?? const <FoodItem>[];
              return Column(
                children: [
                  _FridgeCabinet(
                    foods: foods,
                    onAddPressed: fridge.canEdit ? onAddFood : () {},
                    canAdd: fridge.canEdit,
                  ),
                  if (foods.isEmpty) ...[
                    const SizedBox(height: 18),
                    EmptyStateView(
                      icon: Icons.inventory_2_outlined,
                      title: '친구 냉장고가 비어 있어요',
                      message: fridge.canEdit
                          ? '첫 재료를 추가해 함께 관리해보세요.'
                          : '관리자가 재료를 추가하면 여기에서 확인할 수 있어요.',
                      action: fridge.canEdit
                          ? FilledButton.icon(
                              onPressed: onAddFood,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('공유 재료 추가'),
                            )
                          : null,
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<List<SharedFridge>>(
          future: fridgesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return EmptyStateView(
                icon: Icons.cloud_off_rounded,
                title: '친구 냉장고를 불러오지 못했어요',
                message: snapshot.error.toString(),
                action: TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('다시 시도'),
                ),
              );
            }

            final fridges = snapshot.data ?? const <SharedFridge>[];
            if (fridges.isEmpty) {
              return EmptyStateView(
                icon: Icons.group_add_outlined,
                title: '아직 연결된 친구 냉장고가 없어요',
                message: '친구가 보낸 초대 코드를 입력하면 실제 냉장고를 여기에서 볼 수 있어요.',
                action: OutlinedButton.icon(
                  onPressed: onPasteInvite,
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('초대 코드 입력'),
                ),
              );
            }

            return Column(
              children: fridges
                  .map(
                    (fridge) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      child: ListTile(
                        onTap: () => onOpen(fridge),
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.kitchen_rounded,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          fridge.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(_roleLabel(fridge.role)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          '친구가 재료를 수정하면 친구의 원래 냉장고에도 바로 반영됩니다.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SharedFoodDraft {
  const _SharedFoodDraft({required this.name, required this.expiryDate});

  final String name;
  final DateTime expiryDate;
}

String _roleLabel(String role) {
  return switch (role) {
    'editor' => '함께 관리',
    _ => '보기만 가능',
  };
}

void _showFoodDetail(BuildContext context, FoodItem food) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final statusColor = _statusColor(food);

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      foodIconFor(food.name, category: food.category),
                      color: statusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          food.storageType.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _DetailRow(label: '소비기한', value: _formatDate(food.expiryDate)),
              _DetailRow(
                label: '남은 기간',
                value: food.expiryLabel,
                valueColor: statusColor,
              ),
              _DetailRow(
                label: '상태',
                value: food.statusLabel,
                valueColor: statusColor,
              ),
              if (food.category?.isNotEmpty == true)
                _DetailRow(label: '분류', value: food.category!),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(FoodItem food) {
  if (food.daysLeft < 0) return const Color(0xFFB3261E);
  if (food.daysLeft <= 2) return const Color(0xFFD95F2B);
  if (food.daysLeft <= 7) return const Color(0xFF9A7200);
  return const Color(0xFF19734B);
}

String _formatDate(DateTime date) {
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.'
      '${date.day.toString().padLeft(2, '0')}';
}
