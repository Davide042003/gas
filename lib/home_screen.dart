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
import 'post_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Color color = AppColors.backgroundDefault;
  final String? userId = FirebaseAuth.instance.currentUser!.uid;
  final PostService postService =
      PostService(userId: FirebaseAuth.instance.currentUser!.uid);

  bool hasVoted = false;
  late PageController _pageController;
  int totalPosts = 0;
  String postId = "";
  List<dynamic> answersCount = [];
  int totalAnswers = 0;

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

  Future<void> goToNextPage() async {
    await postService.markPostAsSeen(postId);

    int nextPage = _pageController.page!.toInt() + 1;
    if (nextPage < totalPosts) {
      _pageController.animateToPage(nextPage,
          duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void goToNextPageTapToContinue() {
    int nextPage = _pageController.page!.toInt() + 1;
    if (nextPage < totalPosts) {
      _pageController.animateToPage(nextPage,
          duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    }

    setState(() {
      hasVoted = false;
    });
  }

  Future<void> clickAnswer(int indexAnswer, String postId, String idUserPost,
      bool isAnonymous, bool answers2) async {
    await postService.addAnswerToPost(
        postId,
        AnswerPostModel(
          id: userId,
          isAnonymous: isAnonymous,
          timestamp: Timestamp.now(),
        ),
        idUserPost,
        indexAnswer);

 //   await postService.markPostAsSeen(postId);

    if (answers2 == true) {
      await fetchAnswersCounts(postService, postId, idUserPost, 2);
      totalAnswers = answersCount.reduce((a, b) => a + b);

      answersCount =
          answersCount.map((element) => element / totalAnswers).toList();
      print(answersCount);
    }else{
      await fetchAnswersCounts(postService, postId, idUserPost, 3);
      totalAnswers = answersCount.reduce((a, b) => a + b);

      answersCount =
          answersCount.map((element) => element / totalAnswers).toList();

      print(answersCount);
    }

    setState(() {
      hasVoted = true;
    });
  }

  Future<void> fetchAnswersCounts(PostService postService, String postId,
      String idUserPost, int maxInnerListIndex) async {
    final Map<int, int> answersCountsMap = {};

    for (int i = 0; i < maxInnerListIndex; i++) {
      int count =
          await postService.getAnswersLengthByIndex(postId, idUserPost, i);
      answersCountsMap[i] = count;
    }

    answersCount.clear();
    for (int i = 0; i < maxInnerListIndex; i++) {
      int count = answersCountsMap[i] ?? 0;
      answersCount.add(count);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    print("sign out");
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
              child: Consumer(
                builder: (context, watch, _) {
                  final friendPostsAsync = ref.watch(friendPostsProvider);
                  return friendPostsAsync.when(
                    data: (friendPosts) {
                      if (friendPosts.isNotEmpty) {
                        totalPosts = friendPosts.length;
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
                                    postId = post.postId!;

                                    final user = snapshot.data!.data()
                                    as Map<String, dynamic>;
                                    final username = user['username'] as String;
                                    final profilePictureUrl =
                                    user['imageUrl'] as String;
                                    final name = user['name'] as String;
                                    final timestamp =
                                    user['timestamp'] as Timestamp;
                                    final id = user['id'] as String;
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
                                        color: index == 0
                                            ? AppColors.backgroundDefault
                                            : AppColors
                                            .backgroundColors[randomColor],
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
                                                    child: Icon(
                                                        Icons.hide_image),
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
                                                          fontSize:
                                                          20,
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
                                                        CrossAxisAlignment
                                                            .start,
                                                        children: <Widget>[
                                                          Text(
                                                            post.isAnonymous!
                                                                ? "? ? ? ? ? ? "
                                                                : username ?? '',
                                                            style: TextStyle(
                                                              fontFamily:
                                                              'Helvetica',
                                                              fontWeight:
                                                              FontWeight.w400,
                                                              fontSize: 20,
                                                              color:
                                                              AppColors.white,
                                                            ),
                                                          ),
                                                          SizedBox(height: 2),
                                                          Text(
                                                            "$hour:$minute",
                                                            style: TextStyle(
                                                              fontFamily:
                                                              'Helvetica',
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
                                                      color:
                                                      AppColors.whiteShadow55,
                                                    ),
                                                    child: Icon(
                                                      Ionicons.chatbubble,
                                                      color: AppColors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: post.images!.length == 2 ? 40 : post.answersList!.length == 2 ? 120 : 80),
                                              Text(
                                                post.question!,
                                                style: TextStyle(
                                                  fontFamily: 'Helvetica',
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.white,
                                                  fontSize: 24,
                                                ),
                                              ),
                                              SizedBox(height: post.images!.length == 2 ? 30 : post.answersList!.length == 2 ? 70 : 40),
                                              post.images!.length == 2
                                                  ? Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceEvenly,
                                                children: [
                                                  Column(
                                                    children: [
                                                      GestureDetector(
                                                        child: Stack(
                                                            alignment: Alignment.bottomCenter,
                                                            children: [
                                                              Container(
                                                                width:
                                                                screenWidth /
                                                                    2.3,
                                                                height:
                                                                screenHeight /
                                                                    4,
                                                                decoration:
                                                                BoxDecoration(
                                                                  image: post.images![0] !=
                                                                      null
                                                                      ? DecorationImage(
                                                                      image: NetworkImage(post.images![0]),
                                                                      fit: BoxFit.cover)
                                                                      : null,
                                                                  color: Colors
                                                                      .white,
                                                                  borderRadius:
                                                                  BorderRadius.circular(
                                                                      20),
                                                                ),
                                                              ),
                                                              AnimatedContainer(
                                                                duration: Duration(seconds: 1),
                                                                curve: Curves.easeInOut,
                                                                width: screenWidth / 2.3,
                                                                height: hasVoted ? (screenHeight / 4) * answersCount[0] : 0,
                                                                decoration: BoxDecoration(
                                                                  color: AppColors.fadeImageAnswer.withOpacity(.61),
                                                                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                                                                ),
                                                              ),
                                                            ]),
                                                        behavior:
                                                        HitTestBehavior
                                                            .translucent,
                                                        onTap: () async {
                                                          hasVoted ? null : await clickAnswer(
                                                              0,
                                                              post.postId!,
                                                              friendUserId,
                                                              false,
                                                              true);
                                                        },
                                                      ),
                                                      SizedBox(
                                                        height:
                                                        screenHeight /
                                                            50,
                                                      ),
                                                      hasVoted
                                                          ? Text(
                                                        "${(answersCount[0] * 100).round()}%",
                                                        style: TextStyle(
                                                            fontFamily:
                                                            'Helvetica',
                                                            fontWeight:
                                                            FontWeight
                                                                .bold,
                                                            fontSize:
                                                            20,
                                                            color: AppColors
                                                                .white),
                                                      )
                                                          : SizedBox()
                                                    ],
                                                  ),
                                                  Column(
                                                    children: [
                                                      GestureDetector(
                                                        child: Stack(
                                                            alignment: Alignment.bottomCenter,
                                                            children: [
                                                              Container(
                                                                width:
                                                                screenWidth /
                                                                    2.3,
                                                                height:
                                                                screenHeight /
                                                                    4,
                                                                decoration:
                                                                BoxDecoration(
                                                                  image: post.images![0] !=
                                                                      null
                                                                      ? DecorationImage(
                                                                      image: NetworkImage(post.images![0]),
                                                                      fit: BoxFit.cover)
                                                                      : null,
                                                                  color: Colors
                                                                      .white,
                                                                  borderRadius:
                                                                  BorderRadius.circular(
                                                                      20),
                                                                ),
                                                              ),
                                                              AnimatedContainer(
                                                                duration: Duration(seconds: 1),
                                                                curve: Curves.easeInOut,
                                                                width: screenWidth / 2.3,
                                                                height: hasVoted ? (screenHeight / 4) * answersCount[1] : 0,
                                                                decoration: BoxDecoration(
                                                                  color: AppColors.fadeImageAnswer.withOpacity(.61),
                                                                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                                                                ),
                                                              ),
                                                            ]),
                                                        behavior:
                                                        HitTestBehavior
                                                            .translucent,
                                                        onTap: () async {
                                                          hasVoted ? null : await clickAnswer(
                                                              1,
                                                              post.postId!,
                                                              friendUserId,
                                                              false,
                                                              true);
                                                        },
                                                      ),
                                                      SizedBox(
                                                        height:
                                                        screenHeight /
                                                            50,
                                                      ),
                                                      hasVoted
                                                          ? Text(
                                                        "${(answersCount[1] * 100).round()}%",
                                                        style: TextStyle(
                                                            fontFamily:
                                                            'Helvetica',
                                                            fontWeight:
                                                            FontWeight
                                                                .bold,
                                                            fontSize:
                                                            20,
                                                            color: AppColors
                                                                .white),
                                                      )
                                                          : SizedBox()
                                                    ],
                                                  )
                                                ],
                                              )
                                                  : post.answersList!.length == 2 ? Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceEvenly,
                                                children: [
                                                  Column(
                                                    children: [
                                                      GestureDetector(
                                                        child: Stack(
                                                            alignment: Alignment.centerLeft,
                                                            children: [
                                                              Container(
                                                                width:
                                                                screenWidth /
                                                                    3.3,
                                                                height:
                                                                screenHeight /
                                                                    16,
                                                                decoration:
                                                                BoxDecoration(
                                                                  color: Colors
                                                                      .white,
                                                                  borderRadius:
                                                                  BorderRadius.circular(
                                                                      20),
                                                                ),
                                                                child: Center(child : Text(
                                                                  post.answersList![0], style: TextStyle(
                                                                  fontFamily: 'Helvetica', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brown
                                                                ),
                                                                )),
                                                              ),
                                                              AnimatedContainer(
                                                                duration: Duration(seconds: 1),
                                                                curve: Curves.easeInOut,
                                                                width: hasVoted ? (screenWidth / 3.3) * answersCount[0] : 0,
                                                                height: screenHeight / 16,
                                                                decoration: BoxDecoration(
                                                                  color: AppColors.fadeImageAnswer.withOpacity(.61),
                                                                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                                                                ),
                                                              ),
                                                            ]),
                                                        behavior:
                                                        HitTestBehavior
                                                            .translucent,
                                                        onTap: () async {
                                                          hasVoted ? null : await clickAnswer(
                                                              0,
                                                              post.postId!,
                                                              friendUserId,
                                                              false,
                                                              true);
                                                        },
                                                      ),
                                                      SizedBox(
                                                        height:
                                                        screenHeight /
                                                            50,
                                                      ),
                                                      hasVoted
                                                          ? Text(
                                                        "${(answersCount[0] * 100).round()}%",
                                                        style: TextStyle(
                                                            fontFamily:
                                                            'Helvetica',
                                                            fontWeight:
                                                            FontWeight
                                                                .bold,
                                                            fontSize:
                                                            20,
                                                            color: AppColors
                                                                .white),
                                                      )
                                                          : SizedBox()
                                                    ],
                                                  ),
                                                  Column(
                                                    children: [
                                                      GestureDetector(
                                                        child: Stack(
                                                            alignment: Alignment.centerLeft,
                                                            children: [
                                                              Container(
                                                                width:
                                                                screenWidth /
                                                                    3.3,
                                                                height:
                                                                screenHeight /
                                                                    16,
                                                                decoration:
                                                                BoxDecoration(
                                                                  color: Colors
                                                                      .white,
                                                                  borderRadius:
                                                                  BorderRadius.circular(
                                                                      20),
                                                                ),
                                                                child: Center(child : Text(
                                                                  post.answersList![1], style: TextStyle(
                                                                    fontFamily: 'Helvetica', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brown
                                                                ),
                                                                )),
                                                              ),
                                                              AnimatedContainer(
                                                                duration: Duration(seconds: 1),
                                                                curve: Curves.easeInOut,
                                                                width: hasVoted ? (screenWidth / 3.3) * answersCount[1] : 0,
                                                                height: screenHeight / 16,
                                                                decoration: BoxDecoration(
                                                                  color: AppColors.fadeImageAnswer.withOpacity(.61),
                                                                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                                                                ),
                                                              ),
                                                            ]),
                                                        behavior:
                                                        HitTestBehavior
                                                            .translucent,
                                                        onTap: () async {
                                                          hasVoted ? null : await clickAnswer(
                                                              1,
                                                              post.postId!,
                                                              friendUserId,
                                                              false,
                                                              true);
                                                        },
                                                      ),
                                                      SizedBox(
                                                        height:
                                                        screenHeight /
                                                            50,
                                                      ),
                                                      hasVoted
                                                          ? Text(
                                                        "${(answersCount[1] * 100).round()}%",
                                                        style: TextStyle(
                                                            fontFamily:
                                                            'Helvetica',
                                                            fontWeight:
                                                            FontWeight
                                                                .bold,
                                                            fontSize:
                                                            20,
                                                            color: AppColors
                                                                .white),
                                                      )
                                                          : SizedBox()
                                                    ],
                                                  ),
                                                ],
                                              ): Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                    children: [
                                                      Column(
                                                        children: [
                                                          GestureDetector(
                                                            child: Stack(
                                                                alignment: Alignment.centerLeft,
                                                                children: [
                                                                  Container(
                                                                    width:
                                                                    screenWidth /
                                                                        3.3,
                                                                    height:
                                                                    screenHeight /
                                                                        16,
                                                                    decoration:
                                                                    BoxDecoration(
                                                                      color: Colors
                                                                          .white,
                                                                      borderRadius:
                                                                      BorderRadius.circular(
                                                                          20),
                                                                    ),
                                                                    child: Center(child : Text(
                                                                      post.answersList![0], style: TextStyle(
                                                                        fontFamily: 'Helvetica', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brown
                                                                    ),
                                                                    )),
                                                                  ),
                                                                  AnimatedContainer(
                                                                    duration: Duration(seconds: 1),
                                                                    curve: Curves.easeInOut,
                                                                    width: hasVoted ? (screenWidth / 3.3) * answersCount[0] : 0,
                                                                    height: screenHeight / 16,
                                                                    decoration: BoxDecoration(
                                                                      color: AppColors.fadeImageAnswer.withOpacity(.61),
                                                                      borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                                                                    ),
                                                                  ),
                                                                ]),
                                                            behavior:
                                                            HitTestBehavior
                                                                .translucent,
                                                            onTap: () async {
                                                              hasVoted ? null : await clickAnswer(
                                                                  0,
                                                                  post.postId!,
                                                                  friendUserId,
                                                                  false,
                                                                  false);
                                                            },
                                                          ),
                                                          SizedBox(
                                                            height:
                                                            screenHeight /
                                                                50,
                                                          ),
                                                          hasVoted
                                                              ? Text(
                                                            "${(answersCount[0] * 100).round()}%",
                                                            style: TextStyle(
                                                                fontFamily:
                                                                'Helvetica',
                                                                fontWeight:
                                                                FontWeight
                                                                    .bold,
                                                                fontSize:
                                                                20,
                                                                color: AppColors
                                                                    .white),
                                                          )
                                                              : SizedBox()
                                                        ],
                                                      ),
                                                      Column(
                                                        children: [
                                                          GestureDetector(
                                                            child: Stack(
                                                                alignment: Alignment.centerLeft,
                                                                children: [
                                                                  Container(
                                                                    width:
                                                                    screenWidth /
                                                                        3.3,
                                                                    height:
                                                                    screenHeight /
                                                                        16,
                                                                    decoration:
                                                                    BoxDecoration(
                                                                      color: Colors
                                                                          .white,
                                                                      borderRadius:
                                                                      BorderRadius.circular(
                                                                          20),
                                                                    ),
                                                                    child: Center(child : Text(
                                                                      post.answersList![1], style: TextStyle(
                                                                        fontFamily: 'Helvetica', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brown
                                                                    ),
                                                                    )),
                                                                  ),
                                                                  AnimatedContainer(
                                                                    duration: Duration(seconds: 1),
                                                                    curve: Curves.easeInOut,
                                                                    width: hasVoted ? (screenWidth / 3.3) * answersCount[1] : 0,
                                                                    height: screenHeight / 16,
                                                                    decoration: BoxDecoration(
                                                                      color: AppColors.fadeImageAnswer.withOpacity(.61),
                                                                      borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                                                                    ),
                                                                  ),
                                                                ]),
                                                            behavior:
                                                            HitTestBehavior
                                                                .translucent,
                                                            onTap: () async {
                                                              hasVoted ? null : await clickAnswer(
                                                                  1,
                                                                  post.postId!,
                                                                  friendUserId,
                                                                  false,
                                                                  false);
                                                            },
                                                          ),
                                                          SizedBox(
                                                            height:
                                                            screenHeight /
                                                                50,
                                                          ),
                                                          hasVoted
                                                              ? Text(
                                                            "${(answersCount[1] * 100).round()}%",
                                                            style: TextStyle(
                                                                fontFamily:
                                                                'Helvetica',
                                                                fontWeight:
                                                                FontWeight
                                                                    .bold,
                                                                fontSize:
                                                                20,
                                                                color: AppColors
                                                                    .white),
                                                          )
                                                              : SizedBox()
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: screenHeight/40,),
                                                  Row(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                    children: [
                                                      Column(
                                                        children: [
                                                          GestureDetector(
                                                            child: Stack(
                                                                alignment: Alignment.centerLeft,
                                                                children: [
                                                                  Container(
                                                                    width:
                                                                    screenWidth /
                                                                        3.3,
                                                                    height:
                                                                    screenHeight /
                                                                        16,
                                                                    decoration:
                                                                    BoxDecoration(
                                                                      color: Colors
                                                                          .white,
                                                                      borderRadius:
                                                                      BorderRadius.circular(
                                                                          20),
                                                                    ),
                                                                    child: Center(child : Text(
                                                                      post.answersList![2], style: TextStyle(
                                                                        fontFamily: 'Helvetica', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brown
                                                                    ),
                                                                    )),
                                                                  ),
                                                                  AnimatedContainer(
                                                                    duration: Duration(seconds: 1),
                                                                    curve: Curves.easeInOut,
                                                                    width: hasVoted ? (screenWidth / 3.3) * answersCount[2] : 0,
                                                                    height: screenHeight / 16,
                                                                    decoration: BoxDecoration(
                                                                      color: AppColors.fadeImageAnswer.withOpacity(.61),
                                                                      borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                                                                    ),
                                                                  ),
                                                                ]),
                                                            behavior:
                                                            HitTestBehavior
                                                                .translucent,
                                                            onTap: () async {
                                                              hasVoted ? null : await clickAnswer(
                                                                  2,
                                                                  post.postId!,
                                                                  friendUserId,
                                                                  false,
                                                                  false);
                                                            },
                                                          ),
                                                          SizedBox(
                                                            height:
                                                            screenHeight /
                                                                50,
                                                          ),
                                                          hasVoted
                                                              ? Text(
                                                            "${(answersCount[2] * 100).round()}%",
                                                            style: TextStyle(
                                                                fontFamily:
                                                                'Helvetica',
                                                                fontWeight:
                                                                FontWeight
                                                                    .bold,
                                                                fontSize:
                                                                20,
                                                                color: AppColors
                                                                    .white),
                                                          )
                                                              : SizedBox()
                                                        ],
                                                      ),
                                                    ],
                                                  )
                                                ],
                                              )
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
                    },
                    loading: () => Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => Center(child: Text('Error: $error')),
                  );
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
                    height: hasVoted ? screenHeight / 1.8 : screenHeight / 1.45,
                  ),
                  hasVoted
                      ? Expanded(
                          child: GestureDetector(
                          child: Container(
                            width: screenWidth,
                            child: Center(
                                child: Text(
                              "Tap To Continue",
                              style: TextStyle(
                                  fontFamily: "Helvetica",
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white.withOpacity(0.7)),
                            )),
                          ),
                          behavior: HitTestBehavior.translucent,
                          onTap: goToNextPageTapToContinue,
                        ))
                      : Padding(
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
                                      style:
                                          ref.watch(stylesProvider).text.invite,
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
                                  onPressed: () async {
                                    await goToNextPage();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.transparent,
                                    elevation: 0,
                                  ),
                                  label: Text(
                                    "Skip",
                                    style:
                                        ref.watch(stylesProvider).text.skipHome,
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
