import '../../models/nickname_status.dart';
import '../../models/profile_data.dart';
import '../profile_repository.dart';

class PlaceholderProfileRepository implements ProfileRepository {
  const PlaceholderProfileRepository();

  @override
  Future<ProfileData> fetchProfile() async {
    return const ProfileData(name: '', subtitle: '', freshnessScore: 0);
  }

  @override
  Future<NicknameStatus> fetchNicknameStatus() async {
    return const NicknameStatus();
  }

  @override
  Future<void> updateNickname(String nickname) async {}
}
