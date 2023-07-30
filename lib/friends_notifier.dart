import 'package:gas/core/models/friends_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';

final FriendSystem friendSystem = FriendSystem(userId: FirebaseAuth.instance.currentUser?.uid ?? '');

final receivedRequestsProvider = FutureProvider<List<DocumentSnapshot>>((ref) async {
  final snapshot = await friendSystem.getReceivedRequestsImm();
  return snapshot.docs;
});

final sentRequestsProvider = FutureProvider<List<DocumentSnapshot>>((ref) async {
  final snapshot = await friendSystem.getSentRequestsImm();
  return snapshot.docs;
});

final friendsProvider = FutureProvider<List<DocumentSnapshot>>((ref) async {
  final snapshot = await friendSystem.getFriendsImm();
  return snapshot.docs;
});


final nonFriendsContactsProvider = StateNotifierProvider<NonFriendsContactsNotifier, AsyncValue<List<Contact>>>((ref) {
  return NonFriendsContactsNotifier();
});

class NonFriendsContactsNotifier extends StateNotifier<AsyncValue<List<Contact>>> {
  NonFriendsContactsNotifier() : super(AsyncValue.loading()) {
    // Load the contacts on initialization
    loadContacts();
  }

  Future<void> loadContacts() async {
    try {
      // Fetch the contacts and store them in the state
      List<Contact> nonFriendsContacts = await friendSystem.getNonFriendsContacts();
      state = AsyncValue.data(nonFriendsContacts);
    } catch (error, stackTrace) {
      // Handle any errors that occur during fetching
      state = AsyncValue.error(error, stackTrace);
    }
  }
}