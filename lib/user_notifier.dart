import 'core/models/user_model.dart';
import 'core/models/user_info_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userProfileFutureProvider = FutureProvider.autoDispose<UserModel?>((ref) {
  final userInfoService = UserInfoService();
  return userInfoService.fetchProfileDataRegistration().onError((error, stackTrace) {
    return null;
  });
});