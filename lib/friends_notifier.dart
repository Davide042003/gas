import 'package:gas/core/models/friends_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FriendSystem friendSystem = FriendSystem(userId: FirebaseAuth.instance.currentUser?.uid ?? '');

final receivedRequestsProvider = FutureProvider<List<DocumentSnapshot>>((ref) async {
  final snapshot = await friendSystem.getReceivedRequestsImm();
  return snapshot.docs;
});

final sentRequestsProvider = FutureProvider<List<DocumentSnapshot>>((ref) async {
  final snapshot = await friendSystem.getSentRequestsImm();
  return snapshot.docs;
});
