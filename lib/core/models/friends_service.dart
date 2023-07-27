import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:rxdart/rxdart.dart';

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

  Future<QuerySnapshot<Map<String, dynamic>>> getReceivedRequestsImm() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc('received_requests')
        .collection('requests')
        .get();
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

    return stream.asyncMap((snapshot) async {
      final filteredDocs = <DocumentSnapshot<Map<String, dynamic>>>[];

      for (final doc in snapshot.docs) {
        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(doc.id)
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
            final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
            final username = userSnapshot.data()?['username']?.toString()?.toLowerCase();
            final name = userSnapshot.data()?['name']?.toString()?.toLowerCase();

            if ((username?.contains(queryText) ?? false) || (name?.contains(queryText) ?? false)) {
              filteredDocs.add(userSnapshot);
            }
          }
        }
      }

      return filteredDocs;
    });
  }

  Stream<List<Map<String, dynamic>>> combineStreams(String searchText) {
    final queryText = searchText.toLowerCase();

    final searchFriendsStream = searchFriends(searchText);
    final searchSentRequestsStream = searchSentRequests(searchText);
    final searchReceivedRequestsStream = searchReceivedRequests(searchText);
    final searchContactsStream = searchContactsByUsername(searchText);

    final combinedStream = Rx.combineLatest4(
      searchFriendsStream,
      searchReceivedRequestsStream,
      searchSentRequestsStream,
      searchContactsStream,
          (List<DocumentSnapshot<Map<String, dynamic>>> friends,
          List<DocumentSnapshot<Map<String, dynamic>>> receivedRequests,
          List<DocumentSnapshot<Map<String, dynamic>>> sentRequests,
          List<DocumentSnapshot<Map<String, dynamic>>> contacts,) async {
        List<Map<String, dynamic>> combinedResults = [];

        // Add friends with title
        if (friends.isNotEmpty) {
          combinedResults.add({'title': 'Friends'});
          combinedResults.add({'type': 'friends'});
          combinedResults.addAll(friends.map((doc) => doc.data()!));
        }

        // Add sent requests with title
        if (sentRequests.isNotEmpty) {
          combinedResults.add({'title': 'Sent Requests'});
          combinedResults.add({'type': 'sentRequest'});
          combinedResults.addAll(sentRequests.map((doc) => doc.data()!));
        }

        // Add received requests with title
        if (receivedRequests.isNotEmpty) {
          combinedResults.add({'title': 'Received Requests'});
          combinedResults.add({'type': 'receivedRequest'});
          combinedResults.addAll(receivedRequests.map((doc) => doc.data()!));
        }

        // Add contacts with title
        if (contacts.isNotEmpty) {
          combinedResults.add({'title': 'Contacts'});
          combinedResults.add({'type': 'contact'});
          combinedResults.addAll(
            await Future.wait(
              contacts.map(
                    (DocumentSnapshot<Map<String, dynamic>> doc) async {
                  final contactData = doc.data()!;
                  final phoneNumber = contactData['phoneNumber'];

                  // Assuming you have a ContactService that fetches the display name based on the phone number
                  final displayName = await getDisplayNameByPhoneNumber(
                      phoneNumber);

                  contactData['displayName'] =
                      displayName; // Add the 'displayName' field
                  return contactData;
                },
              ),
            ),
          );
        }

        return combinedResults;
      },
    ).asyncMap((
        value) => value); // Convert the Future<List<Map<String, dynamic>>> to List<Map<String, dynamic>>

    return combinedStream;
  }

  Future<String> getDisplayNameByPhoneNumber(String phoneNumber) async {
    // Query the contacts with the given phone number
    final Iterable<Contact> contacts = await ContactsService.getContactsForPhone(phoneNumber);

    if (contacts.isNotEmpty) {
      // Get the first contact that matches the phone number
      final Contact contact = contacts.first;

      print(contact.displayName);
      // Retrieve the display name
      return contact.displayName ?? '';
    }

    return '';
  }

  Future<void> declineFriendRequest(String senderUserId) async {
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

      // Delete the corresponding request in the sender's "sent_requests" collection
      final recipientRef = FirebaseFirestore.instance
          .collection('users')
          .doc(senderUserId)
          .collection('friends')
          .doc('sent_requests')
          .collection('requests')
          .where('recipientUserId', isEqualTo: userId);

      final recipientSnapshot = await recipientRef.get();
      if (recipientSnapshot.size > 0) {
        final recipientRequestDoc = recipientSnapshot.docs.first;
        await recipientRequestDoc.reference.delete();
      }
    }
  }
}
