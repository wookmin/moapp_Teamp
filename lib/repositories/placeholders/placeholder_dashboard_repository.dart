import '../../models/freshness_summary.dart';
import '../dashboard_repository.dart';

class PlaceholderDashboardRepository implements DashboardRepository {
  const PlaceholderDashboardRepository();

  @override
  Future<FreshnessSummary> fetchFreshnessSummary() async {
    return const FreshnessSummary(score: 0, urgentCount: 0);
  }
}
