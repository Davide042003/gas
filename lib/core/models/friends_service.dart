import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:gas/friends_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FriendSystem {
  final String userId;

  FriendSystem({required this.userId});

  Future<QuerySnapshot<Map<String, dynamic>>> getSentRequestsImm() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc('sent_requests')
        .collection('requests')
        .get();
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

  Future<QuerySnapshot<Map<String, dynamic>>> getFriendsImm() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc('accepted_friends')
        .collection('friends')
        .get();
  }

  Future<List<Contact>> getContacts() async {
    Iterable<Contact>? contacts = await ContactsService.getContacts();
    List<Contact> contactList = contacts?.toList() ?? [];
    return contactList;
  }

  Future<List<Contact>> getNonFriendsContacts(FutureProviderRef<List<Contact>> ref) async {
    final contacts = await ref.read(contactsProvider.future);
    final receivedRequestsSnapshot = await ref.read(receivedRequestsProvider.future);
    final sentRequestsSnapshot = await ref.read(sentRequestsProvider.future);
    final friendsSnapshot = await ref.read(friendsProvider.future);

    List<String?> phoneNumbers = contacts
        .where((contact) => contact.phones?.isNotEmpty == true)
        .map((contact) => contact.phones!.first.value)
        .toList();

    List<String?> sentRequests =
    sentRequestsSnapshot.map((doc) => doc['recipientUserId'] as String?).toList();
    List<String?> receivedRequests =
    receivedRequestsSnapshot.map((doc) => doc['senderUserId'] as String?).toList();
    List<String> friends = friendsSnapshot.map((doc) => doc.id).toList();

    Map<String, DocumentSnapshot<Map<String, dynamic>>> userDataMap = {};

    await Future.wait(phoneNumbers.map((phoneNumber) async {
      if (phoneNumber != null) {
        String phoneNumberEdited = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

        QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('users').where("phoneNumber", isEqualTo: phoneNumberEdited).get();

        if (snapshot.docs.isNotEmpty) {
          userDataMap[phoneNumber] = snapshot.docs.first;
        }
      }
    }));

    List<Contact> nonFriends = [];

    for (var contact in contacts) {
      if (contact.phones != null &&
          contact.phones!.isNotEmpty &&
          contact.phones!.first.value != null) {
        String phoneNumber = contact.phones!.first.value!;

        if (userDataMap.containsKey(phoneNumber)) {
          DocumentSnapshot<Map<String, dynamic>> userDoc = userDataMap[phoneNumber]!;
          String receiverUserId = userDoc.id;

          if (!sentRequests.contains(receiverUserId) &&
              !receivedRequests.contains(receiverUserId) &&
              !friends.contains(receiverUserId) && receiverUserId != userId) {
            nonFriends.add(contact);
          }
        }
      }
    }

    return nonFriends;
  }

  Future<List<Map<String, dynamic>>> getPotentialFriendsWithCommonFriendsCount(FutureProviderRef<List<Map<String, dynamic>>> ref) async {
    final friendsSnapshot = await ref.read(friendsProvider.future);
    final nonFriendsContacts = await ref.read(nonFriendsContactsProvider.future);
    final receivedRequestsSnapshot = await ref.read(receivedRequestsProvider.future);
    final sentRequestsSnapshot = await ref.read(sentRequestsProvider.future);

    final friendsIds = friendsSnapshot.map((doc) => doc.id).toList();

    List<String?> sentRequests = sentRequestsSnapshot.map((doc) => doc['recipientUserId'] as String?).toList();
    List<String?> receivedRequests = receivedRequestsSnapshot.map((doc) => doc['senderUserId'] as String?).toList();

    Map<String, int> potentialFriendsWithCommonFriendsCount = {}; // Map to store potential friends and their common friend count

    for (final friendId in friendsIds) {
      final friendFriendsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc('accepted_friends')
          .collection('friends')
          .get();

      final friendFriendsIds = friendFriendsSnapshot.docs.map((doc) => doc.id).toList();

      for (final potentialFriendId in friendFriendsIds) {
        if (!friendsIds.contains(potentialFriendId)) {
          potentialFriendsWithCommonFriendsCount[potentialFriendId] =
              (potentialFriendsWithCommonFriendsCount[potentialFriendId] ?? 0) + 1;
        }
      }
    }

    final currentUserFriendsSnapshot = await ref.read(friendsProvider.future);
    final currentUserFriendsIds = currentUserFriendsSnapshot.map((doc) => doc.id).toList();

    // Exclude current user from potential friends
    currentUserFriendsIds.add(userId);

    potentialFriendsWithCommonFriendsCount.removeWhere((id, count) =>
    currentUserFriendsIds.contains(id) ||
        sentRequests.contains(id) ||
        receivedRequests.contains(id) ||
        friendsIds.contains(id));

    final potentialFriendDocs = await Future.wait(potentialFriendsWithCommonFriendsCount.keys.map((id) =>
        FirebaseFirestore.instance
            .collection('users')
            .doc(id)
            .get()));

    List<Map<String, dynamic>> potentialFriendsWithCommonFriends = [];

    for (var i = 0; i < potentialFriendDocs.length; i++) {
      final friendDoc = potentialFriendDocs[i];
      final commonFriendsCount = potentialFriendsWithCommonFriendsCount[friendDoc.id];
      potentialFriendsWithCommonFriends.add({
        'userDoc': friendDoc,
        'commonFriendsCount': commonFriendsCount,
      });
    }

    return potentialFriendsWithCommonFriends;
  }

  Future<PhoneNumberCheckResult> checkUserExistsByPhoneNumber(String phoneNumber) async {

    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();

    String phoneNumberEdited =  phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    for (var doc in snapshot.docs) {
      String userPhoneNumber = doc['phoneNumber'];
      if (userPhoneNumber != null) {
        String userPhoneNumberEdited =  userPhoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
        if (userPhoneNumberEdited.contains(phoneNumberEdited)) {
          return PhoneNumberCheckResult(userExists: true, matchedPhoneNumber: userPhoneNumber);
        }
      }
    }

    return PhoneNumberCheckResult(userExists: false, matchedPhoneNumber: '');
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

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> searchUsers(String searchText, {int batchSize = 20, DocumentSnapshot<Map<String, dynamic>>? startAfter}) async {
    final queryText = searchText.toLowerCase();

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('username', descending: false)
        .limit(batchSize)
        .withConverter<Map<String, dynamic>>(
      fromFirestore: (snapshot, _) => snapshot.data()!,
      toFirestore: (data, _) => data,
    );

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final querySnapshot = await query.get();

    final filteredDocs = querySnapshot.docs.where((doc) {
      final data = doc.data();
      final username = data['username'].toString().toLowerCase();
      final name = data['name'].toString().toLowerCase();
      final userIdDoc = doc.id;
      return (username.contains(queryText) || name.contains(queryText)) &&
          userIdDoc != userId;
    }).toList();

    return filteredDocs;
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> searchFriends(String searchText, WidgetRef ref) async {
    final queryText = searchText.toLowerCase();

    final friendsSnapshot = await ref.read(friendsProvider.future);

    final filteredDocs = <DocumentSnapshot<Map<String, dynamic>>>[];

    for (final doc in friendsSnapshot) {
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
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> searchSentRequests(String searchText, WidgetRef ref) async {
    final queryText = searchText.toLowerCase();

    final sentRequestsSnapshot = await ref.read(sentRequestsProvider.future);

    final filteredDocs = <DocumentSnapshot<Map<String, dynamic>>>[];

    for (final doc in sentRequestsSnapshot) {
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
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> searchReceivedRequests(String searchText, WidgetRef ref) async {
    final queryText = searchText.toLowerCase();

    final receivedRequestsSnapshot = await ref.read(receivedRequestsProvider.future);

    final filteredDocs = <DocumentSnapshot<Map<String, dynamic>>>[];

    for (final doc in receivedRequestsSnapshot) {
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
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> searchContactsByUsername(String searchText, WidgetRef ref) async {
    final queryText = searchText.toLowerCase();

    final nonFriends = await ref.read(nonFriendsContactsProvider.future);

    final filteredDocs = <DocumentSnapshot<Map<String, dynamic>>>[];

    for (final contact in nonFriends) {
      final phoneNumber = contact.phones?.first.value;
      if (phoneNumber != null) {
        final phoneNumberEdited = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
        final otherUserId = await getUserIdFromPhoneNumber(phoneNumberEdited);

        QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('users').where("phoneNumber", isEqualTo: phoneNumberEdited).get();
        DocumentSnapshot<Map<String, dynamic>> doc = snapshot.docs.first;

        final username = doc.data()?['username']
            ?.toString()
            ?.toLowerCase();
        final name = doc.data()?['name']
            ?.toString()
            ?.toLowerCase();

        if ((username?.contains(queryText) ?? false) ||
            (name?.contains(queryText) ?? false)) {
          filteredDocs.add(doc);
        }
      }
    }

    return filteredDocs;
  }

  Future<List<Map<String, dynamic>>> searchPotentialFriendsWithCommonFriends(
      String searchText, WidgetRef ref) async {
    final potentialFriendsWithCommonFriends = await ref.read(potentialFriendsWithCommonFriendsProvider.future);

    final filteredList = potentialFriendsWithCommonFriends.where((user) {
      final userDoc = user['userDoc'];
      final userData = userDoc.data();
      final username = userData?['username']?.toString()?.toLowerCase();
      final name = userData?['name']?.toString()?.toLowerCase();

      return (username?.contains(searchText) ?? false) ||
          (name?.contains(searchText) ?? false);
    }).toList();

    return filteredList;
  }

  Future<List<Map<String, dynamic>>> combineResults(String searchText, WidgetRef ref) async {
    final queryText = searchText.toLowerCase();

    final friends = await searchFriends(searchText, ref);
    final receivedRequests = await searchReceivedRequests(searchText, ref);
    final sentRequests = await searchSentRequests(searchText, ref);
    final contacts = await searchContactsByUsername(searchText, ref);
    final mutual = await searchPotentialFriendsWithCommonFriends(searchText, ref);

    Set<String> addedUserIds = {}; // Set to track added users

    List<Map<String, dynamic>> combinedResults = [];

    if (friends.isNotEmpty) {
      combinedResults.add({'title': 'Friends'});
      combinedResults.add({'type': 'friends'});
      combinedResults.addAll(friends.map((doc) {
        addedUserIds.add(doc.id); // Add user ID to the set
        return doc.data()!;
      }));
    }

    if (sentRequests.isNotEmpty) {
      combinedResults.add({'title': 'Sent Requests'});
      combinedResults.add({'type': 'sentRequest'});
      combinedResults.addAll(sentRequests.map((doc) {
        addedUserIds.add(doc.id); // Add user ID to the set
        return doc.data()!;
      }));
    }

    if (receivedRequests.isNotEmpty) {
      combinedResults.add({'title': 'Received Requests'});
      combinedResults.add({'type': 'receivedRequest'});
      combinedResults.addAll(receivedRequests.map((doc) {
        addedUserIds.add(doc.id); // Add user ID to the set
        return doc.data()!;
      }));
    }

    if (contacts.isNotEmpty) {
      combinedResults.add({'title': 'Contacts'});
      combinedResults.add({'type': 'contact'});

      await Future.forEach(contacts, (doc) async {
        final contactData = doc.data()!;
        final phoneNumber = contactData['phoneNumber'];

        if (!addedUserIds.contains(phoneNumber)) {
          addedUserIds.add(phoneNumber);

          final displayName = await getDisplayNameByPhoneNumber(phoneNumber);

          if (displayName != null) {
            contactData['displayName'] = displayName;
            combinedResults.add(contactData);
          }
        }
      });
    }

    if (mutual.isNotEmpty) {
      combinedResults.add({'title': 'PERSONE CHE POTRESTI CONOSCERE'});
      combinedResults.add({'type': 'mutual'});

      // Add potential friends with common friends along with the number of common friends
      for (final potentialFriend in mutual) {
        final userDoc = potentialFriend['userDoc'];
        final commonFriendsCount = potentialFriend['commonFriendsCount'];
        combinedResults.add({
          'userDoc': userDoc,
          'commonFriendsCount': commonFriendsCount,
        });
      }
    }

    return combinedResults;
  }

  Future<String> getDisplayNameByPhoneNumber(String phoneNumber) async {
    // Query the contacts with the given phone number
    final Iterable<Contact> contacts = await ContactsService.getContactsForPhone(phoneNumber);

    if (contacts.isNotEmpty) {
      // Get the first contact that matches the phone number
      final Contact contact = contacts.first;
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

class PhoneNumberCheckResult {
  final bool userExists;
  final String matchedPhoneNumber;

  PhoneNumberCheckResult({required this.userExists, required this.matchedPhoneNumber});
}