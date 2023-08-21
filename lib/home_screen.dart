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
import 'chat_service.dart';
import 'chat_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  Color color = AppColors.backgroundDefault;
  final String? userId = FirebaseAuth.instance.currentUser!.uid;
  final PostService postService =
      PostService(userId: FirebaseAuth.instance.currentUser!.uid);

  bool hasVoted = false;
  late PageController _pageController;
  List<dynamic> answersCount = [];
  int totalAnswers = 0;
  bool isAnonymous = false;
  bool isFriends = true;
  List<PostModel> posts = [];
  late PostModel actualPost;

  bool isTextFieldVisible = false;
  final FocusNode _focusNode = FocusNode();
  TextEditingController textEditingController = TextEditingController();

  List<AnimationController> animationControllers = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    for (var controller in animationControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset the background color every time the page is displayed
    color = AppColors.backgroundDefault; // Set the initial background color
  }

  Future<void> goToNextPage() async {
 //   await postService.markPostAsSeen(postId);

    int nextPage = _pageController.page!.toInt() + 1;
    if (nextPage < posts.length) {
      _pageController.animateToPage(nextPage,
          duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void goToNextPageTapToContinue() {
    int nextPage = _pageController.page!.toInt() + 1;
    if (nextPage < posts.length) {
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

    for (AnimationController anim in animationControllers){
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

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    print("sign out");
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double bottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
        backgroundColor: color,
        resizeToAvoidBottomInset: false,
        body: Stack (
          children: [
            SingleChildScrollView(
              child: Stack(
                children: [
                  Container(
                    width: screenWidth,
                    height: screenHeight,
                    child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(isFriends ? 1.0 : -1.0, 0.0),
                              end: Offset(0.0, 0.0),
                            ).animate(animation),
                            child: child,
                          );
                        },
                        child: Consumer(
                          key: ValueKey<bool>(false),
                          builder: (context, watch, _) {
                            final friendPostsAsync = ref.watch(friendPostsProvider);

                            return friendPostsAsync.when(
                              data: (friendPosts) {
                                if (friendPosts.isNotEmpty) {
                                  posts = friendPosts;
                                  return PageView(
                                      controller: _pageController,
                                      scrollDirection: Axis.vertical,
                                      physics: NeverScrollableScrollPhysics(),
                                      children: List.generate(friendPosts.length, (index) {
                                        final post = friendPosts[index];
                                        final friendUserId = post.id as String;
                                        final userInfoProvider = otherUserProfileProvider(friendUserId);
                                        final userProfileFuture = ref.watch(userInfoProvider.future);

                                        return FutureBuilder<UserModel?>(
                                          future: userProfileFuture,
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              UserModel? userProfile = snapshot.data;
                                              final username = userProfile!.username!;
                                              final profilePictureUrl = userProfile!.imageUrl!;
                                              final name = userProfile!.name!;
                                              final timestamp = userProfile!.timestamp ?? Timestamp.now();
                                              final id = userProfile!.id!;
                                              final localDateTime =
                                              post.timestamp!.toDate().toLocal();
                                              final hour = localDateTime.hour
                                                  .toString()
                                                  .padLeft(2, '0');
                                              final minute = localDateTime.minute
                                                  .toString()
                                                  .padLeft(2, '0');

                                              int questionLenght = post.answersList?.length! ?? 0;
                                              if (questionLenght == 0){
                                                questionLenght = post.images?.length! ?? 0;
                                              }

                                              for (int i = 0; i < questionLenght; i++) {
                                                AnimationController controller = AnimationController(
                                                  vsync: this,
                                                  duration: Duration(seconds: 1),
                                                );
                                                animationControllers.add(controller);
                                              }

                                              return Container(
                                                  color: index == 0
                                                      ? AppColors.backgroundDefault
                                                      : post.colorBackground,
                                                  child: Padding(
                                                    padding: EdgeInsets.only(
                                                        right: 20,
                                                        left: 20,
                                                        top: screenHeight / 3.75),
                                                    child: Column(
                                                      children: [
                                                        GestureDetector(onTap:() {
                                                          post.isAnonymous! ? null : BottomSheetProfile.showOtherProfileBottomSheet(context, id);
                                                        }, child: Row(
                                                          children: <Widget>[
                                                            post.isAnonymous!
                                                                ? CircleAvatar(
                                                              maxRadius: 25,
                                                              backgroundImage: null,
                                                              child: Icon(
                                                                  Icons.hide_image),
                                                            )
                                                                : CircleAvatar(
                                                              radius: 25,
                                                              child: Stack(
                                                                children: [
                                                                  // Show CachedNetworkImage if userProfile?.imageUrl is not empty
                                                                  if (profilePictureUrl != null && profilePictureUrl != "")
                                                                    CachedNetworkImage(
                                                                      imageUrl: profilePictureUrl,
                                                                      imageBuilder: (context, imageProvider) => Container(
                                                                        decoration: BoxDecoration(
                                                                          shape: BoxShape.circle,
                                                                          image: DecorationImage(
                                                                            image: imageProvider,
                                                                            fit: BoxFit.cover,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      progressIndicatorBuilder: (context, url, downloadProgress) =>
                                                                          Center(child: CupertinoActivityIndicator()), // Show CircularProgressIndicator while loading
                                                                      errorWidget: (context, url, error) => Icon(Icons.error),
                                                                    ),

                                                                  if (profilePictureUrl == null || profilePictureUrl == "")
                                                                    Center(
                                                                      child: Text(
                                                                        name != null && name != "" ? name![0] : '',
                                                                        style: TextStyle(
                                                                            fontFamily: 'Helvetica',
                                                                            fontWeight: FontWeight.bold,
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
                                                            InkWell(onTap: () {
                                                              setState(() {
                                                                isTextFieldVisible = true;
                                                              });
                                                              FocusScope.of(context).requestFocus(_focusNode);

                                                            }, child:Container(
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
                                                            )),
                                                          ],
                                                        )),
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
                                                            ImageAnswer(
                                                              answersCount: hasVoted ? answersCount[0] ?? 0.0 : 0.0,
                                                              imageUrl: post.images![0] ?? "",
                                                              hasVoted: hasVoted,
                                                              curvedAnimation: CurvedAnimation(
                                                                parent: animationControllers[0],
                                                                curve: Curves.easeInOut,
                                                              ),
                                                              clickAnswer: () async {
                                                                if (!hasVoted) {
                                                                  await clickAnswer(0, post.postId!, friendUserId, isAnonymous, true);
                                                                }
                                                              },
                                                            ),
                                                            ImageAnswer(
                                                              answersCount: hasVoted ? answersCount[1] ?? 0.0 : 0.0,
                                                              imageUrl: post.images![1] ?? "",
                                                              hasVoted: hasVoted,
                                                              curvedAnimation: CurvedAnimation(
                                                                parent: animationControllers[1],
                                                                curve: Curves.easeInOut,
                                                              ),
                                                              clickAnswer: () async {
                                                                if (!hasVoted) {
                                                                  await clickAnswer(1, post.postId!, friendUserId, isAnonymous, true);
                                                                }
                                                              },
                                                            ),

                                                          ],
                                                        )
                                                            : post.answersList!.length == 2 ? Row(
                                                          mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                          children: [
                                                            TextAnswer(
                                                              answersCount: hasVoted ? answersCount[0] ?? 0.0 : 0.0,
                                                              answerText: post.answersList?[0] ?? "",
                                                              hasVoted: hasVoted,
                                                              curvedAnimation: CurvedAnimation(
                                                                parent: animationControllers[0],
                                                                curve: Curves.easeInOut,
                                                              ),
                                                              clickAnswer: () async {
                                                                if (!hasVoted) {
                                                                  await clickAnswer(0, post.postId!, friendUserId, isAnonymous, true);
                                                                }
                                                              },
                                                            ),
                                                            TextAnswer(
                                                              answersCount: hasVoted ? answersCount[1] ?? 0.0 : 0.0,
                                                              answerText: post.answersList?[1] ?? "",
                                                              hasVoted: hasVoted,
                                                              curvedAnimation: CurvedAnimation(
                                                                parent: animationControllers[1],
                                                                curve: Curves.easeInOut,
                                                              ),
                                                              clickAnswer: () async {
                                                                if (!hasVoted) {
                                                                  await clickAnswer(1, post.postId!, friendUserId, isAnonymous, true);
                                                                }
                                                              },
                                                            ),
                                                          ],
                                                        ): Column(
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceEvenly,
                                                              children: [
                                                                TextAnswer(
                                                                  answersCount: hasVoted ? answersCount[0] ?? 0.0 : 0.0,
                                                                  answerText: post.answersList?[0] ?? "",
                                                                  hasVoted: hasVoted,
                                                                  curvedAnimation: CurvedAnimation(
                                                                    parent: animationControllers[0],
                                                                    curve: Curves.easeInOut,
                                                                  ),
                                                                  clickAnswer: () async {
                                                                    if (!hasVoted) {
                                                                      await clickAnswer(0, post.postId!, friendUserId, isAnonymous, false);
                                                                    }
                                                                  },
                                                                ),
                                                                TextAnswer(
                                                                  answersCount: hasVoted ? answersCount[1] ?? 0.0 : 0.0,
                                                                  answerText: post.answersList?[1] ?? "",
                                                                  hasVoted: hasVoted,
                                                                  curvedAnimation: CurvedAnimation(
                                                                    parent: animationControllers[1],
                                                                    curve: Curves.easeInOut,
                                                                  ),
                                                                  clickAnswer: () async {
                                                                    if (!hasVoted) {
                                                                      await clickAnswer(1, post.postId!, friendUserId, isAnonymous, false);
                                                                    }
                                                                  },
                                                                )
                                                              ],
                                                            ),
                                                            SizedBox(height: screenHeight/40,),
                                                            Row(
                                                              mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceEvenly,
                                                              children: [
                                                                TextAnswer(
                                                                  answersCount: hasVoted ? answersCount[2] ?? 0.0 : 0.0,
                                                                  answerText: post.answersList?[2] ?? "",
                                                                  hasVoted: hasVoted,
                                                                  curvedAnimation: CurvedAnimation(
                                                                    parent: animationControllers[2],
                                                                    curve: Curves.easeInOut,
                                                                  ),
                                                                  clickAnswer: () async {
                                                                    if (!hasVoted) {
                                                                      await clickAnswer(2, post.postId!, friendUserId, isAnonymous, false);
                                                                    }
                                                                  },
                                                                )
                                                              ],
                                                            )
                                                          ],
                                                        )
                                                      ],

                                                    ),
                                                  ));
                                            }
                                            return CupertinoActivityIndicator();
                                          },
                                        );
                                      }));
                                } else {
                                  return Align(
                                      alignment: Alignment.center,
                                      child: Container(
                                        height: screenHeight/4,
                                        width: screenWidth/1.3,
                                        padding: EdgeInsets.symmetric(vertical: 50),
                                        margin: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: AppColors.a,
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text('Nessun nuovo post'),
                                            SizedBox(height: 20),
                                            Text('Aggiungi nuovi amici!'),
                                          ],
                                        ),
                                      )
                                  );
                                }
                              },
                              loading: () => Center(child: CupertinoActivityIndicator(radius: 20,)),
                              error: (error, stackTrace) => Center(child: Text('Error: $error')),
                            );
                          },
                        )
                 /*           :
                        Consumer(key: ValueKey<bool>(true),
                          builder: (context, watch, _) {
                            final globalPostsAsync = ref.watch(globalPostsProvider);
                            return globalPostsAsync.when(
                              data: (globalPosts) {
                                if (globalPosts.isNotEmpty) {
                                  totalPosts = globalPosts.length;
                                  posts =
                                  return PageView(
                                      controller: _pageController,
                                      scrollDirection: Axis.vertical,
                                      physics: NeverScrollableScrollPhysics(),
                                      children: List.generate(globalPosts.length, (index) {
                                        final post = globalPosts[index];
                                        final globalUserId = post.id as String;
                                        final userInfoProvider = otherUserProfileProvider(globalUserId);
                                        final userProfileFuture = ref.watch(userInfoProvider.future);

                                        return FutureBuilder<UserModel?>(
                                          future: userProfileFuture,
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {

                                              UserModel? userProfile = snapshot.data;
                                              final username = userProfile!.username!;
                                              final profilePictureUrl = userProfile!.imageUrl!;
                                              final name = userProfile!.name!;
                                              final timestamp = userProfile!.timestamp ?? Timestamp.now();
                                              final id = userProfile!.id!;
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
                                                        GestureDetector(onTap:() {
                                                          post.isAnonymous! ? null : BottomSheetProfile.showOtherProfileBottomSheet(context, id);
                                                        }, child: Row(
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
                                                            InkWell(onTap: () {print ("vamos");}, child:Container(
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
                                                            )),
                                                          ],
                                                        )),
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
                                                                        globalUserId,
                                                                        isAnonymous,
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
                                                                        globalUserId,
                                                                        isAnonymous,
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
                                                                        globalUserId,
                                                                        isAnonymous,
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
                                                                        globalUserId,
                                                                        isAnonymous,
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
                                                                            globalUserId,
                                                                            isAnonymous,
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
                                                                            globalUserId,
                                                                            isAnonymous,
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
                                                                            globalUserId,
                                                                            isAnonymous,
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
                                            return CupertinoActivityIndicator(radius: 20);
                                          },
                                        );
                                      }));
                                } else {
                                  return Align(
                                      alignment: Alignment.center,
                                      child: Container(
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
                                      )
                                  );
                                }
                              },
                              loading: () => Center(child: CupertinoActivityIndicator(radius: 20,)),
                              error: (error, stackTrace) => Center(child: Text('Error: $error')),
                            );
                          },
                        )), */
                    )
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
                                onPressed: () {context.push('/chat');},
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
                                  onPressed: () {setState(() {
                                    isFriends = true;
                                  });},
                                  child: Text(
                                    "My Friends",
                                    style: ref
                                        .watch(stylesProvider)
                                        .text
                                        .numberContactOnBoarding
                                        .copyWith(color: isFriends ? AppColors.white : null),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {setState(() {
                                    isFriends = false;
                                  });},
                                  child: Text(
                                    "Global",
                                    style: ref
                                        .watch(stylesProvider)
                                        .text
                                        .numberContactOnBoarding
                                        .copyWith(color: isFriends ? null : AppColors.white),
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
                            ? GestureDetector(
                          child: Container(
                            padding: EdgeInsets.only(top: screenHeight/10),
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
                        )
                            : Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(width: screenWidth/4, child: Column(
                                  children: [
                                    InkWell(
                                      child: Icon(
                                        isAnonymous ? Ionicons.eye_off : Ionicons.eye,
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
                                      isAnonymous ? "ANONYMOUS" : "VISIBLE",
                                      style:
                                      ref.watch(stylesProvider).text.invite,
                                    ),
                                  ],
                                ),),
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
              ),
            ),
            AnimatedPositioned(
              duration: Duration(milliseconds: 300),
              bottom: isTextFieldVisible
                  ? MediaQuery.of(context).viewInsets.bottom
                  : -80.0, // Move the container off-screen when not visible
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                        child: TextField(
                          controller: textEditingController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: "Type your message...",
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (value) {
                            setState(() {
                              isTextFieldVisible = false;
                            });
                          },
                        ),
                    ),
                    SizedBox(width: 8.0),
                    ElevatedButton(
                      onPressed: () async {
                        actualPost = posts[_pageController.page!.round()];
                        await MessageService().sendInitialMessage(
                          content: textEditingController.text,
                          senderIsAnonymous: isAnonymous,
                          receiverId: actualPost.id!,
                          receiverIsAnonymous: actualPost.isAnonymous!,
                          idPost: actualPost.postId!,);
                        ref.refresh(conversationListProvider);
                      },
                      child: Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}