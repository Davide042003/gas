import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserInfoService {

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