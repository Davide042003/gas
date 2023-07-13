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
    List<Contact> contacts = await ContactsService.getContacts();
    List<String?> phoneNumbers =
    contacts.map((contact) => contact.phones?.first.value).toList();

    QuerySnapshot<Map<String, dynamic>> sentRequestsSnapshot =
    await getSentRequests().first;
    QuerySnapshot<Map<String, dynamic>> receivedRequestsSnapshot =
    await getReceivedRequests().first;
    QuerySnapshot<Map<String, dynamic>> friendsSnapshot =
    await getFriends().first;

    List<String?> sentRequests =
    sentRequestsSnapshot.docs.map((doc) => doc['recipientUserId'] as String?)
        .toList();
    List<String?> receivedRequests =
    receivedRequestsSnapshot.docs.map((doc) => doc['senderUserId'] as String?)
        .toList();
    List<String> friends =
    friendsSnapshot.docs.map((doc) => doc.id).toList();

    List<Contact> nonFriends = [];

    // Check user existence for each contact
    for (var contact in contacts) {
      if (contact.phones != null &&
          contact.phones!.isNotEmpty &&
          contact.phones!.first.value != null) {
        String phoneNumber = contact.phones!.first.value!;

        // Check if user exists by phone number
        bool userExists = await checkUserExistsByPhoneNumber(phoneNumber);

        if (userExists) {
          String receiverUserId = await getUserIdFromPhoneNumber(phoneNumber);

          if (!sentRequests.contains(receiverUserId) &&
              !receivedRequests.contains(receiverUserId) &&
              !friends.contains(receiverUserId)) {
            nonFriends.add(contact);
          }
        }
      }
    }

    return nonFriends;
  }

  Future<bool> checkUserExistsByPhoneNumber(String phoneNumber) async {

    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<String> getUserIdFromPhoneNumber(String phoneNumber) async {
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('users')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();

      return snapshot.docs[0].id;
  }

  Future<void> sendFriendRequest(String recipientUserId, String senderUserId) async {
    final senderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc('sent_requests')
        .collection('requests')
        .doc();

    final recipientRef = FirebaseFirestore.instance
        .collection('users')
        .doc(recipientUserId)
        .collection('friends')
        .doc('received_requests')
        .collection('requests')
        .doc(senderRef.id);

    final requestData = {
      'recipientUserId': recipientUserId,
      // Additional request information can be added here
    };

    await senderRef.set(requestData);

    final requestData2 = {
      'senderUserId': senderUserId,
      // Additional request information can be added here
    };

    await recipientRef.set(requestData2);
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

  Future<void> deleteSentRequest(String recipientUserId) async {
    final senderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc('sent_requests')
        .collection('requests')
        .where('recipientUserId', isEqualTo: recipientUserId);

    final senderSnapshot = await senderRef.get();
    if (senderSnapshot.size > 0) {
      final requestDoc = senderSnapshot.docs.first;
      await requestDoc.reference.delete();

      final recipientRef = FirebaseFirestore.instance
          .collection('users')
          .doc(recipientUserId)
          .collection('friends')
          .doc('received_requests')
          .collection('requests')
          .doc(requestDoc.id);

      await recipientRef.delete();
    }
  }

  Future<void> deleteFriend(String friendUserId) async {
    final senderAcceptedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc('accepted_friends')
        .collection('friends')
        .doc(friendUserId);

    await senderAcceptedRef.delete();

    final recipientAcceptedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(friendUserId)
        .collection('friends')
        .doc('accepted_friends')
        .collection('friends')
        .doc(userId);

    await recipientAcceptedRef.delete();
  }

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> searchUsers(String searchText,) {
    final queryText = searchText.toLowerCase();

    final stream = FirebaseFirestore.instance
        .collection('users')
        .orderBy('username', descending: false)
        .snapshots();

    return stream.map((snapshot) {
      final filteredDocs = snapshot.docs.where((doc) {
        final username = doc.data()['username'].toString().toLowerCase();
        final name = doc.data()['name'].toString().toLowerCase();
        final userIdDoc = doc.id;
        return (username.contains(queryText) || name.contains(queryText)) &&
            userIdDoc != userId;
      }).toList();

      return filteredDocs;
    });
  }

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> searchFriends(String searchText,) {
    final queryText = searchText.toLowerCase();

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc('accepted_friends')
        .collection('friends')
        .snapshots();

    return stream.map((snapshot) {
      final filteredDocs = snapshot.docs.where((doc) {
        final username = doc.data()['username'].toString().toLowerCase();
        final name = doc.data()['name'].toString().toLowerCase();
        final userId = doc.id;
        return (username.contains(queryText) || name.contains(queryText)) &&
            userId != userId;
      }).toList();

      return filteredDocs;
    });
  }

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> searchSentRequests(String searchText,) {
    final queryText = searchText.toLowerCase();

    final sentRequestsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc('sent_requests')
        .collection('requests')
        .snapshots();

    return sentRequestsStream.asyncMap((snapshot) async {
      final filteredDocs = <DocumentSnapshot<Map<String, dynamic>>>[];

      for (final doc in snapshot.docs) {
        final recipientUserId = doc['recipientUserId'].toString();

        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(recipientUserId)
            .get();

        final username = userSnapshot.data()?['username']?.toString()?.toLowerCase();
        final name = userSnapshot.data()?['name']?.toString()?.toLowerCase();

        if ((username?.contains(queryText) ?? false) || (name?.contains(queryText) ?? false)) {
          filteredDocs.add(userSnapshot);
        }
      }

      return filteredDocs;
    });
  }

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> searchReceivedRequests(String searchText,) {
    final queryText = searchText.toLowerCase();

    final sentRequestsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc('received_requests')
        .collection('requests')
        .snapshots();

    return sentRequestsStream.asyncMap((snapshot) async {
      final filteredDocs = <DocumentSnapshot<Map<String, dynamic>>>[];

      for (final doc in snapshot.docs) {
        final senderUserId = doc['senderUserId'].toString();

        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(senderUserId)
            .get();

        final username = userSnapshot.data()?['username']?.toString()?.toLowerCase();
        final name = userSnapshot.data()?['name']?.toString()?.toLowerCase();

        if ((username?.contains(queryText) ?? false) || (name?.contains(queryText) ?? false)) {
          filteredDocs.add(userSnapshot);
        }
      }

      return filteredDocs;
    });
  }

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> searchContactsByUsername(String searchText) {
    final queryText = searchText.toLowerCase();

    return Stream.fromFuture(getNonFriendsContacts()).asyncMap((nonFriends) async {
      final filteredDocs = <DocumentSnapshot<Map<String, dynamic>>>[];

      for (final contact in nonFriends) {
        final phoneNumber = contact.phones?.first.value;
        if (phoneNumber != null) {
          final userExists = await checkUserExistsByPhoneNumber(phoneNumber);
          if (userExists) {
            final userId = await getUserIdFromPhoneNumber(phoneNumber);
            final userSnapshot = await FirebaseFirestore.instance.collection(
                'users').doc(userId).get();
            final username = userSnapshot.data()?['username']
                ?.toString()
                ?.toLowerCase();
            final name = userSnapshot.data()?['name']
                ?.toString()
                ?.toLowerCase();

            if ((username?.contains(queryText) ?? false) ||
                (name?.contains(queryText) ?? false)) {
              filteredDocs.add(userSnapshot);
            }
          }
        }
      }

      return filteredDocs;
    });
  }
}