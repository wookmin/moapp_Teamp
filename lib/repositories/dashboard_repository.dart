import '../models/freshness_summary.dart';

abstract class DashboardRepository {
  Future<FreshnessSummary> fetchFreshnessSummary();
}
