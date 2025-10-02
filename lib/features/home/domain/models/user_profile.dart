/// Feature: Home
/// Model: UserProfile (used by Home and EditProfileScreen)
class UserProfile {
  String name;
  String username;
  String profileImageUrl;
  String location;

  UserProfile({
    required this.name,
    required this.username,
    required this.profileImageUrl,
    required this.location,
  });
}

