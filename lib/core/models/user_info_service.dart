import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class UserInfoService {

  Stream<UserModel?> fetchProfileData() {
    try {
      // Get the current user's UID4
      String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Create a document reference for the user
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      // Return the snapshot changes as a stream
      return userRef.snapshots().map((snapshot) {
        if (snapshot.exists) {
          // Convert the document data to a UserModel object
          UserModel user = UserModel.fromData(snapshot.data() as Map<String, dynamic>);
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

  Future<void> updateUser(UserModel updatedUser, Function? onCompleted) async {
    try {
      // Get the current user's UID
      String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Create a document reference for the user
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      // Update the user document with the new data
      await userRef.update(updatedUser.toJson());

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



  Future<void> storeUserInformation(String name, String username) async {
    try {
      // Get the current user's UID
      String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Create a document reference for the user
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      // Check if the document exists
      DocumentSnapshot userSnapshot = await userRef.get();

      if (userSnapshot.exists) {
        // Document already exists, update the existing document
        await userRef.update({
          'name': name,
          'username': username,
        });
      } else {
        // Document doesn't exist, create a new document
        await userRef.set({
          'name': name,
          'username': username,
        });
      }

      // Success message
      print('User information stored/updated successfully!');
    } catch (e) {
      // Error handling
      print('Error storing/updating user information: $e');
    }
  }

  Future<dynamic> getStoredValueByName(String fieldName) async {
    try {
      // Get the current user's UID
      String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Create a document reference for the user
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      // Retrieve the document snapshot
      DocumentSnapshot userSnapshot = await userRef.get();

      // Check if the document exists
      if (userSnapshot.exists) {
        // Get the field value by name
        userRef.get().then((value) {
          dynamic fieldValue = value.get(fieldName);
          print(fieldValue);
          return fieldValue;
        });
      } else {
        // Document doesn't exist
        return null;
      }
    } catch (e) {
      // Error handling
      print('Error retrieving stored value: $e');
      return null;
    }
  }

}