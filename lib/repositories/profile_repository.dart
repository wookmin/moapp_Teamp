import '../models/nickname_status.dart';
import '../models/profile_data.dart';

abstract class ProfileRepository {
  Future<ProfileData> fetchProfile();
  Future<NicknameStatus> fetchNicknameStatus();
  Future<void> updateNickname(String nickname);
}
