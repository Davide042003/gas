import 'package:gas/core/models/friends_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'core/models/friends_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

final contactsProvider = FutureProvider<List<Contact>>((ref) async {
  List<Contact> contacts = await ContactsService.getContacts();
  return contacts;
});

final potentialFriendsWithCommonFriendsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return friendSystem.getPotentialFriendsWithCommonFriendsCount(ref);
});


final nonFriendsContactsProvider = FutureProvider<List<Contact>>((ref) {
  return friendSystem.getNonFriendsContacts(ref);
});
