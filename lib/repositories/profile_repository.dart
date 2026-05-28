import '../models/profile_data.dart';

abstract class ProfileRepository {
  Future<ProfileData> fetchProfile();
}
