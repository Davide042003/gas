import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_model.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'friends_service.dart';
import 'answer_post_model.dart';

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

  Future<void> addAnswerToPost(String postId, AnswerPostModel answer, String idUserPost, int innerListIndex) async {
    try {
      // Get the reference to the post document in Firestore
      final postRef = FirebaseFirestore.instance
          .collection('users')
          .doc(idUserPost)
          .collection('posts')
          .doc('published_posts')
          .collection('posts')
          .doc(postId);

      // Fetch the post data from Firestore
      final postDoc = await postRef.get();
      final postData = postDoc.data();

      if (postData != null) {
        // Convert the 'answersTap' data to a map of int keys to lists of AnswerPostModel objects
        final Map<String, dynamic>? answersData = postData['answersTap'];
        Map<int, List<AnswerPostModel>> answersMap = {};
        if (answersData != null) {
          answersMap = (answersData as Map<String, dynamic>).map(
                (key, value) => MapEntry(int.parse(key), (value as List<dynamic>)
                .map((answerData) => AnswerPostModel.fromData(answerData))
                .toList()),
          );
        }

        // Add the new answer to the appropriate inner list
        if (answersMap.containsKey(innerListIndex)) {
          answersMap[innerListIndex]!.add(answer);
        } else {
          answersMap[innerListIndex] = [answer];
        }

        // Update the 'answersTap' field in the post data
        postData['answersTap'] = answersMap.map(
              (key, value) => MapEntry(key.toString(), value.map((answer) => answer.toJson()).toList()),
        );

        // Save the updated post data back to Firestore
        await postRef.update(postData);

        print('Answer added successfully to post with ID: $postId');
      } else {
        print('Post with ID: $postId does not exist.');
      }
    } catch (error) {
      // Handle any errors that occur during the process
      print('Error adding answer to post: $error');
    }
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

  Future<List<PostModel>> getFriendsPosts() async {
    final FriendSystem friendService = FriendSystem(userId: userId);

    final friendsSnapshot = await friendService.getFriendsImm();
    final friendIds = friendsSnapshot.docs.map((doc) => doc.id).toList();
    final friendPosts = <PostModel>[];

    // Retrieve the posts of each friend and filter out the posts the user has already seen
    for (final friendId in friendIds) {
      final friendPostsQuery = FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('posts')
          .doc('published_posts')
          .collection('posts')
          .orderBy('timestamp', descending: true);

      final friendPostsSnapshot = await friendPostsQuery.get();

      print('Number of posts for friend with ID $friendId: ${friendPostsSnapshot.size}');

      for (final postDoc in friendPostsSnapshot.docs) {
        final postId = postDoc.id;
        final post = PostModel.fromData(postDoc.data());
        print(postDoc.id);
        post.postId = postId;

        if(post.isMyFriends!) {
          if (!await _hasUserSeenPost(postId)) {
            friendPosts.add(post);
          }
        }
      }
    }

    // Sort the friendPosts list based on timestamp (descending order)
    friendPosts.sort((a, b) => b.timestamp!.compareTo(a.timestamp!));

    return friendPosts;
  }

  Future<int> getAnswersLengthByIndex(String postId, String userId, int innerListIndex) async {
    try {
      // Get the reference to the post document in Firestore
      final postRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('posts')
          .doc('published_posts')
          .collection('posts')
          .doc(postId);

      // Fetch the post data from Firestore
      final postDoc = await postRef.get();
      final postData = postDoc.data();

      if (postData != null) {
        // Convert the 'answersTap' data to a map of int keys to lists of AnswerPostModel objects
        final Map<String, dynamic>? answersData = postData['answersTap'];
        Map<int, List<AnswerPostModel>> answersMap = {};
        if (answersData != null) {
          answersMap = (answersData as Map<String, dynamic>).map(
                (key, value) => MapEntry(int.parse(key), (value as List<dynamic>)
                .map((answerData) => AnswerPostModel.fromData(answerData))
                .toList()),
          );
        }

        // Check if the answersMap contains the specified innerListIndex
        if (answersMap.containsKey(innerListIndex)) {
          // Return the length of the array at the specified index
          return answersMap[innerListIndex]!.length;
        } else {
          // If the innerListIndex doesn't exist, return 0
          return 0;
        }
      } else {
        print('Post with ID: $postId does not exist.');
        return 0;
      }
    } catch (error) {
      // Handle any errors that occur during the process
      print('Error retrieving answers length: $error');
      return 0;
    }
  }
}
