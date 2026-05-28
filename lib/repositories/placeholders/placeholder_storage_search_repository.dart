import '../../models/storage_tip.dart';
import '../storage_search_repository.dart';

class PlaceholderStorageSearchRepository implements StorageSearchRepository {
  const PlaceholderStorageSearchRepository();

  @override
  Future<List<StorageTip>> searchStorageTips(String query) async {
    return const [];
  }
}
