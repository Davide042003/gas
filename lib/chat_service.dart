import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/models/conversation_model.dart';
import 'core/models/messagge_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> sendInitialMessage({
    required String content,
    required String receiverId,
    required bool senderIsAnonymous,
    required bool receiverIsAnonymous,
    String? idPost,
  }) async {
    final newMessage = Message(
      id: "",
      content: content,
      senderId: uid,
      receiverId: receiverId,
      idPost: idPost,
      timestamp: Timestamp.now(),
    );

    // Add the message to Firestore
    await _firestore.collection('messages').add(newMessage.toJson());

    // Update conversation details if needed
    await getOrCreateConversationId(senderId: uid,
        receiverId: receiverId,
        senderIsAnonymous: senderIsAnonymous,
        receiverIsAnonymous: receiverIsAnonymous,
        newMessage: newMessage);
  }

  Future<String> getOrCreateConversationId({
    required String senderId,
    required String receiverId,
    required senderIsAnonymous,
    required receiverIsAnonymous,
    required Message newMessage,
  }) async {
    final conversationId = _generateConversationId(
        senderId, receiverId, senderIsAnonymous, receiverIsAnonymous);

    print("conversationId" + conversationId);

    final querySnapshot = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();

    if (querySnapshot.exists) {
      await querySnapshot.reference.set({
        'lastMessage': newMessage.content,
        'lastMessageTimestamp': newMessage.timestamp,
      }, SetOptions(merge: true));

      return conversationId;
    } else {
      final newConversation = Conversation(
        id: conversationId,
        participant1Id: senderId,
        participant1IsAnonymous: senderIsAnonymous,
        participant2Id: receiverId,
        participant2IsAnonymous: receiverIsAnonymous,
        lastMessage: newMessage.content,
        lastMessageTimestamp: newMessage.timestamp,
      );

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .set(newConversation.toJson());

      return conversationId;
    }
  }


  String _generateConversationId(String userId1, String userId2,
      bool anonymous1, bool anonymous2) {
    final sortedUserIds = [userId1, userId2]..sort();
    return '${sortedUserIds[0]}_${sortedUserIds[1]}_${anonymous1
        ? 'anon'
        : 'notanon'}_${anonymous2 ? 'anon' : 'notanon'}';
  }

  Future<List<Conversation>> getConversationList() async {
    final querySnapshot1 = await _firestore
        .collection('conversations')
        .where('participant1Id', isEqualTo: uid)
        .get();

    final querySnapshot2 = await _firestore
        .collection('conversations')
        .where('participant2Id', isEqualTo: uid)
        .get();

    final conversationList1 = querySnapshot1.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Conversation.fromData(data);
    }).toList();

    final conversationList2 = querySnapshot2.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Conversation.fromData(data);
    }).toList();

    final mergedConversationList = [...conversationList1, ...conversationList2];
    mergedConversationList.sort((a, b) =>
        b.lastMessageTimestamp!.compareTo(a.lastMessageTimestamp!));

    return mergedConversationList;
  }
}