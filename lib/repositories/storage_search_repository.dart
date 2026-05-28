import '../models/storage_tip.dart';

abstract class StorageSearchRepository {
  Future<List<StorageTip>> searchStorageTips(String query);
}
