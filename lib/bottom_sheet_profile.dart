import 'package:flutter/material.dart';
import 'package:gas/styles/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:gas/styles/styles_provider.dart';
import 'core/models/user_info_service.dart';
import 'core/models/user_model.dart';
import 'core/models/friends_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      // You can return the widget for friend status here
      return Text('You are friends!');
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
        SizedBox(height: 5,),
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
    Widget _buildReceivedRequestWidget() {
      // You can return the widget for received request status here
      return Text('Accept or Decline Request');
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
            return Container(
              height: MediaQuery.of(context).size.height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StreamBuilder<UserModel?>(
                    stream: UserInfoService().fetchOtherProfileData(userId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        UserModel? userProfile = snapshot.data;
                        String buttonText = '';
                        Function()? onTapAction;

                        Stream<QuerySnapshot<Map<String, dynamic>>>
                            sentRequestsStream = friendSystem.getSentRequests();
                        // Stream for checking received requests
                        Stream<QuerySnapshot<Map<String, dynamic>>>
                            receivedRequestsStream =
                            friendSystem.getReceivedRequests();
                        // Stream for checking friends
                        Stream<QuerySnapshot<Map<String, dynamic>>>
                            friendsStream = friendSystem.getFriends();

                        return Stack(children: [
                          userProfile!.imageUrl!.isEmpty
                              ? SizedBox()
                              : Container(
                                  width: screenWidth,
                                  height: screenHeight / 2.35,
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        child: Container(
                                          width: screenWidth,
                                          height: screenHeight / 2.35,
                                          child: Image.network(
                                            userProfile!.imageUrl ?? '',
                                            fit: BoxFit.cover,
                                          ),
                                        ),
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
                                                    AppColors.backgroundDefault
                                                        .withOpacity(0.7),
                                                    AppColors.backgroundDefault
                                                        .withOpacity(0.4),
                                                    AppColors.backgroundDefault
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
                                              height: screenHeight / 2.35 / 15,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    AppColors.backgroundDefault
                                                        .withOpacity(0),
                                                    AppColors.backgroundDefault
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
                                child: StreamBuilder<
                                    QuerySnapshot<Map<String, dynamic>>>(
                                  stream: sentRequestsStream,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      bool isInSentRequests =
                                          snapshot.data!.docs.any((doc) =>
                                              doc.data()["recipientUserId"] ==
                                              userId);
                                      if (isInSentRequests) {
                                        return _buildSentRequestWidget(() async {
                                          await friendSystem.deleteSentRequest(userId);
                                          setState(() {
                                            //    sentRequests.removeAt(index);
                                          });
                                        });
                                      } else {
                                        return StreamBuilder<
                                            QuerySnapshot<
                                                Map<String, dynamic>>>(
                                          stream: receivedRequestsStream,
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              bool isInReceivedRequests =
                                                  snapshot.data!.docs.any(
                                                      (doc) =>
                                                          doc.data()[
                                                              "senderUserId"] ==
                                                          userId);
                                              if (isInReceivedRequests) {
                                                return _buildReceivedRequestWidget();
                                              } else {
                                                return StreamBuilder<
                                                    QuerySnapshot<
                                                        Map<String, dynamic>>>(
                                                  stream: friendsStream,
                                                  builder: (context, snapshot) {
                                                    if (snapshot.hasData) {
                                                      bool areFriends = snapshot
                                                          .data!.docs
                                                          .any((doc) =>
                                                              doc.id == userId);
                                                      if (areFriends) {
                                                        return _buildFriendWidget();
                                                      } else {
                                                        return _nonFriends(
                                                            () async {
                                                          // Implement the send friend request action here
                                                          await sendFriendRequest(
                                                              userId);
                                                          setState(() {});
                                                        });
                                                      }
                                                    }
                                                    return SizedBox
                                                        .shrink(); // Return an empty widget if none of the conditions match
                                                  },
                                                );
                                              }
                                            }
                                            return SizedBox
                                                .shrink(); // Return an empty widget if none of the conditions match
                                          },
                                        );
                                      }
                                    }
                                    return SizedBox
                                        .shrink(); // Return an empty widget if none of the conditions match
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
                        return CircularProgressIndicator();
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
