import '../models/freshness_summary.dart';
import 'dashboard_repository.dart';
import 'firebase_expiry_repository.dart';

class FirebaseDashboardRepository implements DashboardRepository {
  FirebaseDashboardRepository({FirebaseExpiryRepository? expiryRepository})
      : _expiryRepository = expiryRepository ?? FirebaseExpiryRepository();

  final FirebaseExpiryRepository _expiryRepository;

  @override
  Future<FreshnessSummary> fetchFreshnessSummary() async {
    final items = await _expiryRepository.fetchExpiryItems();

    if (items.isEmpty) {
      return const FreshnessSummary(score: 0, urgentCount: 0);
    }

    final urgentFoods = items.where((f) => f.isUrgent).toList();
    final freshCount = items.where((f) => f.daysLeft > 7).length;
    final score = ((freshCount / items.length) * 100).round();

    return FreshnessSummary(
      score: score,
      urgentCount: urgentFoods.length,
      urgentFoods: urgentFoods,
    );
  }
}
