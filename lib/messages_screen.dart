import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gas/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/models/user_model.dart';
import 'core/models/user_info_service.dart';
import 'package:gas/user_notifier.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'profile_edit_screen.dart';
import 'post_notifier.dart';
import 'package:gas/my_post.dart';
import 'core/ui/conversation_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/models/conversation_model.dart';
import 'package:gas/chat_service.dart';
import 'chat_notifier.dart';
import 'core/models/user_model.dart';

class MessageScreen extends ConsumerStatefulWidget {
  final Conversation conversation;
  final UserModel userProfile;

  MessageScreen({
    required this.conversation,
    required this.userProfile,
  });

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends ConsumerState<MessageScreen> {
  TextEditingController textEditingController = TextEditingController();
  String? otherParticipantId;
  FocusNode focusField = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    otherParticipantId = widget.conversation.participant1Id == MessageService().uid
        ? widget.conversation.participant2Id
        : widget.conversation.participant1Id;
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundDefault,
      body: Stack(children:[
        SafeArea(
        bottom: false,
        child: Column(
              children: [
                Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 35,
                        ),
                        Container(
                          child: Text(
                            "${widget.userProfile.username}", textAlign: TextAlign.center,
                            style: ref
                                .watch(stylesProvider)
                                .text
                                .titleOnBoarding
                                .copyWith(fontSize: 28),),
                        ),
                        InkWell(
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 35,
                            color: AppColors.white,
                          ),
                          onTap: () async {
                            await ref.refresh(conversationListProvider);
                            Navigator.pop(context);
                          },
                        ),
                      ],)),
                SizedBox(height: 10,),
                Stack(children: [
                  Container(
                    color: AppColors.whiteShadow,
                    height: screenHeight / 600,),
                  Center(child: Container(color: AppColors.white,
                    height: screenHeight / 400,
                    width: screenWidth / 3,))
                ],),
                Expanded(
                  child: Consumer(
                    builder: (context, watch, child) {
                      final messagesAsyncValue = ref.watch(messagesListProvider(widget.conversation.id));

                      return messagesAsyncValue.when(
                        data: (messages) {
                          WidgetsBinding.instance!.addPostFrameCallback((_) {
                            // Scroll to the end of the list when new messages are added
                            if (_scrollController.hasClients) {
                              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                            }
                          });

                          return SingleChildScrollView(controller: _scrollController, child: Column(children:[ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.only(bottom: 85),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              // Determine if the message is from the current user
                              final bool isCurrentUser = message.senderId == widget.userProfile.id;

                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                  isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  children: [
                                    if (!isCurrentUser)
                                      Padding(
                                        padding: EdgeInsets.only(right: 8.0),
                                        child: CircleAvatar(
                                          // Display sender's avatar or icon
                                        ),
                                      ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isCurrentUser
                                            ? Colors.blueAccent
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: isCurrentUser
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message.content,
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )]));
                        },
                        loading: () => CircularProgressIndicator(),
                        error: (error, stackTrace) => Text("Error loading messages"),
                      );
                    },
                  ),
                ),
              ],
            ),
      ),
        AnimatedPositioned(
          duration: Duration(milliseconds: 300),
          bottom: MediaQuery.of(context).viewInsets.top,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textEditingController,
                    focusNode: focusField,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () async {
                    if(textEditingController.text.isNotEmpty) {
                      await MessageService().sendMessage(
                          content: textEditingController.text,
                          receiverId: otherParticipantId!,
                          conversationId: widget.conversation
                              .id);
                      textEditingController.clear();
                      ref.refresh(messagesListProvider(widget.conversation.id));
                    }
                  },
                  child: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ]
      ),
    );
  }
}
