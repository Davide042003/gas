import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gas/styles/colors.dart';
import 'package:gas/core/ui/anon_appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:ionicons/ionicons.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/models/post_service.dart';
import 'core/models/post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'core/models/answer_post_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Color color = AppColors.backgroundDefault;
  final String? userId = FirebaseAuth.instance.currentUser!.uid;
  final PostService postService =
      PostService(userId: FirebaseAuth.instance.currentUser!.uid);

  late PageController _pageController;
  int totalPosts = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset the background color every time the page is displayed
    color = AppColors.backgroundDefault; // Set the initial background color
  }

  void goToNextPage() {
    int nextPage = _pageController.page!.toInt() + 1;
    if (nextPage < totalPosts) {
      _pageController.animateToPage(nextPage,
          duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> clickAnswer(int indexAnswer, String postId, String idUserPost, bool isAnonymous) async {
    await postService.addAnswerToPost(postId, AnswerPostModel(
      id: userId,
      isAnonymous: isAnonymous,
      timestamp: Timestamp.now(),
    ), idUserPost, indexAnswer);

    print("answered");
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
        backgroundColor: color,
        body: Stack(
          children: [
            Container(
              width: screenWidth,
              height: screenHeight,
              child: FutureBuilder<List<PostModel>>(
                future: postService.getFriendsPosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData) {
                    final friendPosts = snapshot.data!;
                    totalPosts = friendPosts.length;
                    if (friendPosts.length > 0) {
                      return PageView(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          physics: NeverScrollableScrollPhysics(),
                          children: List.generate(friendPosts.length, (index) {
                            final post = friendPosts[index];
                            final friendUserId = post.id as String;

                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(friendUserId)
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final user = snapshot.data!.data()
                                      as Map<String, dynamic>;
                                  final username = user['username'] as String;
                                  final profilePictureUrl =
                                      user['imageUrl'] as String;
                                  final name = user['name'] as String;
                                  final timestamp =
                                      user['timeStamp'] as Timestamp;
                                  final id =
                                  user['id'] as String;
                                  final localDateTime =
                                      post.timestamp!.toDate().toLocal();
                                  final hour = localDateTime.hour
                                      .toString()
                                      .padLeft(2, '0');
                                  final minute = localDateTime.minute
                                      .toString()
                                      .padLeft(2, '0');

                                  int randomColor = Random().nextInt(5);

                                  return Container(
                                    color: index == 0 ? AppColors.backgroundDefault: AppColors.backgroundColors[randomColor],
                                      child: Padding(
                                    padding: EdgeInsets.only(
                                        right: 20,
                                        left: 20,
                                        top: screenHeight / 3.75),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: <Widget>[
                                            post.isAnonymous!
                                                ? CircleAvatar(
                                                    maxRadius: 25,
                                                    backgroundImage: null,
                                                    child:
                                                        Icon(Icons.hide_image),
                                                  )
                                                : CircleAvatar(
                                                    maxRadius: 25,
                                                    backgroundImage:
                                                        profilePictureUrl
                                                                .isEmpty
                                                            ? null
                                                            : NetworkImage(
                                                                profilePictureUrl),
                                                    child: profilePictureUrl
                                                            .isEmpty
                                                        ? Text(
                                                            name.isNotEmpty
                                                                ? name[0]
                                                                : '',
                                                            style: TextStyle(
                                                                fontFamily:
                                                                    'Helvetica',
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 20,
                                                                color: AppColors
                                                                    .white),
                                                          )
                                                        : SizedBox(),
                                                  ),
                                            SizedBox(width: 16),
                                            Expanded(
                                              child: Container(
                                                color: Colors.transparent,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                      post.isAnonymous!
                                                          ? "? ? ? ? ? ? "
                                                          : username ?? '',
                                                      style: TextStyle(
                                                        fontFamily: 'Helvetica',
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontSize: 20,
                                                        color: AppColors.white,
                                                      ),
                                                    ),
                                                    SizedBox(height: 2),
                                                    Text(
                                                      "$hour:$minute",
                                                      style: TextStyle(
                                                        fontFamily: 'Helvetica',
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontSize: 18,
                                                        color: AppColors
                                                            .whiteShadow,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 45,
                                              height: 45,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColors.whiteShadow55,
                                              ),
                                              child: Icon(
                                                Ionicons.chatbubble,
                                                color: AppColors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 40),
                                        Text(
                                          post.question!,
                                          style: TextStyle(
                                            fontFamily: 'Helvetica',
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.white,
                                            fontSize: 24,
                                          ),
                                        ),
                                        SizedBox(height: 30),
                                        post.images!.length == 2
                                            ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  GestureDetector(
                                                    child: Container(
                                                      width: screenWidth / 2.3,
                                                      height: screenHeight / 4,
                                                      decoration: BoxDecoration(
                                                        image: post.images![
                                                                    0] !=
                                                                null
                                                            ? DecorationImage(
                                                                image: NetworkImage(
                                                                    post.images![
                                                                        0]),
                                                                fit: BoxFit
                                                                    .cover)
                                                            : null,
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      // Add your content for the first white container here
                                                    ),
                                                    behavior: HitTestBehavior
                                                        .translucent,
                                                    onTap: () async {
                                                      await clickAnswer(0, post.postId!, friendUserId, false);
                                                    },
                                                  ),
                                                  GestureDetector(
                                                    child: Container(
                                                      width: screenWidth / 2.3,
                                                      height: screenHeight / 4,
                                                      decoration: BoxDecoration(
                                                        image: post.images![
                                                                    1] !=
                                                                null
                                                            ? DecorationImage(
                                                                image: NetworkImage(
                                                                    post.images![
                                                                        1]),
                                                                fit: BoxFit
                                                                    .cover)
                                                            : null,
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      // Add your content for the second white container here
                                                    ),
                                                    behavior: HitTestBehavior
                                                        .translucent,
                                                    onTap: () {},
                                                  ),
                                                ],
                                              )
                                            : SizedBox(),
                                      ],
                                    ),
                                  ));
                                }
                                return CircularProgressIndicator();
                              },
                            );
                          }));
                    } else {
                      return Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.only(top: screenHeight / 4.5),
                          child: Text('No posts available'),
                        ),
                      );
                    }
                  } else {
                    return Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.only(top: screenHeight / 4.5),
                        child: Text('No posts available'),
                      ),
                    );
                  }
                },
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            "Chat",
                            style: ref.watch(stylesProvider).text.appBarHome,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 25),
                          child: Image.asset('assets/img/logo.png', height: 40),
                          width: 100,
                        ),
                        TextButton(
                          onPressed: () {
                            context.push('/profile');
                          },
                          child: Text(
                            "Profile",
                            style: ref.watch(stylesProvider).text.appBarHome,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                          width: screenWidth / 3,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          InkWell(
                            child: Icon(
                              Icons.people_rounded,
                              size: 32,
                              color: AppColors.white,
                            ),
                            onTap: () {
                              context.push("/contact");
                            },
                          ),
                          SizedBox(
                            width: screenWidth / 7,
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "My Friends",
                              style: ref
                                  .watch(stylesProvider)
                                  .text
                                  .numberContactOnBoarding
                                  .copyWith(color: AppColors.white),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "Global",
                              style: ref
                                  .watch(stylesProvider)
                                  .text
                                  .numberContactOnBoarding,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: screenHeight / 1.45,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              InkWell(
                                child: Icon(
                                  Icons.remove_red_eye,
                                  size: 35,
                                  color: AppColors.white,
                                ),
                                onTap: () {
                                  context.pop();
                                },
                              ),
                              SizedBox(
                                height: screenHeight / 200,
                              ),
                              Text(
                                "ANONYMOUS",
                                style: ref.watch(stylesProvider).text.invite,
                              ),
                            ],
                          ),
                          Spacer(),
                          ElevatedButton.icon(
                            icon: Icon(
                              Ionicons.play,
                              color: AppColors.white,
                              size: 28,
                            ),
                            onPressed: goToNextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.transparent,
                              elevation: 0,
                            ),
                            label: Text(
                              "Skip",
                              style: ref.watch(stylesProvider).text.skipHome,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}
