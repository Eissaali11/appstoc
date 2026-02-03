import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> login(String username, String password);
  Future<void> logout();
  Future<UserEntity> getCurrentUser();
}
