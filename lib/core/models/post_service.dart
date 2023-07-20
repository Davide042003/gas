import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_model.dart';

class PostService {
  final String userId;

  PostService(this.userId);

  Future<void> publishPost({
    required String question,
    List<String>? images,
    List<String>? answersList,
    required bool isAnonymous,
    required bool isMyFriends,
  }) async {
    final post = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('posts')
        .doc('published_posts')
        .collection('posts')
        .doc();

    final postData = {
      'question': question,
      'images': images ?? [],
      'answersList': answersList ?? [],
      'isAnonymous': isAnonymous,
      'isMyFriends': isMyFriends,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await post.set(postData);
  }

  Future<List<PostModel>> getFriendsPosts() async {
    final friends = await _getFriendsList();

    final friendPosts = <PostModel>[];

    // Retrieve the posts of each friend and filter out the posts the user has already seen
    for (final friendId in friends) {
      final friendPostsQuery = FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('posts')
          .doc('published_posts')
          .collection('posts')
          .orderBy('timestamp', descending: true);

      final friendPostsSnapshot = await friendPostsQuery.get();

      for (final postDoc in friendPostsSnapshot.docs) {
        final postId = postDoc.id;
        final post = PostModel.fromData(postDoc.data());

        if (!await _hasUserSeenPost(postId)) {
          friendPosts.add(post);
        }
      }
    }

    // Sort the friendPosts list based on timestamp (descending order)
    friendPosts.sort((a, b) => b.timestamp!.compareTo(a.timestamp!));

    return friendPosts;
  }

  Future<void> markPostAsSeen(String postId) async {
    final seenPostsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('posts')
        .doc('seen_posts')
        .collection('posts');

    await seenPostsRef.doc(postId).set({});
  }

  Future<bool> _hasUserSeenPost(String postId) async {
    final seenPostsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('posts')
        .doc('seen_posts')
        .collection('posts');

    final postDoc = await seenPostsRef.doc(postId).get();
    return postDoc.exists;
  }

  // Replace this method with your implementation to get the user's friend list
  Future<List<String>> _getFriendsList() async {
    // Replace this with your logic to fetch the user's friend list
    // For example, you might store the friend IDs in a subcollection of the user document
    return ['friend_id_1', 'friend_id_2'];
  }
}
