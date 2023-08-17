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

class MyPost extends ConsumerStatefulWidget {
  final PostModel post;
  final UserModel user;

  MyPost({required this.post, required this.user});

  @override
  _MyPostState createState() => _MyPostState();
}

class _MyPostState extends ConsumerState<MyPost> with TickerProviderStateMixin {
  final String? userId = FirebaseAuth.instance.currentUser!.uid;
  final PostService postService =
      PostService(userId: FirebaseAuth.instance.currentUser!.uid);

  List<dynamic> answersCount = [];
  int totalAnswers = 0;
  bool hasVoted = true;
  late Map<int, List<AnswerPostModel>> answersMap;
  late List<Future<UserModel?>> userFutures;

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

  Future<void> fetchAnswersCounts(PostService postService, String postId,
      String idUserPost, int maxInnerListIndex) async {
    final answersCountsMap =
        await postService.getAnswersByIndex(postId, idUserPost);

    answersCount.clear();
    for (int i = 0; i < maxInnerListIndex; i++) {
      final answers = answersCountsMap[i] ?? [];
      answersCount.add(answers.length);
    }
  }

  Future<void> fetchData() async {
    answersMap = await postService.getAnswersByIndex(
        widget.post.postId!, widget.user.id!);

    userFutures = answersMap[0]
            ?.map((answer) =>
                ref.read(otherUserProfileProvider(answer.id!).future))
            ?.toList() ??
        [];

    // Wait for all user profile futures to complete
    await Future.wait(userFutures);

    // Calculate total answers
    totalAnswers =
        answersMap.values.fold<int>(0, (sum, answers) => sum + answers.length);

    // Calculate answers count as a list of percentages
    answersCount = answersMap.values
        .map<double>((answers) => answers.length / totalAnswers)
        .toList();
  }

  Future<void> checkUserVote() async {
    await fetchData();
    for (AnimationController anim in animationControllers) {
      anim.forward();
    }
  }

  void showDialogWithChoices() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Sei sicuro di voler eliminare il post?'),
          content: Text('I tuoi amici non potranno più risponderti!'),
          actions: [
            CupertinoDialogAction(
              child: Text('Annulla'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            CupertinoDialogAction(
              child: Text('Elimina',
                  style: TextStyle(color: AppColors.backgroundRed)),
              onPressed: () {},
            ),
          ],
        );
      },
    );
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
                                    top: screenHeight / 5.5),
                                child: Column(
                                  children: [
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
                                                answersCount:
                                                    answersCount[0] ?? 0.0,
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
                                                clickAnswer: () {},
                                              ),
                                              ImageAnswer(
                                                answersCount:
                                                    answersCount[1] ?? 0.0,
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
                                                clickAnswer: () {},
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
                                                    answersCount:
                                                        answersCount[0] ?? 0.0,
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
                                                    clickAnswer: () {},
                                                  ),
                                                  TextAnswer(
                                                    answersCount:
                                                        answersCount[1] ?? 0.0,
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
                                                    clickAnswer: () {},
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
                                                        answersCount:
                                                            answersCount[0] ??
                                                                0.0,
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
                                                        clickAnswer: () {},
                                                      ),
                                                      TextAnswer(
                                                        answersCount:
                                                            answersCount[1] ??
                                                                0.0,
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
                                                        clickAnswer: () {},
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
                                                        answersCount:
                                                            answersCount[2] ??
                                                                0.0,
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
                                                        clickAnswer: () {},
                                                      )
                                                    ],
                                                  )
                                                ],
                                              ),
                                    SizedBox(
                                      height: 60,
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        padding: EdgeInsets.only(bottom: 25),
                                        itemCount: answersMap.length,
                                        itemBuilder: (context, index) {
                                          final answerList = answersMap[index];
                                          answerList!.sort((a, b) => a
                                              .timestamp!
                                              .compareTo(b.timestamp!));

                                          return Column(
                                            children:
                                                List.generate(answerList.length,
                                                    (answerIndex) {
                                              final answer =
                                                  answerList[answerIndex];

                                              return FutureBuilder<UserModel?>(
                                                future: userFutures[
                                                    answerIndex], // Use answerIndex instead of index
                                                builder: (context, snapshot) {
                                                  if (snapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return CircularProgressIndicator();
                                                  } else if (snapshot
                                                      .hasError) {
                                                    return Text(
                                                        'Error: ${snapshot.error}');
                                                  } else {
                                                    final userProfile =
                                                        snapshot.data;

                                                    String showAnswer = "";

                                                    if (widget.post.images != null) {
                                                      if(widget.post.images!.length == 2) {
                                                        showAnswer =
                                                        "Foto ${index + 1}";
                                                      }
                                                    }
                                                    if (widget.post.answersList != null) {
                                                      if (widget.post.answersList!.length >= 2) {
                                                        showAnswer = "${widget.post.answersList![index]}";
                                                      }
                                                    }

                                                    return GestureDetector(
                                                      onTap: () {
                                                        answer.isAnonymous!
                                                            ? null
                                                            : BottomSheetProfile
                                                                .showOtherProfileBottomSheet(
                                                                    context,
                                                                    answer.id!);
                                                      },
                                                      child: Container(
                                                        height: 60,
                                                        decoration: BoxDecoration(
                                                            color:
                                                                AppColors.white,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            15))),
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                vertical: 8,
                                                                horizontal: 8),
                                                        margin: EdgeInsets.only(
                                                            bottom: 10),
                                                        child: Row(
                                                          children: <Widget>[
                                                            CircleAvatar(
                                                              radius: 28,
                                                              child: Stack(
                                                                children: [
                                                                  if (userProfile!
                                                                              .imageUrl !=
                                                                          null &&
                                                                      userProfile!
                                                                              .imageUrl !=
                                                                          "")
                                                                    CachedNetworkImage(
                                                                      imageUrl:
                                                                          userProfile!
                                                                              .imageUrl!,
                                                                      imageBuilder:
                                                                          (context, imageProvider) =>
                                                                              Container(
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                          image:
                                                                              DecorationImage(
                                                                            image:
                                                                                imageProvider,
                                                                            fit:
                                                                                BoxFit.cover,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      progressIndicatorBuilder: (context,
                                                                              url,
                                                                              downloadProgress) =>
                                                                          Center(
                                                                              child: CupertinoActivityIndicator()),
                                                                      errorWidget: (context,
                                                                              url,
                                                                              error) =>
                                                                          Icon(Icons
                                                                              .error),
                                                                    ),
                                                                  if (userProfile!
                                                                              .imageUrl ==
                                                                          null ||
                                                                      userProfile!
                                                                              .imageUrl ==
                                                                          "")
                                                                    Center(
                                                                      child:
                                                                          Text(
                                                                        userProfile!.name != null &&
                                                                                userProfile!.name != ""
                                                                            ? userProfile!.name![0]
                                                                            : '',
                                                                        style: TextStyle(
                                                                            fontFamily:
                                                                                'Helvetica',
                                                                            fontWeight: FontWeight
                                                                                .bold,
                                                                            fontSize:
                                                                                26,
                                                                            color:
                                                                                AppColors.white),
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                            ),
                                                            SizedBox(width: 2),
                                                            Expanded(
                                                              child: Container(
                                                                color: Colors
                                                                    .transparent,
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: <Widget>[
                                                                    Text(
                                                                      userProfile!
                                                                              .name ??
                                                                          '',
                                                                      style: TextStyle(
                                                                          fontFamily:
                                                                              'Helvetica',
                                                                          fontWeight: FontWeight
                                                                              .bold,
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              Colors.black),
                                                                    ),
                                                                    SizedBox(
                                                                        height:
                                                                            6),
                                                                    Text(
                                                                      userProfile!
                                                                              .username ??
                                                                          '',
                                                                      style: TextStyle(
                                                                          fontFamily:
                                                                              'Helvetica',
                                                                          fontWeight: FontWeight
                                                                              .bold,
                                                                          fontSize:
                                                                              12,
                                                                          color:
                                                                              Colors.black),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(width: 2),
                                                            Text(
                                                                "ha risposto '$showAnswer'")
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              );
                                            }),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ))),
                      SafeArea(
                        child: Column(
                          children: [
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                    Container(
                                      child: Text(
                                        "La tua Domanda",
                                        textAlign: TextAlign.center,
                                        style: ref
                                            .watch(stylesProvider)
                                            .text
                                            .titleOnBoarding
                                            .copyWith(fontSize: 22),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      itemBuilder: (BuildContext context) =>
                                          <PopupMenuEntry<String>>[
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Text('Elimina domanda',
                                              style: TextStyle(
                                                  fontFamily: 'Helvetica',
                                                  fontSize: 16,
                                                  color:
                                                      AppColors.backgroundRed,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                      onSelected: (String value) {
                                        if (value == 'delete') {
                                          showDialogWithChoices();
                                        }
                                      },
                                      offset: Offset(0, 40),
                                      elevation: 8,
                                      padding: EdgeInsets.all(0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10)),
                                      ),
                                      color: AppColors.white,
                                      enabled: true,
                                      icon: Icon(Icons.more_horiz_rounded),
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
                              height: screenHeight / 1.45,
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
