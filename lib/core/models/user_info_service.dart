import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class UserInfoService {

  Stream<UserModel?> fetchProfileData() {
    try {
      // Get the current user's UID4
      String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Create a document reference for the user
      DocumentReference userRef = FirebaseFirestore.instance.collection('users')
          .doc(uid);

      // Return the snapshot changes as a stream
      return userRef.snapshots().map((snapshot) {
        if (snapshot.exists) {
          // Convert the document data to a UserModel object
          UserModel user = UserModel.fromData(
              snapshot.data() as Map<String, dynamic>);
          print('FETCHED user profile data');
          return user;
        } else {
          // Document doesn't exist
          return null;
        }
      });
    } catch (e) {
      // Error handling
      print('Error fetching user profile data: $e');
      return Stream.error('Error fetching user profile data');
    }
  }

  Future<String> saveImage(File imageFile) async {
    try {
      // Generate a unique file name
      String fileName = path.basename(imageFile.path);

      // Upload the image file to Firebase Storage
      Reference storageRef = FirebaseStorage.instance.ref().child('user_images/$fileName');
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

  Future<void> deleteImageProfile(String imageUrl) async {
    try {
      // Get the reference to the image file in Firebase Storage
      Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);

      // Delete the image file
      await storageRef.delete();

      print('Picture deleted successfully');
    } catch (error) {
      // Handle any errors that occur during the process
      print('Error deleting picture: $error');
      throw Exception('Error deleting picture');
    }
  }

  Future<void> updateUser(UserModel updatedUser, Function? onCompleted) async {
    try {
      // Get the current user's UID
      String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Create a document reference for the user
      DocumentReference userRef = FirebaseFirestore.instance.collection('users')
          .doc(uid);

      Map<String, dynamic> updatedFields = updatedUser.toJson();

      // Remove the null values from the map (optional)
      updatedFields.removeWhere((key, value) => value == null);

      // Update the user document with the new data
      await userRef.update(updatedFields);

      print('UPDATED user profile data');

      if (onCompleted != null) {
        onCompleted();
      }
    } catch (e) {
      // Error handling
      print('Error updating user profile data: $e');
      throw Exception('Error updating user profile data');
    }
  }

  Future<void> storeUserInfo(UserModel user) async {
    try {
      // Assuming you have a 'users' collection in your Cloud Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.id).set(
        user.toJson(), // Convert the UserModel object to a JSON representation
      );
      print('User information stored/updated successfully!');

    } catch (error) {
      // Handle any errors that occur during the process
      print('Error storing user information: $error');
    }
  }

}