import 'package:flutter/material.dart';
import 'package:gas/styles/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:gas/styles/styles_provider.dart';
import 'core/models/user_info_service.dart';
import 'core/models/user_model.dart';
import 'core/models/friends_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'friends_notifier.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'post_notifier.dart';
import 'friend_post.dart';

class BottomSheetProfile {
  static void showOtherProfileBottomSheet(BuildContext context, String userId) {
    Widget _nonFriends(Function() onTapAction) {
      return ElevatedButton.icon(
        onPressed: onTapAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.brownShadow,
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          textStyle: TextStyle(
            fontFamily: 'Helvetica',
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: AppColors.brownShadow,
          ),
        ),
        label: Text('Send friend request'),
        icon: Icon(Icons.person_add_alt_1_rounded),
      );
    }

    // Method to show the friend widget
    Widget _buildFriendWidget() {
      return Column(
        children: [
          SizedBox(height: 15),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Le sue Domande di Oggi",
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Helvetica',
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: AppColors.brown,
              ),
            ),
          ),
          SizedBox(height: 10,),
          Consumer(builder: (context, ref, _) {
            final userPostsAsyncValue = ref.watch(userPostsProvider(userId));

            return userPostsAsyncValue.when(
              loading: () => CircularProgressIndicator(),
              error: (error, stackTrace) => Text('Error: $error'),
              data: (userPosts) {
                if (userPosts.isEmpty) {
                  return Text('No posts available.');
                } else {
                  // Display up to 3 posts for the actual user
                  final postWidgets = userPosts
                      .where((post) => post.isAnonymous == false)
                      .take(3)
                      .map((post) {
                    final localDateTime = post.timestamp!.toDate().toLocal();
                    final hour = localDateTime.hour.toString().padLeft(2, '0');
                    final minute = localDateTime.minute.toString().padLeft(2, '0');

                    return GestureDetector(onTap: () {Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FriendPost(),
                      ),
                    );}, child: Container(
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.question_mark_rounded),
                              SizedBox(width: 10),
                              Text(
                                post.question!,
                                style: TextStyle(
                                  fontFamily: 'Helvetica',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppColors.brown,
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              '$hour:$minute',
                              style: TextStyle(
                                fontFamily: 'Helvetica',
                                fontSize: 15,
                                color: AppColors.brown,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ));
                  })
                      .toList();

                  return Column(children: postWidgets);
                }
              },
            );
          })
        ],
      );
    }

    // Method to show the sent request widget
    Widget _buildSentRequestWidget(Function() onTapAction) {
      return Column(children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.brown,
              width: 3,
            ),
          ),
          constraints: BoxConstraints(
            minHeight: 60,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_add_alt_1_rounded,
                color: AppColors.brown,
              ),
              SizedBox(width: 10),
              Text(
                'Waiting',
                style: TextStyle(
                  fontFamily: 'Helvetica',
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: AppColors.brown,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 5,
        ),
        TextButton(
          onPressed: onTapAction,
          child: Text(
            'Cancel friend request',
            style: TextStyle(
              fontFamily: 'Helvetica',
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: AppColors.white,
            ),
          ),
        ),
      ]);
    }

    // Method to show the received request widget
    Widget _buildReceivedRequestWidget(
        String username, Function() accept, Function() decline) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.a,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.symmetric(vertical: 25),
        child: Column(
          children: [
            Text(
              '$username has invited you as a friend', // Replace 'Username' with the actual username
              style: TextStyle(
                fontFamily: 'Helvetica',
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: AppColors.white,
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: accept,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    primary: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10), // Adjust the button padding
                  ),
                  icon: Icon(
                    Icons.person_add_rounded,
                    color: AppColors.brown,
                  ),
                  label: Text(
                    'Accept',
                    style: TextStyle(
                      fontFamily: 'Helvetica',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.brown,
                    ),
                  ),
                ),
                SizedBox(
                  width: 5,
                ),
                ElevatedButton.icon(
                  onPressed: decline,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    primary: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: AppColors.brown, width: 2), // Add a border
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10), // Adjust the button padding
                  ),
                  icon: Icon(
                    Icons.person_off_rounded,
                    color: AppColors.brown,
                  ),
                  label: Text(
                    'Decline',
                    style: TextStyle(
                      fontFamily: 'Helvetica',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.brown,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    String uidActualUser = FirebaseAuth.instance.currentUser?.uid ?? '';
    FriendSystem friendSystem =
        FriendSystem(userId: FirebaseAuth.instance.currentUser?.uid ?? '');

    Future<void> sendFriendRequest(String recipientUserId) async {
      await friendSystem.sendFriendRequest(
          recipientUserId, FirebaseAuth.instance.currentUser?.uid ?? '');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundDefault,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final userInfoProvider = otherUserProfileProvider(userId);

            return Container(
              height: MediaQuery.of(context).size.height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Consumer(builder: (context, ref, child) {
                    final userProfileFuture =
                        ref.watch(userInfoProvider.future);
                    return FutureBuilder<UserModel?>(
                      future: userProfileFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          UserModel? userProfile = snapshot.data;
                          String buttonText = '';
                          Function()? onTapAction;

                          final sentRequests =
                          ref.watch(sentRequestsProvider);
                          final receivedRequests =
                          ref.watch(receivedRequestsProvider);
                          final friends =
                          ref.watch(friendsProvider);

                          return Stack(children: [
                            userProfile!.imageUrl!.isEmpty
                                ? SizedBox()
                                : Container(
                                    width: screenWidth,
                                    height: screenHeight / 2.35,
                                    child: Stack(
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: userProfile!.imageUrl!,
                                          imageBuilder:
                                              (context, imageProvider) =>
                                                  Container(
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: imageProvider,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          progressIndicatorBuilder: (context,
                                                  url, downloadProgress) =>
                                              Center(
                                                  child: CupertinoActivityIndicator()), // Show CircularProgressIndicator while loading
                                          errorWidget: (context, url, error) =>
                                              Icon(Icons.error),
                                        ),
                                        Positioned.fill(
                                          child: ClipRect(
                                            child: Align(
                                              alignment: Alignment.topCenter,
                                              child: Container(
                                                height: screenHeight / 2.35 / 3,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      AppColors
                                                          .backgroundDefault
                                                          .withOpacity(0.7),
                                                      AppColors
                                                          .backgroundDefault
                                                          .withOpacity(0.4),
                                                      AppColors
                                                          .backgroundDefault
                                                          .withOpacity(0),
                                                    ],
                                                    stops: [0.0, 0.7, 1.0],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: ClipRect(
                                            child: Align(
                                              alignment: Alignment.bottomCenter,
                                              child: Container(
                                                height:
                                                    screenHeight / 2.35 / 15,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      AppColors
                                                          .backgroundDefault
                                                          .withOpacity(0),
                                                      AppColors
                                                          .backgroundDefault
                                                          .withOpacity(1),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )),
                            Column(children: [
                              Padding(
                                  padding: EdgeInsets.only(
                                    left: 20,
                                    right: 20,
                                    top: MediaQueryData.fromWindow(
                                            WidgetsBinding.instance.window)
                                        .padding
                                        .top,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      InkWell(
                                        child: Icon(
                                          Icons.arrow_downward_rounded,
                                          size: 35,
                                          color: AppColors.white,
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                      SizedBox(width: 50),
                                      Container(
                                        alignment: Alignment.center,
                                        width: 200,
                                        child: Text(
                                          userProfile?.username ?? '',
                                          style: TextStyle(
                                            fontFamily: 'Helvetica',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 19,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )),
                              SizedBox(height: 10),
                              Stack(
                                children: [
                                  Container(
                                    color: AppColors.whiteShadow,
                                    height: screenHeight / 600,
                                  ),
                                  Center(
                                    child: Container(
                                      color: AppColors.white,
                                      height: screenHeight / 400,
                                      width: screenWidth / 2.5,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight / 40),
                              userProfile!.imageUrl!.isEmpty
                                  ? Container(
                                      margin:
                                          EdgeInsets.symmetric(horizontal: 20),
                                      height: screenHeight / 7,
                                      child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: CircleAvatar(
                                            radius: 50,
                                            backgroundImage: userProfile
                                                        ?.imageUrl !=
                                                    ""
                                                ? NetworkImage(
                                                    userProfile!.imageUrl ?? '')
                                                : null,
                                            child: userProfile?.imageUrl == ""
                                                ? Text(
                                                    userProfile?.name != ""
                                                        ? userProfile!.name![0]
                                                        : '',
                                                    style: TextStyle(
                                                        fontFamily: 'Helvetica',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 40,
                                                        color: AppColors.white),
                                                  )
                                                : null,
                                          )),
                                    )
                                  : SizedBox(),
                              SizedBox(
                                  height: userProfile!.imageUrl!.isEmpty
                                      ? screenHeight / 35
                                      : screenHeight / 3.9),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Container(
                                        constraints: BoxConstraints(
                                            maxWidth: screenWidth / 2),
                                        child: Text(
                                          userProfile?.name ?? '',
                                          style: TextStyle(
                                            fontFamily: 'Helvetica',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 40,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      child: Icon(
                                        Icons.ios_share_outlined,
                                        size: 30,
                                        color: AppColors.white,
                                      ),
                                      onTap: () {
                                        // Add your share functionality here
                                      },
                                    ),
                                  ],
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                ),
                              ),
                              SizedBox(height: screenHeight / 100),
                              Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Align(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            userProfile?.bio ?? '',
                                            style: TextStyle(
                                              fontFamily: 'Helvetica',
                                              fontWeight: FontWeight.w300,
                                              fontSize: 20,
                                              color: AppColors.white,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                    alignment: Alignment.centerLeft,
                                  )),
                              SizedBox(
                                height: screenHeight / 50,
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Container(
                                  child: Consumer(
                                    builder: (context, ref, child) {
                                      final sentRequests = ref.watch(sentRequestsProvider);
                                      final receivedRequests = ref.watch(receivedRequestsProvider);
                                      final friends = ref.watch(friendsProvider);

                                      return sentRequests.when(
                                        data: (sentRequestsData) {
                                          return receivedRequests.when(
                                            data: (receivedRequestsData) {
                                              return friends.when(
                                                data: (friendsData) {
                                                  bool isInSentRequests = sentRequestsData.any(
                                                          (doc) => (doc.data() as Map<String, dynamic>)["recipientUserId"] == userId);
                                                  if (isInSentRequests) {
                                                    return _buildSentRequestWidget(() async {
                                                      await friendSystem.deleteSentRequest(userId);
                                                      ref.refresh(sentRequestsProvider);
                                                    });
                                                  } else {
                                                    bool isInReceivedRequests = sentRequestsData.any(
                                                            (doc) => (doc.data() as Map<String, dynamic>)["senderUserId"] == userId);
                                                    if (isInReceivedRequests) {
                                                      return _buildReceivedRequestWidget(
                                                        userProfile.name! ?? '',
                                                            () async {
                                                          await friendSystem.acceptFriendRequest(userId);
                                                          ref.refresh(receivedRequestsProvider);
                                                        },
                                                            () async {
                                                          await friendSystem.declineFriendRequest(userId);
                                                          ref.refresh(receivedRequestsProvider);
                                                        },
                                                      );
                                                    } else {
                                                      bool areFriends = friendsData.any((doc) => doc.id == userId);
                                                      if (areFriends) {
                                                        return _buildFriendWidget();
                                                      } else {
                                                        return _nonFriends(() async {
                                                          await sendFriendRequest(userId);
                                                          ref.refresh(sentRequestsProvider);
                                                          setState(() {});
                                                        });
                                                      }
                                                    }
                                                  }
                                                },
                                                loading: () => CupertinoActivityIndicator(radius: 20,),
                                                error: (error, stackTrace) => Text(
                                                  'Error fetching friends data',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              );
                                            },
                                            loading: () => CupertinoActivityIndicator(radius: 20,),
                                            error: (error, stackTrace) => Text(
                                              'Error fetching received requests data',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          );
                                        },
                                        loading: () => CupertinoActivityIndicator(radius: 20,),
                                        error: (error, stackTrace) => Text(
                                          'Error fetching sent requests data',
                                          style: TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ]),
                          ]);
                        } else if (snapshot.hasError) {
                          return Text(
                            'Error fetching profile data',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          );
                        } else {
                          return CupertinoActivityIndicator(radius: 20,);
                        }
                      },
                    );
                  })
                ],
              ),
            );
          },
        );
      },
    );
  }
}
