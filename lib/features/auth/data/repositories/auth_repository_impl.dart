import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/storage/secure_storage.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService storage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storage,
  });

  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    final result = await remoteDataSource.login(username, password);
    final token = result['token'] as String;
    final userJson = result['user'] as Map<String, dynamic>;
    
    await storage.saveToken(token);
    await storage.saveUserId(userJson['id'] as String);
    
    return result;
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
    await storage.clearAll();
  }

  @override
  Future<UserEntity> getCurrentUser() async {
    final userModel = await remoteDataSource.getCurrentUser();
    return userModel;
  }
}
