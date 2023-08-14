import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gas/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gas/core/models/friends_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/cupertino.dart';
import 'core/ui/contact_widget.dart';
import 'core/ui/friend_widget.dart';
import 'core/ui/request_widget.dart';
import 'core/ui/sent_request_widget.dart';
import 'package:gas/friends_notifier.dart';
import 'package:gas/user_notifier.dart';
import 'core/models/user_model.dart';
import 'core/ui/mutual_friend_widget.dart';
import 'core/ui/general_user_widget.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  bool _searchBoxFocused = false;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  final FriendSystem friendSystem =
      FriendSystem(userId: FirebaseAuth.instance.currentUser?.uid ?? '');

  int _currentIndex = 0;
  int _lastIndex = 0;

  String _searchQuery = '';

  final List<String> _texts = [
    'Suggested',
    'Friends',
    'Requests',
  ];

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
  }

  Future<void> sendFriendRequest(String recipientUserId) async {
    try {
      await friendSystem.sendFriendRequest(
          recipientUserId, FirebaseAuth.instance.currentUser?.uid ?? '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request sent.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send friend request.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String friendToDeleteId = '';

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    final List<Widget> pages = [
      pageContactsNoFriend(),
      tryFriends(),
      requests()
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.backgroundDefault,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(left: 140),
                        child: Image.asset('assets/img/logo.png', height: 40),
                        width: 100,
                      ),
                      InkWell(
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 35,
                          color: AppColors.white,
                        ),
                        onTap: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          context.pop();
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.white,
                          ),
                          child: Focus(
                            child: TextField(
                              onTap: () {
                                _searchBoxFocused = true;
                                print("tap");
                              },
                              controller: _searchController,
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: _searchBoxFocused
                                      ? AppColors.brownShadow
                                      : AppColors.a,
                                ),
                                iconColor: AppColors.a,
                                border: InputBorder.none,
                                hintText: 'Add or search friends',
                                hintStyle: ref
                                    .watch(stylesProvider)
                                    .text
                                    .hintOnBoarding
                                    .copyWith(color: AppColors.a, fontSize: 16),
                              ),
                              style: ref
                                  .watch(stylesProvider)
                                  .text
                                  .hintOnBoarding
                                  .copyWith(
                                      color: AppColors.brown, fontSize: 16),
                              cursorColor: AppColors.brownShadow,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                            onFocusChange: (value) {
                              setState(() {
                                if (value) {
                                  //         _searchBoxFocused = true;
                                } else {
                                  //       _searchBoxFocused = false;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      Visibility(
                        visible: _searchBoxFocused,
                        child: FadeInRight(
                          duration: const Duration(milliseconds: 300),
                          controller: (controller) =>
                              _animationController = controller,
                          child: TextButton(
                            child: Text(
                              "Cancel",
                              style: ref
                                  .watch(stylesProvider)
                                  .text
                                  .editProfile
                                  .copyWith(fontSize: 18),
                            ),
                            onPressed: () {
                              setState(() {
                                FocusScope.of(context).unfocus();
                                _searchQuery = "";
                                _searchController.clear();
                                _searchBoxFocused = false;
                                print("close");
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 25,
                ),
                _searchController.text.length >= 1
                    ? Expanded(
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future:
                              friendSystem.combineResults(_searchQuery, ref),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final searchResults = snapshot.data!;
                              final widgets = <Widget>[];
                              String type = "";

                              // Build widgets for each result
                              for (final result in searchResults) {
                                final userData = result;
                                final username = userData['username'];
                                final profilePictureUrl = userData['imageUrl'];
                                final name = userData['name'];
                                final id = userData['id'];
                                final displayName =
                                    userData['displayName'] ?? "name";
                                final commonFriendsCount =
                                    userData['commonFriendsCount'] ?? 0;

                                final title = result['title'] as String?;

                                if (result['type'] != null) {
                                  type = result['type'];
                                } else if (title != null) {
                                  // Add title widget
                                  widgets.add(Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 20),
                                      child: Text(title,
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold))));
                                } else if (type == 'friends') {
                                  widgets.add(FriendWidget(
                                      profilePictureUrl: profilePictureUrl,
                                      name: name,
                                      username: username,
                                      id: id,
                                      onDeleteFriend: () async {
                                        await friendSystem.deleteFriend(friendToDeleteId);
                                        ref.refresh(friendsProvider);
                                        Navigator.pop(context);
                                      }, onNo: (){
                                    Navigator.pop(context);
                                  },
                                    onTap: () {
                                      setState(() {
                                        friendToDeleteId = id;
                                      });
                                    },));
                                } else if (type == 'sentRequest') {
                                  widgets.add(Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 20),
                                      child: SentRequestWidget(
                                          profilePictureUrl:
                                              profilePictureUrl ?? '',
                                          name: name ?? '',
                                          username: username ?? '',
                                          id: id,
                                          onDeleteSentRequest: () async {
                                            await friendSystem
                                                .deleteSentRequest(id);
                                            setState(() {
                                              //     sentRequests.removeAt(index);
                                              ref.refresh(sentRequestsProvider);
                                              ref.refresh(
                                                  nonFriendsContactsProvider);
                                            });
                                          })));
                                } else if (type == 'receivedRequest') {
                                  widgets.add(RequestWidget(
                                      profilePictureUrl: profilePictureUrl,
                                      name: name,
                                      username: username,
                                      id: id,
                                      onAcceptFriendRequest: () async {
                                        await friendSystem
                                            .acceptFriendRequest(id);
                                        ref.refresh(receivedRequestsProvider);
                                        ref.refresh(friendsProvider);
                                      },
                                      onDeleteSentRequest: () async {
                                        await friendSystem
                                            .declineFriendRequest(id);
                                        ref.refresh(receivedRequestsProvider);
                                        ref.refresh(nonFriendsContactsProvider);
                                      }));
                                } else if (type == 'contact') {
                                  widgets.add(Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 20),
                                      child: ContactWidget(
                                          profilePicture: profilePictureUrl,
                                          name: name,
                                          username: username,
                                          nameContact: displayName,
                                          id: id,
                                          onTap: () async {
                                            await sendFriendRequest(id);
                                            ref.refresh(sentRequestsProvider);
                                            ref.refresh(
                                                nonFriendsContactsProvider);
                                          })));
                                } else if (type == 'mutual') {
                                  final userData = result['userDoc']
                                      as DocumentSnapshot<Map<String, dynamic>>;
                                  final commonFriendsCount =
                                      result['commonFriendsCount'] as int;

                                  if (userData != null) {
                                    final name = userData['name'];
                                    final username = userData['username'];
                                    final profilePictureUrl =
                                        userData['imageUrl'];
                                    final id = userData['id'];

                                    widgets.add(Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20),
                                        child: MutualFriendWidget(
                                            profilePicture: profilePictureUrl,
                                            name: name,
                                            username: username,
                                            friendsInCommon: commonFriendsCount,
                                            id: id,
                                            onTap: () async {
                                              await sendFriendRequest(id);
                                              ref.refresh(sentRequestsProvider);
                                              ref.refresh(
                                                  potentialFriendsWithCommonFriendsProvider);
                                            })));
                                  }
                                } else if (type == 'general') {
                                  widgets.add(Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: GeneralUserWidget(
                                      profilePicture: profilePictureUrl,
                                      name: name,
                                      username: username,
                                      id: id,
                                      onTap: () async {
                                  await sendFriendRequest(id);
                                  ref.refresh(sentRequestsProvider);
                                  //rimuovi elemnto qui
                                  })));
                                }
                              }

                              return ListView(
                                children: widgets,
                              );
                            } else if (snapshot.hasError) {
                              print("ok");
                              return Text('Error: ${snapshot.error}');
                            } else {
                              return Padding(
                                  padding: EdgeInsets.only(
                                      bottom: screenHeight / 1.35),
                                  child: CupertinoActivityIndicator(
                                    radius: 15,
                                  ));
                            }
                          },
                        ),
                      )
                    : Expanded(
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            final tween = Tween<Offset>(
                              begin: Offset(
                                  _currentIndex > _lastIndex ? -1.0 : 1.0, 0.0),
                              end: Offset(0.0, 0.0),
                            );
                            return SlideTransition(
                              position: tween.animate(animation),
                              child: child,
                            );
                          },
                          child: pages[_currentIndex],
                        ),
                      )
              ],
            ),
            Visibility(
                visible: !_searchBoxFocused,
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                        padding:
                            EdgeInsets.only(left: 70, right: 70, bottom: 50),
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 1,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(
                              _texts.length,
                              (index) => GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () {
                                  setState(() {
                                    _lastIndex = _currentIndex;
                                    _currentIndex = index;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: _currentIndex == index
                                        ? Colors.blue.withOpacity(0.5)
                                        : Colors.transparent,
                                  ),
                                  child: Text(
                                    _texts[index],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _currentIndex == index
                                          ? Colors.blue
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ))))
          ],
        ),
      ),
    );
  }

  Widget pageContactsNoFriend() {
    double screenHeight = MediaQuery.of(context).size.height;

    return ListView(
      children: [
        // First FutureBuilder for non-friend contacts
        FutureBuilder(
          future: ref.watch(nonFriendsContactsProvider.future),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: EdgeInsets.only(bottom: screenHeight / 1.35),
                child: CupertinoActivityIndicator(
                  radius: 15,
                ),
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final registeredContacts = snapshot.data;

              if (registeredContacts != null && registeredContacts.length > 0) {
                return Column(
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'ADD YOUR CONTACTS',
                          style: TextStyle(
                            fontFamily: 'Helvetica',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: registeredContacts.length,
                      itemBuilder: (context, index) {
                        final userData = registeredContacts[index];

                        if (userData != null) {
                          final name = userData['name'];
                          final username = userData['username'];
                          final profilePicture = userData['imageUrl'];
                          final id = userData['id'];
                          final displayName = userData['displayName'];

                          return ContactWidget(
                            profilePicture: profilePicture,
                            name: name,
                            username: username,
                            nameContact: displayName ?? '',
                            id: id,
                            onTap: () async {
                              await sendFriendRequest(id);
                              ref.refresh(sentRequestsProvider);
                              setState(() {
                                registeredContacts.removeAt(index);
                              });
                            },
                          );
                        }
                      },
                    ),
                  ],
                );
              } else {
                return Container();
              }
            }
          },
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: ref.watch(potentialFriendsWithCommonFriendsProvider.future),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: CupertinoActivityIndicator(
                  radius: 15,
                ),
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final potentialFriends = snapshot.data;

              if (potentialFriends != null && potentialFriends.length > 0) {
                return Column(
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'PERSONE CHE POTRESTI CONOSCERE',
                          style: TextStyle(
                            fontFamily: 'Helvetica',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // ListView.builder for potential friends
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: potentialFriends.length,
                      itemBuilder: (context, index) {
                        final userData = potentialFriends[index]['userDoc']
                            as DocumentSnapshot<Map<String, dynamic>>;
                        final commonFriendsCount = potentialFriends[index]
                            ['commonFriendsCount'] as int;

                        if (userData != null) {
                          final name = userData['name'];
                          final username = userData['username'];
                          final profilePicture = userData['imageUrl'];
                          final id = userData['id'];

                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: MutualFriendWidget(
                              profilePicture: profilePicture,
                              name: name,
                              username: username,
                              friendsInCommon: commonFriendsCount,
                              id: id,
                              onTap: () async {
                                await sendFriendRequest(id);
                                ref.refresh(sentRequestsProvider);
                                ref.refresh(
                                    potentialFriendsWithCommonFriendsProvider);
                              },
                            ),
                          );
                        } else {
                          return Text('User data not found.');
                        }
                      },
                    ),
                  ],
                );
              } else {
                return Container();
              }
            }
          },
        ),
      ],
    );
  }

  Widget tryFriends() {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    final friendsAsyncValue = ref.watch(friendsProvider);

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            ref.refresh(friendsProvider);
          },
        ),
        SliverPadding(
          padding: EdgeInsets.only(right: 15, left: 15, top: 10, bottom: 9),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer(
                  builder: (context, watch, child) {
                    final friendsAsyncValue = ref.watch(friendsProvider);

                    return friendsAsyncValue.when(
                      data: (friends) {
                        final friendsCount = friends.length;
                        if (friends.length <= 50) {
                          return Text(
                            "MY FRIENDS ($friendsCount)",
                            style: TextStyle(
                              fontFamily: 'Helvetica',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        } else {
                          return Text(
                            "MY FRIENDS (50+)",
                            style: TextStyle(
                              fontFamily: 'Helvetica',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                      },
                      loading: () => Text(
                          "MY FRIENDS (0)"), // Default count when data is not available
                      error: (_, __) => Text("Error loading friends"),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
            child: friendsAsyncValue.when(
          data: (friends) {
            if (friends.isNotEmpty) {
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friendData = friends[index].data();
                  final friendId = friends[index].id;

                  return FutureBuilder(
                    future:
                        ref.watch(otherUserProfileProvider(friendId).future),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                            padding:
                                EdgeInsets.only(bottom: screenHeight / 1.35),
                            child: CupertinoActivityIndicator(
                              radius: 15,
                            ));
                      }

                      if (snapshot.hasError || !snapshot.hasData) {
                        return Text("Error fetching data.");
                      }

                      final UserModel? user = snapshot.data!;
                      final username = user!.username;
                      final profilePictureUrl = user.imageUrl!;
                      final name = user.name!;
                      final id = user.id!;

                      return FriendWidget(
                        profilePictureUrl: profilePictureUrl,
                        name: name,
                        username: username!,
                        id: id,
                          onDeleteFriend: () async {
                            await friendSystem.deleteFriend(friendToDeleteId);
                            ref.refresh(friendsProvider);
                            Navigator.pop(context);
                          }, onNo: () {
                        Navigator.pop(context);
                      },
                        onTap: () {
                          setState(() {
                            friendToDeleteId = id;
                          });
                        },
                      );
                    },
                  );
                },
              );
            } else {
              return Container(
                padding: EdgeInsets.symmetric(vertical: 50),
                margin: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.a,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Non hai ancora nessun amico'),
                    SizedBox(height: 20),
                    Text('Aggiungi nuovi amici!'),
                  ],
                ),
              );
            }
          },
          loading: () => Padding(
              padding: EdgeInsets.only(bottom: screenHeight / 1.35),
              child: CupertinoActivityIndicator(
                radius: 15,
              )),
          error: (_, __) => Text("Error loading friends"),
        )),
      ],
    );
  }

  Widget requests() {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    final receivedRequestsAsyncValue = ref.watch(receivedRequestsProvider);

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            ref.refresh(receivedRequestsProvider);
          },
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          sliver: SliverToBoxAdapter(
              child: Container(
            height: 35,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer(
                  builder: (context, watch, child) {
                    final receivedRequestsAsyncValue =
                        ref.watch(receivedRequestsProvider);

                    return receivedRequestsAsyncValue.when(
                      data: (receivedRequests) {
                        final requestCount = receivedRequests.length;
                        return Text(
                          "FRIEND REQUESTS ($requestCount)",
                          style: TextStyle(
                            fontFamily: 'Helvetica',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                      loading: () => Text(
                        "FRIEND REQUESTS (Loading...)",
                        style: TextStyle(
                          fontFamily: 'Helvetica',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      error: (error, stackTrace) => Text(
                        "FRIEND REQUESTS (Error)",
                        style: TextStyle(
                          fontFamily: 'Helvetica',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
                ElevatedButton(
                  onPressed: () => _showSentRequestsBottomSheet(context),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.transparent,
                    padding: EdgeInsets.only(left: 15, top: 5, bottom: 5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "SENT",
                        style: TextStyle(fontFamily: 'Helvetica'),
                      ),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ),
        SliverToBoxAdapter(
          child: receivedRequestsAsyncValue.when(
            data: (receivedRequests) {
              if (receivedRequests.isNotEmpty) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: receivedRequests.length,
                  itemBuilder: (context, index) {
                    final request = receivedRequests[index];
                    final senderUserId = request['senderUserId'] as String;

                    return FutureBuilder(
                      future: ref
                          .watch(otherUserProfileProvider(senderUserId).future),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Padding(
                              padding:
                                  EdgeInsets.only(bottom: screenHeight / 1.35),
                              child: CupertinoActivityIndicator(
                                radius: 15,
                              ));
                        }

                        if (snapshot.hasError) {
                          return Text("Error fetching data.");
                        }

                        final UserModel? user = snapshot.data!;
                        final username = user!.username;
                        final profilePictureUrl = user.imageUrl!;
                        final name = user.name!;
                        final id = user.id!;

                        return RequestWidget(
                          profilePictureUrl: profilePictureUrl,
                          name: name,
                          username: username!,
                          id: id,
                          onAcceptFriendRequest: () async {
                            await friendSystem
                                .acceptFriendRequest(senderUserId);
                            ref.refresh(receivedRequestsProvider);
                            ref.refresh(friendsProvider);
                          },
                          onDeleteSentRequest: () async {
                            await friendSystem
                                .declineFriendRequest(senderUserId);
                            ref.refresh(receivedRequestsProvider);
                          },
                        );
                      },
                    );
                  },
                );
              } else {
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  margin: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppColors.a,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Nessuna richiesta in attesa'),
                      SizedBox(height: 20),
                      Text('Aggiungi nuovi amici!'),
                    ],
                  ),
                );
              }
            },
            loading: () => Padding(
                padding: EdgeInsets.only(bottom: screenHeight / 1.35),
                child: CupertinoActivityIndicator(
                  radius: 15,
                )),
            error: (error, stackTrace) => Text("Error fetching data."),
          ),
        ),
      ],
    );
  }

  void _showSentRequestsBottomSheet(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

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
            return Consumer(
              builder: (context, ref, child) {
                final sentRequestsSnapshot = ref.watch(sentRequestsProvider);

                return sentRequestsSnapshot.when(
                  loading: () => Padding(
                      padding: EdgeInsets.only(bottom: screenHeight / 1.35),
                      child: CupertinoActivityIndicator(
                        radius: 15,
                      )),
                  error: (error, stackTrace) =>
                      Center(child: Text('Error: $error')),
                  data: (sentRequests) {
                    return CupertinoScrollbar(
                      child: SingleChildScrollView(
                        child: Container(
                          padding: EdgeInsets.all(16.0),
                          height: MediaQuery.of(context).size.height * 0.9,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(Icons.arrow_downward),
                                    SizedBox(width: 105),
                                    Text(
                                      'Sent Requests',
                                      style: TextStyle(
                                          fontFamily: 'Helvetica',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16.0),
                              Expanded(
                                child: CustomScrollView(
                                  slivers: [
                                    CupertinoSliverRefreshControl(
                                      onRefresh: () async {
                                        await Future.delayed(
                                            Duration(seconds: 1));
                                        ref.refresh(sentRequestsProvider);
                                      },
                                    ),
                                    SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final request = sentRequests[index];
                                          final recipientUserId =
                                              request['recipientUserId']
                                                  as String;

                                          return FutureBuilder(
                                            future: ref.watch(
                                                otherUserProfileProvider(
                                                        recipientUserId)
                                                    .future),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return CupertinoActivityIndicator();
                                              } else if (snapshot.hasError) {
                                                return Text(
                                                    'Error: ${snapshot.error}');
                                              } else if (!snapshot.hasData) {
                                                return Text(
                                                    'No data available.');
                                              } else {
                                                final UserModel? user =
                                                    snapshot.data!;
                                                final username = user!.username;
                                                final profilePictureUrl =
                                                    user.imageUrl!;
                                                final name = user.name!;
                                                final id = user.id!;

                                                return SentRequestWidget(
                                                  profilePictureUrl:
                                                      profilePictureUrl,
                                                  name: name,
                                                  username: username!,
                                                  id: id,
                                                  onDeleteSentRequest:
                                                      () async {
                                                    await friendSystem
                                                        .deleteSentRequest(
                                                            recipientUserId);
                                                    setState(() {
                                                      sentRequests
                                                          .removeAt(index);
                                                    });
                                                  },
                                                );
                                              }
                                            },
                                          );
                                        },
                                        childCount: sentRequests.length,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
