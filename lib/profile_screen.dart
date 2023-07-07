import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gas/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/models/user_model.dart';
import 'core/models/user_info_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Stream<UserModel?> userProfileStream;
  late UserInfoService userInfoService;

  @override
  void initState() {
    super.initState();
    userInfoService = UserInfoService();
    userProfileStream = userInfoService.fetchProfileData();
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    userProfileStream = userInfoService.fetchProfileData();
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

    return Scaffold(
        backgroundColor: AppColors.backgroundDefault,
        body: SafeArea(
          child: StreamBuilder<UserModel?>(
              stream: userProfileStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  UserModel? userProfile = snapshot.data;
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
                                  backgroundImage: userProfile?.imageUrl != ""
                                      ? NetworkImage(
                                      userProfile!.imageUrl ?? '')
                                      : null,
                                  child: userProfile?.imageUrl == ""
                                      ? Text(userProfile?.name != ""
                                      ? userProfile!.name![0]
                                      : '', style: ref
                                      .watch(stylesProvider)
                                      .text
                                      .titleOnBoarding
                                      .copyWith(fontSize: 50),)
                                      : null,
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
                                context.push("/profile/editProfile");
                              },),
                          ],
                        ),
                        SizedBox(height: 40),
                        Align(alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: 20), child: Text(
                              "Your Pools",
                              textAlign: TextAlign.left,
                              style: ref
                                  .watch(stylesProvider)
                                  .text
                                  .titleOnBoarding
                                  .copyWith(fontSize: 28),
                            ),))
                      ]
                  );
                }else{
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
              }
          ),
        )
    );
  }
}