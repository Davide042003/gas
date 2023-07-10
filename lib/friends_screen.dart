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
      await friendSystem.sendFriendRequest(recipientUserId);
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

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(String phoneNumber) {
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

  @override
  void dispose() {
    super.dispose();
  }

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

    final List<Widget> pages = [
      pageContactsNoFriend(),
      myFriends(),
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
                  padding: EdgeInsets.symmetric(horizontal: 12),
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
                SizedBox(height: 10,),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
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
                                  color: _searchBoxFocused ? AppColors
                                      .brownShadow : AppColors.a,
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
                SizedBox(height: 25,),
                _searchQuery.isEmpty ? Expanded(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      transitionBuilder: (Widget child,
                          Animation<double> animation) {
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
                  ) : Container(),
              ],
            ),
            _searchQuery.isEmpty ? Align(alignment: Alignment.bottomCenter, child: Padding(
                padding: EdgeInsets.only(left: 70, right: 70, bottom: 50), child: Container(
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
                      (index) =>
                      GestureDetector(
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
            )
            )) : SizedBox()
          ],
        ),
      ),
    );
  }

  Widget pageContactsNoFriend() {
    double screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    final registeredContactsStream = Stream.fromFuture(friendSystem.getNonFriendsContacts());

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
                        fontSize: 18,
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
                      future: phoneNumber != null
                          ? getUserData(phoneNumber)
                          : null,
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
                                                  "" ? NetworkImage(
                                                  profilePicture) : null,
                                              child: profilePicture == ""
                                                  ? Text(name != ""
                                                  ? name[0]
                                                  : '', style: ref
                                                  .watch(stylesProvider)
                                                  .text
                                                  .titleOnBoarding
                                                  .copyWith(fontSize: 26),)
                                                  : null,
                                            ),
                                            SizedBox(width: 16,),
                                            Expanded(
                                              child: Container(
                                                color: Colors.transparent,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment
                                                      .start,
                                                  children: <Widget>[
                                                    Text(name ?? '', style: ref
                                                        .watch(stylesProvider)
                                                        .text
                                                        .contactOnBoarding,),
                                                    SizedBox(height: 6,),
                                                    Text(username ?? '',
                                                      style: ref
                                                          .watch(stylesProvider)
                                                          .text
                                                          .numberContactOnBoarding,),
                                                    SizedBox(height: 6,),
                                                    Row(
                                                      children: [
                                                        Icon(Icons
                                                            .account_circle_rounded,
                                                            size: 25),
                                                        SizedBox(width: 5,),
                                                        Text(contact
                                                            .displayName ?? '',
                                                          style: ref
                                                              .watch(
                                                              stylesProvider)
                                                              .text
                                                              .numberContactOnBoarding,),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(height: screenHeight / 30,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              final recipientUserId = userSnapshot
                                                  .data?.id;
                                              if (recipientUserId != null) {
                                                await sendFriendRequest(
                                                    recipientUserId);
                                                setState(() {
                                                  registeredContacts.removeAt(
                                                      index);
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
                                            child: const Text("ADD"),))
                                    ],
                                  ),
                                )
                            );
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
          }else{
            return Container();
          }
        }
      },
    );
  }
  Widget myFriends(){
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: friendSystem.getFriends(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final friends = snapshot.data!.docs;

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friendData = friends[index].data();
              final friendId = friends[index].id;
              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(friendId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.hasData) {
                    final userData = userSnapshot.data!.data();
                    final profilePicture = userData!['imageUrl'] as String?;
                    final name = userData['name'];
                    final username = userData['username'];

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 70,
                        backgroundImage: profilePicture != ""
                            ? NetworkImage(
                            profilePicture ?? '')
                            : null,
                        child: profilePicture == ""
                            ? Text(name != ""
                            ? name[0]
                            : '', style: ref
                            .watch(stylesProvider)
                            .text
                            .titleOnBoarding
                            .copyWith(fontSize: 50),)
                            : null,
                      ),
                      title: Text(name ?? ''),
                      subtitle: Text(username ?? ''),
                    );
                  } else if (userSnapshot.hasError) {
                    return Text('Error: ${userSnapshot.error}');
                  }

                  return ListTile(
                    title: Text('Loading...'),
                  );
                },
              );
            },
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
  Widget requests() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _showSentRequestsBottomSheet(context),
          child: Text('View Sent Requests'),
        ),
        SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: friendSystem.getReceivedRequests(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final receivedRequests = snapshot.data!.docs;

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
                          final user = snapshot.data!.data() as Map<String, dynamic>;
                          final username = user['username'] as String;
                          final profilePictureUrl = user['profilePictureUrl'] as String;
                          final name = user['name'] as String;

                          return ListTile(
                            leading: CircleAvatar(
                              // Display the profile picture
                              backgroundImage: NetworkImage(profilePictureUrl),
                            ),
                            title: Text(username), // Display the username
                            subtitle: Text(name), // Display the name
                            trailing: ElevatedButton(
                              onPressed: () {},
                              child: Text('Accept'),
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
    );
  }
  void _showSentRequestsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: friendSystem.getSentRequests(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final sentRequests = snapshot.data!.docs;

              return ListView.builder(
                itemCount: sentRequests.length,
                itemBuilder: (context, index) {
                  final request = sentRequests[index];
                  final recipientUserId = request['recipientUserId'] as String;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(recipientUserId)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final user = snapshot.data!.data() as Map<String, dynamic>;
                        final username = user['username'] as String;
                        final profilePictureUrl = user['imageUrl'] as String;
                        final name = user['name'] as String;

                        return ListTile(
                          leading: CircleAvatar(
                            // Display the profile picture
                            backgroundImage: NetworkImage(profilePictureUrl),
                          ),
                          title: Text(username), // Display the username
                          subtitle: Text(name), // Display the name
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
        );
      },
    );
  }
}
