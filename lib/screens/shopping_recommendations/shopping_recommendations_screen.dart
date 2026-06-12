import 'package:flutter/material.dart';

import '../../models/food_item.dart';
import '../../models/price_trend.dart';
import '../../models/shopping_cart_item.dart';
import '../../models/shopping_recommendation.dart';
import '../../repositories/app_repositories.dart';
import '../../services/kamis_price_service.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/empty_state_view.dart';

class ShoppingRecommendationsScreen extends StatefulWidget {
  const ShoppingRecommendationsScreen({super.key});

  @override
  State<ShoppingRecommendationsScreen> createState() =>
      _ShoppingRecommendationsScreenState();
}

class _ShoppingRecommendationsScreenState
    extends State<ShoppingRecommendationsScreen>
    with TickerProviderStateMixin {
  late Future<_ShoppingScreenData> _future;
  late final AnimationController _cartHighlightController;
  final TextEditingController _searchController = TextEditingController();
  final KamisPriceService _kamisPriceService = KamisPriceService();
  final GlobalKey _cartFabKey = GlobalKey();
  Future<List<PriceTrend>>? _searchFuture;
  String _submittedSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _cartHighlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _refresh();
  }

  @override
  void dispose() {
    _cartHighlightController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    _future = _loadScreenData();
  }

  /// 현재 냉장고 식재료 이름들을 가져와 Kamis 추천에 필터로 전달한다.
  ///
  /// 추후 파트너가 ExpiryRepository에 history(과거 등록 이력) 기능을 추가하면,
  /// 이 부분에 history names를 합쳐 넘기면 "한 번이라도 등록한 적 있는 품목"까지
  /// 자동으로 필터에 포함된다.
  Future<List<ShoppingCategory>> _loadRecommendations() async {
    Set<String> foodNameHistory = const {};
    List<FoodItem> currentFoods = const [];
    try {
      final foods = await AppRepositories.expiry.fetchExpiryItems();
      foodNameHistory = foods.map((FoodItem f) => f.name.trim()).toSet();
      currentFoods = foods;
    } catch (_) {
      foodNameHistory = const {};
      currentFoods = const [];
    }

    return AppRepositories.shoppingRecommendations.fetchRecommendations(
      foodNameHistory: foodNameHistory,
      currentFoods: currentFoods,
    );
  }

  Future<_ShoppingScreenData> _loadScreenData() async {
    final categories = await _loadRecommendations();
    try {
      final cartItems = await AppRepositories.shoppingCart.fetchCartItems();
      return _ShoppingScreenData(categories: categories, cartItems: cartItems);
    } catch (error) {
      return _ShoppingScreenData(
        categories: categories,
        cartItems: const [],
        cartErrorMessage: _cartErrorMessage(error),
      );
    }
  }

  Future<void> _addRecommendation(
    ShoppingRecommendation item,
    GlobalKey buttonKey,
  ) async {
    try {
      final added = await AppRepositories.shoppingCart
          .addCartItemFromRecommendation(item);

      if (added) {
        await _playAddToCartMotion(buttonKey);
        _pulseCartSection();
      }

      if (!mounted) return;
      setState(_refresh);
      _showSnackBar(
        added ? '${item.name}을 장바구니에 담았어요' : '${item.name}은 이미 장바구니에 있어요',
      );
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('장바구니 추가에 실패했어요: $error');
    }
  }

  Future<void> _addAllRecommendations(_ShoppingScreenData data) async {
    final cartNames = data.cartNames;
    final targets = data.allRecommendations
        .where((item) => !cartNames.contains(_normalizeName(item.name)))
        .toList();

    if (targets.isEmpty) {
      _showSnackBar('이미 모든 추천 품목이 장바구니에 있어요');
      return;
    }

    try {
      final addedCount = await AppRepositories.shoppingCart
          .addManyFromRecommendations(targets);

      if (addedCount > 0) {
        _pulseCartSection();
      }

      if (!mounted) return;
      setState(_refresh);
      _showSnackBar(
        addedCount > 0
            ? '$addedCount개 품목을 장바구니에 담았어요'
            : '이미 모든 추천 품목이 장바구니에 있어요',
      );
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('장바구니 추가에 실패했어요: $error');
    }
  }

  Future<void> _toggleCartItem(ShoppingCartItem item, bool isChecked) async {
    try {
      await AppRepositories.shoppingCart.toggleChecked(item.id, isChecked);
      if (mounted) setState(_refresh);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('체크 상태 변경에 실패했어요: $error');
    }
  }

  Future<void> _deleteCartItem(ShoppingCartItem item) async {
    try {
      await AppRepositories.shoppingCart.deleteCartItem(item.id);
      if (!mounted) return;
      setState(_refresh);
      _showSnackBar('${item.name}을 장바구니에서 삭제했어요');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('삭제에 실패했어요: $error');
    }
  }

  void _submitSearch(String value) {
    final query = value.trim();
    setState(() {
      _submittedSearchQuery = query;
      _searchFuture = query.isEmpty
          ? null
          : _kamisPriceService.searchPriceTrends(query);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _submittedSearchQuery = '';
      _searchFuture = null;
    });
  }

  void _updateSearchText() {
    setState(() {});
  }

  Future<void> _playAddToCartMotion(GlobalKey sourceKey) async {
    final overlay = Overlay.maybeOf(context);
    final sourceContext = sourceKey.currentContext;
    final targetContext = _cartFabKey.currentContext;
    if (overlay == null || sourceContext == null || targetContext == null) {
      return;
    }

    final sourceBox = sourceContext.findRenderObject() as RenderBox?;
    final targetBox = targetContext.findRenderObject() as RenderBox?;
    if (sourceBox == null || targetBox == null) return;

    final sourceCenter = sourceBox.localToGlobal(
      Offset(sourceBox.size.width / 2, sourceBox.size.height / 2),
    );
    final targetCenter = targetBox.localToGlobal(
      Offset(targetBox.size.width / 2, targetBox.size.height / 2),
    );

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 430),
    );
    final curve = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: curve,
          builder: (context, child) {
            final progress = curve.value;
            final position = Offset.lerp(sourceCenter, targetCenter, progress)!;
            final scale = 1 - (progress * 0.25);
            final opacity = 1 - (progress * 0.35);

            return Positioned(
              left: position.dx - 22,
              top: position.dy - 22,
              child: IgnorePointer(
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(scale: scale, child: child),
                ),
              ),
            );
          },
          child: _FlyingCartIcon(color: Theme.of(context).colorScheme.primary),
        );
      },
    );

    overlay.insert(entry);
    try {
      await controller.forward();
    } finally {
      entry.remove();
      controller.dispose();
    }
  }

  void _pulseCartSection() {
    _cartHighlightController.forward(from: 0);
  }

  Future<void> _openCartSheet(_ShoppingScreenData data) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return _CartBottomSheet(
          items: data.cartItems,
          errorMessage: data.cartErrorMessage,
          onToggle: (item, isChecked) async {
            await _toggleCartItem(item, isChecked);
          },
          onDelete: (item) async {
            await _deleteCartItem(item);
          },
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _normalizeName(String value) => ShoppingCartItem.normalizeName(value);

  String _cartErrorMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('permission-denied')) {
      return 'Firestore 규칙에 shopping_cart_items 권한을 배포하면 장바구니를 사용할 수 있어요.';
    }
    if (message.contains('로그인이 필요합니다')) {
      return '로그인 후 장바구니를 사용할 수 있어요.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const CommonAppBar(),
      bottomNavigationBar: const AppBottomNavigationBar(
        currentRoute: '/shopping-recommendations',
      ),
      body: FutureBuilder<_ShoppingScreenData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return EmptyStateView(
              icon: Icons.shopping_cart_outlined,
              title: '장보기 데이터를 불러오지 못했어요',
              message: snapshot.error.toString().replaceFirst('Exception: ', ''),
            );
          }

          final data =
              snapshot.data ??
              const _ShoppingScreenData(categories: [], cartItems: []);

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
                children: [
                  _SmartCartBanner(
                    pendingCount: data.pendingRecommendationCount,
                    isCartAvailable: !data.hasCartError,
                    onAddAll: () => _addAllRecommendations(data),
                  ),
                  const SizedBox(height: 18),
                  _KamisPriceSearchSection(
                    controller: _searchController,
                    submittedQuery: _submittedSearchQuery,
                    searchFuture: _searchFuture,
                    cartNames: data.cartNames,
                    onSubmit: _submitSearch,
                    onClear: _clearSearch,
                    onQueryChanged: _updateSearchText,
                    onAdd: _addRecommendation,
                  ),
                  const SizedBox(height: 26),
                  Text(
                    '장보기 추천 리스트',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '냉장고 품목과 KAMIS 가격 동향을 분석해 살 만한 재료를 추천합니다.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (data.categories.isEmpty)
                    const EmptyStateView(
                      icon: Icons.shopping_cart_outlined,
                      title: '추천 장보기 목록이 없어요',
                      message: '냉장고에 식품을 추가하면\n맞춤 쇼핑 추천이 표시됩니다.',
                    )
                  else
                    for (final category in data.categories) ...[
                      _CategorySection(
                        category: category,
                        cartNames: data.cartNames,
                        onAdd: _addRecommendation,
                      ),
                      const SizedBox(height: 24),
                    ],
                ],
              ),
              Positioned(
                right: 20,
                bottom: 20,
                child: AnimatedBuilder(
                  animation: _cartHighlightController,
                  builder: (context, child) {
                    return _CartFloatingButton(
                      key: _cartFabKey,
                      itemCount: data.cartItems.length,
                      hasError: data.hasCartError,
                      highlightOpacity: _cartHighlightController.value,
                      onPressed: () => _openCartSheet(data),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShoppingScreenData {
  const _ShoppingScreenData({
    required this.categories,
    required this.cartItems,
    this.cartErrorMessage,
  });

  final List<ShoppingCategory> categories;
  final List<ShoppingCartItem> cartItems;
  final String? cartErrorMessage;

  bool get hasCartError => cartErrorMessage != null;

  Set<String> get cartNames =>
      cartItems.map((item) => item.normalizedName).toSet();

  List<ShoppingRecommendation> get allRecommendations =>
      categories.expand((category) => category.items).toList();

  int get pendingRecommendationCount {
    final names = cartNames;
    return allRecommendations
        .where(
          (item) => !names.contains(ShoppingCartItem.normalizeName(item.name)),
        )
        .length;
  }
}

/// 식료품 배경 이미지 위에 어두운 오버레이를 깔고, 흰색 텍스트와 버튼을 올린
/// 스마트 장바구니 배너.
class _SmartCartBanner extends StatelessWidget {
  const _SmartCartBanner({
    required this.pendingCount,
    required this.isCartAvailable,
    required this.onAddAll,
  });

  final int pendingCount;
  final bool isCartAvailable;
  final VoidCallback onAddAll;

  static const String _backgroundUrl =
      'https://img.freepik.com/premium-photo/shopping-basket-full-fruits-vegetables_53876-157890.jpg';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasPendingItems = pendingCount > 0 && isCartAvailable;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 168,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              _backgroundUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(color: colorScheme.primaryContainer);
              },
              errorBuilder: (context, error, stack) =>
                  Container(color: colorScheme.primaryContainer),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xCC0E2E1F), Color(0x66000000)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '스마트 장바구니',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        !isCartAvailable
                            ? '장바구니 권한 설정을 확인해야 해요'
                            : hasPendingItems
                            ? '$pendingCount개 추천 품목을 바로 담을 수 있어요'
                            : '추천 품목이 모두 장바구니에 담겼어요',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      onPressed: hasPendingItems ? onAddAll : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white.withValues(
                          alpha: 0.55,
                        ),
                        foregroundColor: colorScheme.primary,
                        disabledForegroundColor: colorScheme.primary
                            .withValues(alpha: 0.65),
                      ),
                      child: const Text('모두 리스트에 추가'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KamisPriceSearchSection extends StatelessWidget {
  const _KamisPriceSearchSection({
    required this.controller,
    required this.submittedQuery,
    required this.searchFuture,
    required this.cartNames,
    required this.onSubmit,
    required this.onClear,
    required this.onQueryChanged,
    required this.onAdd,
  });

  final TextEditingController controller;
  final String submittedQuery;
  final Future<List<PriceTrend>>? searchFuture;
  final Set<String> cartNames;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;
  final VoidCallback onQueryChanged;
  final void Function(ShoppingRecommendation item, GlobalKey buttonKey) onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchBar(
          controller: controller,
          hintText: '예: 사과, 양파, 배추',
          leading: const Icon(Icons.search_rounded),
          trailing: [
            if (controller.text.isNotEmpty)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
                tooltip: '검색어 지우기',
              ),
          ],
          onChanged: (_) => onQueryChanged(),
          onSubmitted: onSubmit,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18),
          ),
        ),
        const SizedBox(height: 14),
        _KamisSearchResults(
          submittedQuery: submittedQuery,
          searchFuture: searchFuture,
          cartNames: cartNames,
          onAdd: onAdd,
        ),
      ],
    );
  }
}

class _KamisSearchResults extends StatelessWidget {
  const _KamisSearchResults({
    required this.submittedQuery,
    required this.searchFuture,
    required this.cartNames,
    required this.onAdd,
  });

  final String submittedQuery;
  final Future<List<PriceTrend>>? searchFuture;
  final Set<String> cartNames;
  final void Function(ShoppingRecommendation item, GlobalKey buttonKey) onAdd;

  @override
  Widget build(BuildContext context) {
    final future = searchFuture;
    if (future == null) {
      return const EmptyStateView(
        icon: Icons.sell_outlined,
        title: '가격이 궁금한 재료를 검색해보세요',
        message: 'KAMIS 일일 가격 데이터에서 품목을 찾아드립니다.',
      );
    }

    return FutureBuilder<List<PriceTrend>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return EmptyStateView(
            icon: Icons.cloud_off_rounded,
            title: '가격 검색에 실패했어요',
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
          );
        }

        final trends = snapshot.data ?? const <PriceTrend>[];
        if (trends.isEmpty) {
          return EmptyStateView(
            icon: Icons.search_off_rounded,
            title: '"$submittedQuery" 가격 정보가 없어요',
            message: '다른 식재료명으로 검색해보세요.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"$submittedQuery" 검색 결과 ${trends.length}개',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...trends.map((trend) {
              final recommendation = _recommendationFromTrend(trend);
              final isInCart = cartNames.contains(
                ShoppingCartItem.normalizeName(recommendation.name),
              );
              return _KamisPriceResultCard(
                trend: trend,
                recommendation: recommendation,
                isInCart: isInCart,
                onAdd: onAdd,
              );
            }),
          ],
        );
      },
    );
  }

  ShoppingRecommendation _recommendationFromTrend(PriceTrend trend) {
    return ShoppingRecommendation(
      name: trend.itemName,
      note: trend.recommendationReason,
      tag: trend.trendLabel,
      status: trend.isPriceDrop ? StockStatus.priceDrop : StockStatus.seasonal,
      reason: 'KAMIS 가격 검색 결과',
      priceTrend: trend,
    );
  }
}

class _KamisPriceResultCard extends StatelessWidget {
  const _KamisPriceResultCard({
    required this.trend,
    required this.recommendation,
    required this.isInCart,
    required this.onAdd,
  });

  final PriceTrend trend;
  final ShoppingRecommendation recommendation;
  final bool isInCart;
  final void Function(ShoppingRecommendation item, GlobalKey buttonKey) onAdd;

  @override
  Widget build(BuildContext context) {
    final addButtonKey = GlobalKey();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trendColor = _trendColor(trend, colorScheme);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.sell_rounded, color: trendColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              trend.itemName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _TagChip(label: trend.trendLabel, color: trendColor),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _priceLabel(trend),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: addButtonKey,
                  onPressed: isInCart
                      ? null
                      : () => onAdd(recommendation, addButtonKey),
                  icon: Icon(
                    isInCart
                        ? Icons.check_circle_rounded
                        : Icons.add_shopping_cart_rounded,
                    color: colorScheme.primary,
                  ),
                  tooltip: isInCart ? '이미 담긴 품목' : '장바구니 추가',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PriceComparisonRow(trend: trend),
          ],
        ),
      ),
    );
  }

  static Color _trendColor(PriceTrend trend, ColorScheme colorScheme) {
    final label = trend.trendLabel;
    if (label.contains('하락')) return const Color(0xFF1E6FD9);
    if (label.contains('상승')) return const Color(0xFFC0392B);
    return colorScheme.primary;
  }

  static String _priceLabel(PriceTrend trend) {
    final price = trend.currentPrice;
    final unit = trend.unit;
    if (price == null) return '현재 가격 확인 필요';
    return '${_formatPrice(price)}원${unit == null ? '' : ' / $unit'}';
  }
}

class _PriceComparisonRow extends StatelessWidget {
  const _PriceComparisonRow({required this.trend});

  final PriceTrend trend;

  @override
  Widget build(BuildContext context) {
    final values = [
      _PriceComparisonValue(label: '전일', price: trend.previousDayPrice),
      _PriceComparisonValue(label: '전월', price: trend.previousMonthPrice),
      _PriceComparisonValue(label: '전년', price: trend.previousYearPrice),
    ].where((value) => value.price != null).toList();

    if (values.isEmpty) {
      return Text(
        '비교 가격 정보가 아직 없어요.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Row(
      children: values
          .map(
            (value) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatPrice(value.price!)}원',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PriceComparisonValue {
  const _PriceComparisonValue({required this.label, required this.price});

  final String label;
  final int? price;
}

class _CartFloatingButton extends StatelessWidget {
  const _CartFloatingButton({
    required this.itemCount,
    required this.hasError,
    required this.highlightOpacity,
    required this.onPressed,
    super.key,
  });

  final int itemCount;
  final bool hasError;
  final double highlightOpacity;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scale = 1 + (highlightOpacity * 0.08);

    return Transform.scale(
      scale: scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          FloatingActionButton(
            onPressed: onPressed,
            tooltip: '내 장바구니',
            backgroundColor: Color.lerp(
              colorScheme.primary,
              colorScheme.tertiary,
              highlightOpacity,
            ),
            foregroundColor: colorScheme.onPrimary,
            child: Icon(
              hasError
                  ? Icons.error_outline_rounded
                  : Icons.shopping_basket_rounded,
            ),
          ),
          if (itemCount > 0)
            Positioned(
              right: -2,
              top: -6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: Text(
                  itemCount > 99 ? '99+' : '$itemCount',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onError,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CartBottomSheet extends StatefulWidget {
  const _CartBottomSheet({
    required this.items,
    required this.errorMessage,
    required this.onToggle,
    required this.onDelete,
  });

  final List<ShoppingCartItem> items;
  final String? errorMessage;
  final Future<void> Function(ShoppingCartItem item, bool isChecked) onToggle;
  final Future<void> Function(ShoppingCartItem item) onDelete;

  @override
  State<_CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<_CartBottomSheet> {
  late List<ShoppingCartItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final checkedCount = _items.where((item) => item.isChecked).length;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shopping_basket_rounded,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '내 장바구니',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    _items.isEmpty ? '0개' : '$checkedCount/${_items.length} 완료',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (widget.errorMessage != null)
                EmptyStateView(
                  icon: Icons.lock_outline_rounded,
                  title: '장바구니 권한을 확인해야 해요',
                  message: widget.errorMessage!,
                )
              else if (_items.isEmpty)
                const EmptyStateView(
                  icon: Icons.add_shopping_cart_rounded,
                  title: '장바구니가 비었어요',
                  message: '추천 품목을 담으면 여기에 표시됩니다.',
                )
              else
                Expanded(
                  child: ListView(
                    children: _items
                        .map(
                          (item) => _CartItemTile(
                            item: item,
                            onToggle: (isChecked) =>
                                _toggleItem(item, isChecked),
                            onDelete: () => _deleteItem(item),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleItem(ShoppingCartItem item, bool isChecked) async {
    await widget.onToggle(item, isChecked);
    setState(() {
      final index = _items.indexWhere((candidate) => candidate.id == item.id);
      if (index == -1) return;
      _items[index] = ShoppingCartItem(
        id: item.id,
        name: item.name,
        note: item.note,
        tag: item.tag,
        isChecked: isChecked,
        createdAt: item.createdAt,
        source: item.source,
      );
    });
  }

  Future<void> _deleteItem(ShoppingCartItem item) async {
    await widget.onDelete(item);
    setState(() {
      _items = _items
          .where((candidate) => candidate.id != item.id)
          .toList();
    });
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  final ShoppingCartItem item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        value: item.isChecked,
        onChanged: (value) => onToggle(value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          item.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: item.note.isEmpty
            ? null
            : Text(
                item.note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        secondary: IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
          color: colorScheme.error,
          tooltip: '장바구니 삭제',
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.cartNames,
    required this.onAdd,
  });

  final ShoppingCategory category;
  final Set<String> cartNames;
  final void Function(ShoppingRecommendation item, GlobalKey buttonKey) onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                category.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              category.neededLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...category.items.map((item) {
          final isInCart = cartNames.contains(
            ShoppingCartItem.normalizeName(item.name),
          );
          return _ShoppingItemCard(
            item: item,
            isInCart: isInCart,
            onAdd: onAdd,
          );
        }),
      ],
    );
  }
}

class _ShoppingItemCard extends StatelessWidget {
  const _ShoppingItemCard({
    required this.item,
    required this.isInCart,
    required this.onAdd,
  });

  final ShoppingRecommendation item;
  final bool isInCart;
  final void Function(ShoppingRecommendation item, GlobalKey buttonKey) onAdd;

  @override
  Widget build(BuildContext context) {
    final addButtonKey = GlobalKey();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tagColor = _tagColor(item.status, colorScheme);
    final priceAdvice = _PriceAdvice.fromTrend(item.priceTrend);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ItemThumbnail(imageUrl: item.imageUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _TagChip(label: item.tag, color: tagColor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: addButtonKey,
                  onPressed: isInCart ? null : () => onAdd(item, addButtonKey),
                  icon: Icon(
                    isInCart
                        ? Icons.check_circle_rounded
                        : Icons.add_shopping_cart_rounded,
                    color: isInCart
                        ? colorScheme.primary.withValues(alpha: 0.75)
                        : colorScheme.primary,
                  ),
                  tooltip: isInCart ? '이미 담긴 품목' : '장바구니 추가',
                ),
              ],
            ),
            if (priceAdvice != null) ...[
              const SizedBox(height: 10),
              _PriceAdviceBanner(advice: priceAdvice),
            ],
          ],
        ),
      ),
    );
  }

  static Color _tagColor(StockStatus status, ColorScheme colorScheme) {
    return switch (status) {
      StockStatus.out => const Color(0xFFC0392B),
      StockStatus.low => const Color(0xFFD98A00),
      StockStatus.seasonal => colorScheme.primary,
      StockStatus.priceDrop => const Color(0xFF1E6FD9),
    };
  }
}

class _FlyingCartIcon extends StatelessWidget {
  const _FlyingCartIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_shopping_cart_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

class _ItemThumbnail extends StatelessWidget {
  const _ItemThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const size = 64.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: size,
        height: size,
        color: colorScheme.surfaceContainerHighest,
        child: (imageUrl == null || imageUrl!.isEmpty)
            ? Icon(
                Icons.eco_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 28,
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stack) => Icon(
                  Icons.eco_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 28,
                ),
              ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatPrice(int price) {
  final text = price.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i += 1) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

/// 카드 하단의 가격 추천 배너
class _PriceAdviceBanner extends StatelessWidget {
  const _PriceAdviceBanner({required this.advice});

  final _PriceAdvice advice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: advice.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: advice.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(advice.icon, size: 16, color: advice.color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              advice.message,
              style: theme.textTheme.labelMedium?.copyWith(
                color: advice.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (advice.detail != null)
            Text(
              advice.detail!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: advice.color.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

/// PriceTrend로부터 카드 하단에 띄울 추천 메시지를 만든다.
class _PriceAdvice {
  const _PriceAdvice({
    required this.message,
    required this.color,
    required this.icon,
    this.detail,
  });

  final String message;
  final Color color;
  final IconData icon;
  final String? detail;

  static _PriceAdvice? fromTrend(PriceTrend? trend) {
    if (trend == null) return null;
    final label = trend.trendLabel;

    String? detail;
    final rate = trend.changeRate;
    if (rate != null && rate.abs() > 0) {
      detail = '${rate > 0 ? '+' : ''}${rate.toStringAsFixed(1)}%';
    }

    if (label.contains('하락')) {
      return _PriceAdvice(
        message: '지금 사는 것을 추천해요!',
        color: const Color(0xFF1E6FD9),
        icon: Icons.trending_down_rounded,
        detail: detail,
      );
    }
    if (label.contains('상승')) {
      return _PriceAdvice(
        message: '지금은 살 때가 아니에요!',
        color: const Color(0xFFC0392B),
        icon: Icons.trending_up_rounded,
        detail: detail,
      );
    }
    return null;
  }
}