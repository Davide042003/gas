import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gas/core/models/post_model.dart';
import 'package:gas/core/models/post_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

final postServiceProvider = Provider<PostService>((ref) {
  return PostService(userId: FirebaseAuth.instance.currentUser!.uid);
});

final friendPostsProvider = FutureProvider.autoDispose<List<PostModel>>((ref) async {
  final postService = ref.read(postServiceProvider);
  return postService.getFriendsPosts();
});