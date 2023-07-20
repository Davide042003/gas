import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_model.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class PostService {
  final String userId;

  PostService({required this.userId});

  Future<String> saveImage(File imageFile) async {
    try {
      // Generate a unique file name
      String fileName = path.basename(imageFile.path);

      // Upload the image file to Firebase Storage
      Reference storageRef =
          FirebaseStorage.instance.ref().child('user_images/$fileName');
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);

      // Get the download URL of the uploaded image
      String imageUrl = await taskSnapshot.ref.getDownloadURL();

      print('Image saved successfully: $imageUrl');
      return imageUrl;
    } catch (error) {
      // Handle any errors that occur during the process
      print('Error saving image: $error');
      throw Exception('Error saving image');
    }
  }

  Future<void> publishPost(PostModel post) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('posts')
          .doc('published_posts')
          .collection('posts')
          .doc()
          .set(
            post.toJson(), // Convert the PostModel object to a JSON representation
          );
      print('Post stored successfully!');
    } catch (error) {
      // Handle any errors that occur during the process
      print('Error storing post information: $error');
    }
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
