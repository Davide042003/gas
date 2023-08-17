import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gas/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/models/user_model.dart';
import 'core/models/user_info_service.dart';
import 'package:gas/user_notifier.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'profile_edit_screen.dart';
import 'post_notifier.dart';
import 'package:gas/my_post.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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

    return Scaffold(
        backgroundColor: AppColors.backgroundDefault,
        body: SafeArea(
          child: Consumer(
            builder: (context, watch, child) {
              final userProfileFuture = ref.watch(userProfileFutureProvider);

              return userProfileFuture.when(
                data: (userProfile) {
                  if (userProfile != null) {
                    return Column(
                        children: [
                          Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  InkWell(
                                    child: Icon(
                                      Icons.arrow_back_rounded,
                                      size: 35,
                                      color: AppColors.white,
                                    ),
                                    onTap: () {
                                      context.pop();
                                    },
                                  ),
                                  Container(
                                    child: Text(
                                      "Profile", textAlign: TextAlign.center,
                                      style: ref
                                          .watch(stylesProvider)
                                          .text
                                          .titleOnBoarding
                                          .copyWith(fontSize: 28),),
                                    width: 100,),
                                  InkWell(
                                    child: Icon(
                                      Icons.settings,
                                      size: 35,
                                      color: AppColors.white,
                                    ),
                                    onTap: () {},
                                  ),
                                ],)),
                          SizedBox(height: 10,),
                          Stack(children: [
                            Container(
                              color: AppColors.whiteShadow,
                              height: screenHeight / 600,),
                            Center(child: Container(color: AppColors.white,
                              height: screenHeight / 400,
                              width: screenWidth / 3,))
                          ],),
                          SizedBox(height: 30),
                          Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 70,
                                    child: Stack(
                                      children: [
                                        // Show CachedNetworkImage if userProfile?.imageUrl is not empty
                                        if (userProfile?.imageUrl != null && userProfile!.imageUrl != "")
                                          CachedNetworkImage(
                                            imageUrl: userProfile!.imageUrl!,
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
                                        // Show Text with the first character of the name if userProfile?.imageUrl is empty
                                        if (userProfile?.imageUrl == null || userProfile!.imageUrl == "")
                                          Center(
                                            child: Text(
                                              userProfile?.name != null && userProfile!.name != "" ? userProfile!.name![0] : '',
                                              style: ref.watch(stylesProvider).text.titleOnBoarding.copyWith(fontSize: 50),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    userProfile?.name ?? '',
                                    style: ref
                                        .watch(stylesProvider)
                                        .text
                                        .titleOnBoarding
                                        .copyWith(fontSize: 28),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    userProfile?.username ?? '',
                                    style: ref
                                        .watch(stylesProvider)
                                        .text
                                        .titleOnBoarding
                                        .copyWith(fontSize: 17),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                child: Container(
                                  width: screenWidth / 1.5,
                                  height: screenHeight / 3.5,),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProfileScreen(),
                                    ),
                                  );
                                },),
                            ],
                          ),
                          SizedBox(height: 40),
                          Align(alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(left: 20), child: Text(
                                "Le Tue Domande",
                                textAlign: TextAlign.left,
                                style: ref
                                    .watch(stylesProvider)
                                    .text
                                    .titleOnBoarding
                                    .copyWith(fontSize: 28, color: AppColors.brown),
                              ),)),
                          SizedBox(height: 10),
                          Consumer(builder: (context, ref, _) {
                            final userPostsAsyncValue = ref.watch(userPostsProvider(userProfile.id!));

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
                                        builder: (context) => MyPost(user: userProfile, post: post,),
                                      ),
                                    );}, child: Container(
                                      padding: EdgeInsets.all(10),
                                      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                        ]
                    );
                  } else {
                    return Center(
                      child: CupertinoActivityIndicator(radius: 20,),
                    );
                  }
                },
                loading: () => Center(
                  child: CupertinoActivityIndicator(radius: 20,),
                ),
                error: (error, stackTrace) => Center(
                  child: Text('Error fetching data.'),
                ),
              );
            },
          ),
        )
    );
  }
}