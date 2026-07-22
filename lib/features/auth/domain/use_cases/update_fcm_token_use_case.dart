import '../repositories/auth_repository.dart';

class UpdateFcmTokenUseCase {
  final AuthRepository repository;

  UpdateFcmTokenUseCase(this.repository);

  Future<void> call(String fcmToken) async {
    await repository.updateFcmToken(fcmToken);
  }
}
