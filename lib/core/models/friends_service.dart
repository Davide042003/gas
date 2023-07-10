import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';

class FriendSystem {
  final String userId;

  FriendSystem({required this.userId});

  Stream<QuerySnapshot<Map<String, dynamic>>> getSentRequests() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc('sent_requests')
        .collection('requests')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getReceivedRequests() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc('received_requests')
        .collection('requests')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getFriends() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc('accepted_friends')
        .collection('friends')
        .snapshots();
  }

  Future<List<Contact>> getContacts() async {
    Iterable<Contact>? contacts = await ContactsService.getContacts();
    List<Contact> contactList = contacts?.toList() ?? [];
    return contactList;
  }

  Future<List<Contact>> getNonFriendsContacts() async {
    List<Contact> contacts = await ContactsService.getContacts();;
    List<String?> phoneNumbers = contacts.map((contact) => contact.phones?.first.value).toList();

    QuerySnapshot<Map<String, dynamic>> sentRequestsSnapshot = await getSentRequests().first;
    QuerySnapshot<Map<String, dynamic>> receivedRequestsSnapshot = await getReceivedRequests().first;
    QuerySnapshot<Map<String, dynamic>> friendsSnapshot = await getFriends().first;

    List<String?> sentRequests = sentRequestsSnapshot.docs.map((doc) => doc['recipientUserId'] as String?).toList();
    List<String?> receivedRequests = receivedRequestsSnapshot.docs.map((doc) => doc['senderUserId'] as String?).toList();
    List<String> friends = friendsSnapshot.docs.map((doc) => doc.id).toList();

    List<Contact> nonFriends = [];
    for (var contact in contacts) {
      if (contact.phones != null &&
          contact.phones!.isNotEmpty &&
          contact.phones!.first.value != null &&
          !phoneNumbers.contains(contact.phones!.first.value) &&
          !sentRequests.contains(contact.phones!.first.value) &&
          !receivedRequests.contains(contact.phones!.first.value) &&
          !friends.contains(contact.phones!.first.value)) {
        nonFriends.add(contact);
      }
    }

    return nonFriends;
  }

  Future<void> sendFriendRequest(String recipientUserId) async {
    final senderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc('sent_requests')
        .collection('requests')
        .doc();

    await senderRef.set({
      'recipientUserId': recipientUserId,
      // Additional request information can be added here
    });
  }

  Future<void> acceptFriendRequest(String senderUserId) async {
    final senderReceivedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc('received_requests')
        .collection('requests')
        .where('senderUserId', isEqualTo: senderUserId);

    final senderReceivedSnapshot = await senderReceivedRef.get();
    if (senderReceivedSnapshot.size > 0) {
      final senderRequestDoc = senderReceivedSnapshot.docs.first;
      await senderRequestDoc.reference.delete();
    }

    final senderAcceptedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc('accepted_friends')
        .collection('friends')
        .doc(senderUserId);

    await senderAcceptedRef.set({});

    final recipientSentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(senderUserId)
        .collection('friends')
        .doc('sent_requests')
        .collection('requests')
        .where('recipientUserId', isEqualTo: userId);

    final recipientSentSnapshot = await recipientSentRef.get();
    if (recipientSentSnapshot.size > 0) {
      final recipientRequestDoc = recipientSentSnapshot.docs.first;
      await recipientRequestDoc.reference.delete();
    }

    final recipientAcceptedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(senderUserId)
        .collection('friends')
        .doc('accepted_friends')
        .collection('friends')
        .doc(userId);

    await recipientAcceptedRef.set({});
  }
}
