import '../../models/profile_data.dart';
import '../profile_repository.dart';

class PlaceholderProfileRepository implements ProfileRepository {
  const PlaceholderProfileRepository();

  @override
  Future<ProfileData> fetchProfile() async {
    return const ProfileData(name: '', subtitle: '', freshnessScore: 0);
  }
}
