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

class FriendsScreen extends ConsumerStatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  bool _searchBoxFocused = false;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  String id = FirebaseAuth.instance.currentUser?.uid ?? '';
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

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(
      String phoneNumber) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.size > 0) {
        return querySnapshot.docs.first;
      } else {
        throw Exception('User data not found.');
      }
    });
  }

  bool isLoading = false;
  String friendToDeleteId = '';
  void showDialogWithChoices() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Choose an option'),
          content: Text('Your friend will not see you anymore'),
          actions: [
            CupertinoDialogAction(
              child: Text('Annulla'),
              onPressed: () {
                setState(() {
                  isLoading = false;
                });
                Navigator.pop(context);
              },
            ),
            CupertinoDialogAction(
              child: Text('Elimina'),
              onPressed: () {
                setState(() {
                  isLoading = false;
                });
                friendSystem.deleteFriend(friendToDeleteId);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

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
                                  _searchBoxFocused = true;
                                } else {
                                  _searchController.clear();
                                  _searchBoxFocused = false;
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
                _searchQuery.isEmpty
                    ? Expanded(
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
                    : Expanded(
                  child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                    stream: friendSystem.searchUsers(_searchQuery, id),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final users = snapshot.data!;
                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final userData = users[index].data();
                            return ListTile(
                              title: Text(userData['username']),
                              subtitle: Text(userData['name']),
                              // Add any other user information you want to display
                              onTap: () {
                                // Handle tapping on a user
                                // e.g., send a friend request, navigate to user profile, etc.
                              },
                            );
                          },
                        );
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  ),
                )
              ],
            ),
            _searchQuery.isEmpty
                ? Align(
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
                        )))
                : SizedBox()
          ],
        ),
      ),
    );
  }

  Widget pageContactsNoFriend() {
    double screenHeight = MediaQuery.of(context).size.height;

    final registeredContactsStream =
        Stream.fromFuture(friendSystem.getNonFriendsContacts());

    return StreamBuilder<List<Contact>>(
      stream: registeredContactsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final registeredContacts = snapshot.data ?? [];

          if (registeredContacts.length > 0) {
            return ListView(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ADD YOUR CONTACTS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                AnimatedList(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  // Disable list scrolling
                  initialItemCount: registeredContacts.length,
                  itemBuilder: (context, index, animation) {
                    final contact = registeredContacts[index];
                    final phoneNumber = contact.phones?.firstOrNull?.value;

                    return FutureBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      future:
                          phoneNumber != null ? getUserData(phoneNumber) : null,
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (userSnapshot.hasError) {
                          return Text('Error: ${userSnapshot.error}');
                        } else {
                          final userData = userSnapshot.data?.data();
                          if (userData != null) {
                            final name = userData['name'];
                            final username = userData['username'];
                            final profilePicture = userData['imageUrl'];

                            return SizeTransition(
                                sizeFactor: animation,
                                child: Container(
                                  padding: EdgeInsets.only(
                                      left: 20, right: 20, top: 13, bottom: 13),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Row(
                                          children: <Widget>[
                                            CircleAvatar(
                                              maxRadius: 38,
                                              backgroundImage: profilePicture !=
                                                      ""
                                                  ? NetworkImage(profilePicture)
                                                  : null,
                                              child: profilePicture == ""
                                                  ? Text(
                                                      name != "" ? name[0] : '',
                                                      style: ref
                                                          .watch(stylesProvider)
                                                          .text
                                                          .titleOnBoarding
                                                          .copyWith(
                                                              fontSize: 26),
                                                    )
                                                  : null,
                                            ),
                                            SizedBox(
                                              width: 16,
                                            ),
                                            Expanded(
                                              child: Container(
                                                color: Colors.transparent,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                      name ?? '',
                                                      style: ref
                                                          .watch(stylesProvider)
                                                          .text
                                                          .contactOnBoarding,
                                                    ),
                                                    SizedBox(
                                                      height: 6,
                                                    ),
                                                    Text(
                                                      username ?? '',
                                                      style: ref
                                                          .watch(stylesProvider)
                                                          .text
                                                          .numberContactOnBoarding,
                                                    ),
                                                    SizedBox(
                                                      height: 6,
                                                    ),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                            Icons
                                                                .account_circle_rounded,
                                                            size: 25),
                                                        SizedBox(
                                                          width: 5,
                                                        ),
                                                        Text(
                                                          contact.displayName ??
                                                              '',
                                                          style: ref
                                                              .watch(
                                                                  stylesProvider)
                                                              .text
                                                              .numberContactOnBoarding,
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                          height: screenHeight / 30,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              final recipientUserId =
                                                  userSnapshot.data?.id;
                                              if (recipientUserId != null) {
                                                await sendFriendRequest(
                                                    recipientUserId);
                                                setState(() {
                                                  registeredContacts
                                                      .removeAt(index);
                                                });
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Recipient user ID not found.'),
                                                    duration: const Duration(
                                                        seconds: 2),
                                                  ),
                                                );
                                              }
                                            },
                                            style: ref
                                                .watch(stylesProvider)
                                                .button
                                                .buttonInvite,
                                            child: const Text("ADD"),
                                          ))
                                    ],
                                  ),
                                ));
                          } else {
                            return Text('User data not found.');
                          }
                        }
                      },
                    );
                  },
                ),
              ],
            );
          } else {
            return Container();
          }
        }
      },
    );
  }

  Widget tryFriends() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Align(
              alignment: Alignment.centerLeft,
              child: StreamBuilder<QuerySnapshot>(
                stream: friendSystem.getFriends(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final friends = snapshot.data!.docs;
                    final friendsCount = friends.length;

                    if (friends.length <= 50) {
                      return Text(
                        "MY FRIENDS ($friendsCount)",
                      );
                    } else {
                      return Text("MY FRIENDS (50+)");
                    }
                  }

                  return Text(
                      "MY FRIENDS (0)"); // Default count when data is not available
                },
              )),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
          stream: friendSystem.getFriends(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final friends = snapshot.data!.docs;

                  if (friends.length > 0) {
                    //sort by username in alphabetical order
                    friends.sort((a, b) {
                      final friendDataA = (a.data() as Map<String, dynamic>);
                      final friendDataB = (b.data() as Map<String, dynamic>);
                      final usernameA = friendDataA['username'] as String;
                      final usernameB = friendDataB['username'] as String;
                      return usernameA.compareTo(usernameB);
                    });
                    return ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friendData = friends[index].data();
                        final friendId = friends[index].id;

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(friendId)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final user = snapshot.data!.data() as Map<String, dynamic>;
                              final username = user['username'] as String;
                              final profilePictureUrl =
                              user['imageUrl'] as String;
                              final name = user['name'] as String;

                              return Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Row(
                                          children: <Widget>[
                                            CircleAvatar(
                                              maxRadius: 38,
                                              backgroundImage:
                                              profilePictureUrl != ""
                                                  ? NetworkImage(
                                                  profilePictureUrl)
                                                  : null,
                                              child: profilePictureUrl == ""
                                                  ? Text(
                                                name != "" ? name[0] : '',
                                                style: ref
                                                    .watch(stylesProvider)
                                                    .text
                                                    .titleOnBoarding
                                                    .copyWith(fontSize: 26),
                                              )
                                                  : null,
                                            ),
                                            SizedBox(
                                              width: 16,
                                            ),
                                            Expanded(
                                              child: Container(
                                                color: Colors.transparent,
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                      name ?? '',
                                                      style: ref
                                                          .watch(stylesProvider)
                                                          .text
                                                          .contactOnBoarding,
                                                    ),
                                                    SizedBox(
                                                      height: 6,
                                                    ),
                                                    Text(
                                                      username ?? '',
                                                      style: ref
                                                          .watch(stylesProvider)
                                                          .text
                                                          .numberContactOnBoarding,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 10),

                                      InkWell(
                                        onTap: ()  {
                                          setState(() {
                                            friendToDeleteId = friendId;
                                            isLoading = true;
                                          });
                                          showDialogWithChoices();
                                        },
                                        child: isLoading
                                            ? CircularProgressIndicator() : Icon(
                                          Icons.close_rounded,
                                          size: 25,
                                          color: AppColors.a,
                                        ),
                                      ),
                                    ],
                                  ));
                            }

                            return CircularProgressIndicator();
                          },
                        );
                      },
                    );
                  } else {
                    return Container(
                        margin: EdgeInsets.only(
                            top: 25, bottom: 450, left: 25, right: 25),
                        width: 400,
                        height: 50,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            color: AppColors.a),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Non hai ancora nessun amico!'),
                            SizedBox(height: 20),
                            Text('Aggiungi nuovi amici!'),
                          ],
                        ));
                  }
                }

                return CircularProgressIndicator();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget requests() {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: friendSystem.getReceivedRequests(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final receivedRequests = snapshot.data!.docs;
                        final requestCount = receivedRequests.length;

                        return Text("FRIEND REQUESTS ($requestCount)");
                      }

                      return Text(
                          "FRIEND REQUESTS (0)"); // Default count when data is not available
                    },
                  ),
                  ElevatedButton(
                    onPressed: () => _showSentRequestsBottomSheet(context),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.transparent, // Remove background color
                      padding: EdgeInsets.only(
                          left: 15, top: 5, bottom: 5), // Remove padding
                      elevation: 0, // Remove elevation
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            8), // Set your desired border radius
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text("SENT"), // Label
                        const SizedBox(width: 5),
                        Icon(Icons.arrow_forward_ios), // Icon
                      ],
                    ),
                  )
                ])),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: friendSystem.getReceivedRequests(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final receivedRequests = snapshot.data!.docs;

                if (receivedRequests.length > 0) {
                  return ListView.builder(
                    itemCount: receivedRequests.length,
                    itemBuilder: (context, index) {
                      final request = receivedRequests[index];
                      final senderUserId = request['senderUserId'] as String;

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(senderUserId)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final user =
                                snapshot.data!.data() as Map<String, dynamic>;
                            final username = user['username'] as String;
                            final profilePictureUrl =
                                user['imageUrl'] as String;
                            final name = user['name'] as String;

                            return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 13,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Row(
                                        children: <Widget>[
                                          CircleAvatar(
                                            maxRadius: 38,
                                            backgroundImage:
                                                profilePictureUrl != ""
                                                    ? NetworkImage(
                                                        profilePictureUrl)
                                                    : null,
                                            child: profilePictureUrl == ""
                                                ? Text(
                                                    name != "" ? name[0] : '',
                                                    style: ref
                                                        .watch(stylesProvider)
                                                        .text
                                                        .titleOnBoarding
                                                        .copyWith(fontSize: 26),
                                                  )
                                                : null,
                                          ),
                                          SizedBox(
                                            width: 16,
                                          ),
                                          Expanded(
                                            child: Container(
                                              color: Colors.transparent,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    name ?? '',
                                                    style: ref
                                                        .watch(stylesProvider)
                                                        .text
                                                        .contactOnBoarding,
                                                  ),
                                                  SizedBox(
                                                    height: 6,
                                                  ),
                                                  Text(
                                                    username ?? '',
                                                    style: ref
                                                        .watch(stylesProvider)
                                                        .text
                                                        .numberContactOnBoarding,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await friendSystem
                                            .acceptFriendRequest(senderUserId);
                                      },
                                      style: ref
                                          .watch(stylesProvider)
                                          .button
                                          .buttonInvite,
                                      child: const Text("ACCEPT"),
                                    ),
                                    SizedBox(width: 10),
                                    InkWell(
                                      onTap: () async {
                                        // await friendSystem.deleteSentRequest(recipientUserId);
                                        setState(() {
                                          // sentRequests.removeAt(index);
                                        });
                                      },
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 25,
                                        color: AppColors.a,
                                      ),
                                    ),
                                  ],
                                ));
                          }

                          return CircularProgressIndicator();
                        },
                      );
                    },
                  );
                } else {
                  return Container(
                      margin: EdgeInsets.only(
                          top: 25, bottom: 450, left: 25, right: 25),
                      width: 400,
                      height: 50,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          color: AppColors.a),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Nessuna richiesta in attesa'),
                          SizedBox(height: 20),
                          Text('Aggiungi nuovi amici!'),
                        ],
                      ));
                }
              }

              return CircularProgressIndicator();
            },
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
            return SingleChildScrollView(
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
                          SizedBox(
                            width: 100,
                          ),
                          Text('Sent Requests'),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.0),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: friendSystem.getSentRequests(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final sentRequests = snapshot.data!.docs;

                            return ListView.builder(
                              itemCount: sentRequests.length,
                              itemBuilder: (context, index) {
                                final request = sentRequests[index];
                                final recipientUserId =
                                    request['recipientUserId'] as String;

                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(recipientUserId)
                                      .get(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      final user = snapshot.data!.data()
                                          as Map<String, dynamic>;
                                      final username =
                                          user['username'] as String;
                                      final profilePictureUrl =
                                          user['imageUrl'] as String;
                                      final name = user['name'] as String;
                                      bool isDismissed = true;

                                      return Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 0,
                                          vertical: 13,
                                        ),
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Row(
                                                children: <Widget>[
                                                  CircleAvatar(
                                                    maxRadius: 38,
                                                    backgroundImage:
                                                        profilePictureUrl != ""
                                                            ? NetworkImage(
                                                                profilePictureUrl)
                                                            : null,
                                                    child:
                                                        profilePictureUrl == ""
                                                            ? Text(
                                                                name != ""
                                                                    ? name[0]
                                                                    : '',
                                                                style: ref
                                                                    .watch(
                                                                        stylesProvider)
                                                                    .text
                                                                    .titleOnBoarding
                                                                    .copyWith(
                                                                        fontSize:
                                                                            26),
                                                              )
                                                            : null,
                                                  ),
                                                  SizedBox(
                                                    width: 16,
                                                  ),
                                                  Expanded(
                                                    child: Container(
                                                      color: Colors.transparent,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: <Widget>[
                                                          Text(
                                                            name ?? '',
                                                            style: ref
                                                                .watch(
                                                                    stylesProvider)
                                                                .text
                                                                .contactOnBoarding,
                                                          ),
                                                          SizedBox(
                                                            height: 6,
                                                          ),
                                                          Text(
                                                            username ?? '',
                                                            style: ref
                                                                .watch(
                                                                    stylesProvider)
                                                                .text
                                                                .numberContactOnBoarding,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              height: screenHeight / 27,
                                              width: screenWidth / 5,
                                              child:
                                                  Center(child: Text("ADDED")),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(20)),
                                                color: AppColors.a,
                                              ),
                                            ),
                                            SizedBox(width: 15),
                                            InkWell(
                                              onTap: () async {
                                                await friendSystem
                                                    .deleteSentRequest(
                                                        recipientUserId);
                                                setState(() {
                                                  sentRequests.removeAt(index);
                                                });
                                              },
                                              child: Icon(
                                                Icons.close_rounded,
                                                size: 25,
                                                color: AppColors.a,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return CircularProgressIndicator();
                                  },
                                );
                              },
                            );
                          }

                          return CircularProgressIndicator();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
