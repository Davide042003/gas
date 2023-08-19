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

class ChatScreen extends ConsumerStatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    double screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return Scaffold(
        backgroundColor: AppColors.backgroundDefault,
        body: SafeArea(
            child: Column(
                children: [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(width: 40, height: 10),
                          Container(
                            child: Text(
                              "Chat", textAlign: TextAlign.center,
                              style: ref
                                  .watch(stylesProvider)
                                  .text
                                  .titleOnBoarding
                                  .copyWith(fontSize: 28),),
                            width: 100,),
                          InkWell(
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 35,
                              color: AppColors.white,
                            ),
                            onTap: () {
                              context.pop();
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
                  SizedBox(height: 10),
                  Expanded(child: FutureBuilder<List<Conversation>>(
                    future: MessageService().getConversationList(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CupertinoActivityIndicator(radius: 15);
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (snapshot.hasData) {
                        final conversationList = snapshot.data!;
                        return ListView.builder(
                          itemCount: conversationList.length,
                          itemBuilder: (context, index) {
                            final conversation = conversationList[index];
                            final otherParticipantId = conversation.participant1Id == MessageService().uid
                                ? conversation.participant2Id
                                : conversation.participant1Id;

                            return Consumer(
                              builder: (context, watch, child) {
                                final userProfileState = ref.watch(otherUserProfileProvider(otherParticipantId));

                                return userProfileState.when(
                                  data: (userProfile) {
                                    if (userProfile != null) {
                                      return ConversationWidget(
                                        profilePictureUrl: userProfile!.imageUrl!,
                                        username: userProfile!.username!,
                                        lastMessage: conversation.lastMessage ?? "No messages",
                                        isAnonymous: false,
                                        timestamp: conversation.lastMessageTimestamp!,
                                      );
                                    } else {
                                      return CupertinoActivityIndicator(radius: 15,);
                                    }
                                  },
                                  loading: () => CupertinoActivityIndicator(radius: 15,),
                                  error: (error, stackTrace) => Text('Error: $error'),
                                );
                              },
                            );
                          },
                        );
                      } else {
                        return Text('No conversations available.');
                      }
                    },
                  ),
                  ),
                ]
            )
        )
    );
  }
}