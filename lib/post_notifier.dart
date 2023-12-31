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

final globalPostsProvider = FutureProvider.autoDispose<List<PostModel>>((ref) async {
  final postService = ref.read(postServiceProvider);
  return postService.getGlobalPosts(ref);
});

final userPostsProvider = FutureProvider.family<List<PostModel>, String>((ref, userId) async {
  final postService = ref.read(postServiceProvider);
  return postService.getUserPosts(userId);
});

class SelectedPostNotifier extends StateNotifier<PostModel?> {
  SelectedPostNotifier() : super(null);

  void setSelectedPost(PostModel post) {
    state = post;
  }

  void clearSelectedPost() {
    state = null;
  }
}

final selectedPostProvider = StateNotifierProvider<SelectedPostNotifier, PostModel?>((ref) {
  return SelectedPostNotifier();
});
