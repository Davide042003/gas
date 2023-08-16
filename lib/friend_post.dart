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
import 'package:gas/bottom_sheet_profile.dart';
import 'package:gas/user_notifier.dart';
import 'core/models/user_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gas/friends_screen.dart';
import 'package:gas/fractional_range_clipper.dart';
import 'text_answer.dart';
import 'image_answer.dart';

class FriendPost extends ConsumerStatefulWidget {
  final PostModel post;
  final UserModel user;

  FriendPost({required this.post, required this.user});

  @override
  _FriendPostState createState() => _FriendPostState();
}

class _FriendPostState extends ConsumerState<FriendPost>
    with TickerProviderStateMixin {
  final String? userId = FirebaseAuth.instance.currentUser!.uid;
  final PostService postService =
      PostService(userId: FirebaseAuth.instance.currentUser!.uid);

  bool hasVoted = false;
  int totalPosts = 0;
  List<dynamic> answersCount = [];
  int totalAnswers = 0;
  bool isAnonymous = false;

  List<AnimationController> animationControllers = [];

  String? username;
  String? profilePictureUrl;
  String? name;
  String? id;
  String? hour;
  String? minute;

  @override
  void initState() {
    super.initState();

    UserModel? userProfile = widget.user;
    username = userProfile!.username!;
    profilePictureUrl = userProfile!.imageUrl!;
    name = userProfile!.name!;
    final timestamp = userProfile!.timestamp ?? Timestamp.now();
    id = userProfile!.id!;
    final localDateTime = widget.post.timestamp!.toDate().toLocal();
    hour = localDateTime.hour.toString().padLeft(2, '0');
    minute = localDateTime.minute.toString().padLeft(2, '0');

    int questionLenght = widget.post.answersList?.length! ?? 0;
    if (questionLenght == 0) {
      questionLenght = widget.post.images?.length! ?? 0;
    }

    for (int i = 0; i < questionLenght; i++) {
      AnimationController controller = AnimationController(
        vsync: this,
        duration: Duration(seconds: 1),
      );
      animationControllers.add(controller);
    }

    checkUserVote();
  }

  @override
  void dispose() {
    for (var controller in animationControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> fetchData() async {
    int totDomande = 0;

    if (widget.post.answersList != null) {
      if (widget.post.answersList!.length == 2) {
        totDomande = 2;
      } else if (widget.post.answersList!.length == 3) {
        totDomande = 3;
      }
    }else if (widget.post.images != null) {
      totDomande = 2;
    }

    await fetchAnswersCounts(
        postService, widget.post.postId!, widget.user.id!, totDomande);
    totalAnswers = answersCount.reduce((a, b) => a + b);

    answersCount =
        answersCount.map((element) => element / totalAnswers).toList();
  }

  Future<void> clickAnswer(
      int indexAnswer, String postId, bool isAnonymous, bool answers2) async {
    await postService.addAnswerToPost(
        postId,
        AnswerPostModel(
          id: userId,
          isAnonymous: isAnonymous,
          timestamp: Timestamp.now(),
        ),
        widget.user.id!,
        indexAnswer);

    //   await postService.markPostAsSeen(postId);

    if (answers2 == true) {
      await fetchAnswersCounts(postService, postId, widget.user.id!, 2);
      totalAnswers = answersCount.reduce((a, b) => a + b);

      answersCount =
          answersCount.map((element) => element / totalAnswers).toList();
      print(answersCount);
    } else {
      await fetchAnswersCounts(postService, postId, widget.user.id!, 3);
      totalAnswers = answersCount.reduce((a, b) => a + b);

      answersCount =
          answersCount.map((element) => element / totalAnswers).toList();

      print(answersCount);
    }

    setState(() {
      hasVoted = true;
    });

    for (AnimationController anim in animationControllers) {
      anim.forward();
    }
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

  Future<void> checkUserVote() async {
    hasVoted = await postService.hasUserVotedForAnyAnswer(
        widget.post.postId!, userId!, id!);

    if (hasVoted) {
      await fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
        backgroundColor: AppColors.backgroundDefault,
        body: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: FutureBuilder(
              future: checkUserVote(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CupertinoActivityIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return Stack(
                    children: [
                      Container(
                          width: screenWidth,
                          height: screenHeight,
                          child: Container(
                              color: AppColors.backgroundDefault,
                              child: Padding(
                                padding: EdgeInsets.only(
                                    right: 20,
                                    left: 20,
                                    top: screenHeight / 3.75),
                                child: Column(
                                  children: [
                                    Row(
                                      children: <Widget>[
                                        CircleAvatar(
                                          radius: 25,
                                          child: Stack(
                                            children: [
                                              // Show CachedNetworkImage if userProfile?.imageUrl is not empty
                                              if (profilePictureUrl != null &&
                                                  profilePictureUrl != "")
                                                CachedNetworkImage(
                                                  imageUrl: profilePictureUrl!,
                                                  imageBuilder: (context,
                                                          imageProvider) =>
                                                      Container(
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      image: DecorationImage(
                                                        image: imageProvider,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  progressIndicatorBuilder: (context,
                                                          url,
                                                          downloadProgress) =>
                                                      Center(
                                                          child:
                                                              CupertinoActivityIndicator()), // Show CircularProgressIndicator while loading
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          Icon(Icons.error),
                                                ),

                                              if (profilePictureUrl == null ||
                                                  profilePictureUrl == "")
                                                Center(
                                                  child: Text(
                                                    name != null && name != ""
                                                        ? name![0]
                                                        : '',
                                                    style: TextStyle(
                                                        fontFamily: 'Helvetica',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 26,
                                                        color: AppColors.white),
                                                  ),
                                                ),
                                            ],
                                          ),
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
                                                  username ?? '',
                                                  style: TextStyle(
                                                    fontFamily: 'Helvetica',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 20,
                                                    color: AppColors.white,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  "$hour:$minute",
                                                  style: TextStyle(
                                                    fontFamily: 'Helvetica',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 18,
                                                    color:
                                                        AppColors.whiteShadow,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                            onTap: () {
                                              print("vamos");
                                            },
                                            child: Container(
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
                                            )),
                                      ],
                                    ),
                                    SizedBox(
                                        height: widget.post.images!.length == 2
                                            ? 40
                                            : widget.post.answersList!.length ==
                                                    2
                                                ? 120
                                                : 80),
                                    Text(
                                      widget.post.question!,
                                      style: TextStyle(
                                        fontFamily: 'Helvetica',
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.white,
                                        fontSize: 24,
                                      ),
                                    ),
                                    SizedBox(
                                        height: widget.post.images!.length == 2
                                            ? 30
                                            : widget.post.answersList!.length ==
                                                    2
                                                ? 70
                                                : 40),
                                    widget.post.images!.length == 2
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              ImageAnswer(
                                                answersCount: hasVoted!
                                                    ? answersCount[0] ?? 0.0
                                                    : 0.0,
                                                imageUrl:
                                                    widget.post.images![0] ??
                                                        "",
                                                hasVoted: hasVoted,
                                                curvedAnimation:
                                                    CurvedAnimation(
                                                  parent:
                                                      animationControllers[0],
                                                  curve: Curves.easeInOut,
                                                ),
                                                clickAnswer: () async {
                                                  if (!hasVoted!) {
                                                    await clickAnswer(
                                                        0,
                                                        widget.post.postId!,
                                                        isAnonymous,
                                                        true);
                                                  }
                                                },
                                              ),
                                              ImageAnswer(
                                                answersCount: hasVoted
                                                    ? answersCount[1] ?? 0.0
                                                    : 0.0,
                                                imageUrl:
                                                    widget.post.images![1] ??
                                                        "",
                                                hasVoted: hasVoted,
                                                curvedAnimation:
                                                    CurvedAnimation(
                                                  parent:
                                                      animationControllers[1],
                                                  curve: Curves.easeInOut,
                                                ),
                                                clickAnswer: () async {
                                                  if (!hasVoted) {
                                                    await clickAnswer(
                                                        1,
                                                        widget.post.postId!,
                                                        isAnonymous,
                                                        true);
                                                  }
                                                },
                                              ),
                                            ],
                                          )
                                        : widget.post.answersList!.length == 2
                                            ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  TextAnswer(
                                                    answersCount: hasVoted!
                                                        ? answersCount[0] ?? 0.0
                                                        : 0.0,
                                                    answerText: widget.post
                                                            .answersList?[0] ??
                                                        "",
                                                    hasVoted: hasVoted,
                                                    curvedAnimation:
                                                        CurvedAnimation(
                                                      parent:
                                                          animationControllers[
                                                              0],
                                                      curve: Curves.easeInOut,
                                                    ),
                                                    clickAnswer: () async {
                                                      if (!hasVoted!) {
                                                        await clickAnswer(
                                                            0,
                                                            widget.post.postId!,
                                                            isAnonymous,
                                                            true);
                                                      }
                                                    },
                                                  ),
                                                  TextAnswer(
                                                    answersCount: hasVoted
                                                        ? answersCount[1] ?? 0.0
                                                        : 0.0,
                                                    answerText: widget.post
                                                            .answersList?[1] ??
                                                        "",
                                                    hasVoted: hasVoted,
                                                    curvedAnimation:
                                                        CurvedAnimation(
                                                      parent:
                                                          animationControllers[
                                                              1],
                                                      curve: Curves.easeInOut,
                                                    ),
                                                    clickAnswer: () async {
                                                      if (!hasVoted) {
                                                        await clickAnswer(
                                                            1,
                                                            widget.post.postId!,
                                                            isAnonymous,
                                                            true);
                                                      }
                                                    },
                                                  ),
                                                ],
                                              )
                                            : Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      TextAnswer(
                                                        answersCount: hasVoted!
                                                            ? answersCount[0] ??
                                                                0.0
                                                            : 0.0,
                                                        answerText: widget.post
                                                                    .answersList?[
                                                                0] ??
                                                            "",
                                                        hasVoted: hasVoted!,
                                                        curvedAnimation:
                                                            CurvedAnimation(
                                                          parent:
                                                              animationControllers[
                                                                  0],
                                                          curve:
                                                              Curves.easeInOut,
                                                        ),
                                                        clickAnswer: () async {
                                                          if (!hasVoted!) {
                                                            await clickAnswer(
                                                                0,
                                                                widget.post
                                                                    .postId!,
                                                                isAnonymous,
                                                                false);
                                                          }
                                                        },
                                                      ),
                                                      TextAnswer(
                                                        answersCount: hasVoted
                                                            ? answersCount[1] ??
                                                                0.0
                                                            : 0.0,
                                                        answerText: widget.post
                                                                    .answersList?[
                                                                1] ??
                                                            "",
                                                        hasVoted: hasVoted,
                                                        curvedAnimation:
                                                            CurvedAnimation(
                                                          parent:
                                                              animationControllers[
                                                                  1],
                                                          curve:
                                                              Curves.easeInOut,
                                                        ),
                                                        clickAnswer: () async {
                                                          if (!hasVoted) {
                                                            await clickAnswer(
                                                                1,
                                                                widget.post
                                                                    .postId!,
                                                                isAnonymous,
                                                                false);
                                                          }
                                                        },
                                                      )
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: screenHeight / 40,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      TextAnswer(
                                                        answersCount: hasVoted
                                                            ? answersCount[2] ??
                                                                0.0
                                                            : 0.0,
                                                        answerText: widget.post
                                                                    .answersList?[
                                                                2] ??
                                                            "",
                                                        hasVoted: hasVoted,
                                                        curvedAnimation:
                                                            CurvedAnimation(
                                                          parent:
                                                              animationControllers[
                                                                  2],
                                                          curve:
                                                              Curves.easeInOut,
                                                        ),
                                                        clickAnswer: () async {
                                                          if (!hasVoted) {
                                                            await clickAnswer(
                                                                2,
                                                                widget.post
                                                                    .postId!,
                                                                isAnonymous,
                                                                false);
                                                          }
                                                        },
                                                      )
                                                    ],
                                                  )
                                                ],
                                              )
                                  ],
                                ),
                              ))),
                      SafeArea(
                        child: Column(
                          children: [
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    InkWell(
                                      child: Icon(
                                        Icons.arrow_back_rounded,
                                        size: 35,
                                        color: AppColors.white,
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                    SizedBox(width: screenWidth / 35),
                                    Container(
                                      width: screenWidth / 1.4,
                                      child: Text(
                                        "Domanda di $name",
                                        textAlign: TextAlign.center,
                                        style: ref
                                            .watch(stylesProvider)
                                            .text
                                            .titleOnBoarding
                                            .copyWith(fontSize: 22),
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
                                    width: screenWidth / 3,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: hasVoted!
                                  ? screenHeight / 1.8
                                  : screenHeight / 1.45,
                            ),
                            hasVoted!
                                ? Container()
                                : Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 20),
                                    child: Container(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: screenWidth / 4,
                                            child: Column(
                                              children: [
                                                InkWell(
                                                  child: Icon(
                                                    isAnonymous
                                                        ? Ionicons.eye_off
                                                        : Ionicons.eye,
                                                    size: 35,
                                                    color: AppColors.white,
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      if (isAnonymous == true) {
                                                        isAnonymous = false;
                                                      } else {
                                                        isAnonymous = true;
                                                      }
                                                    });
                                                  },
                                                ),
                                                SizedBox(
                                                  height: screenHeight / 200,
                                                ),
                                                Text(
                                                  isAnonymous
                                                      ? "ANONYMOUS"
                                                      : "VISIBLE",
                                                  style: ref
                                                      .watch(stylesProvider)
                                                      .text
                                                      .invite,
                                                ),
                                              ],
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
                  );
                }
              },
            )));
  }
}
