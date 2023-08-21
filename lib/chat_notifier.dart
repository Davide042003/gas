import 'package:gas/chat_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/models/conversation_model.dart';
import 'core/models/messagge_model.dart';

final conversationListProvider = FutureProvider<List<Conversation>>((ref) async {
  final conversationList = await MessageService().getConversationList();
  return conversationList;
});

final messagesListProvider = FutureProvider.family<List<Message>, String>((ref, conversationId) async {
  List<Message> messages = await MessageService().getMessagesForConversation(conversationId);
  return messages;
});