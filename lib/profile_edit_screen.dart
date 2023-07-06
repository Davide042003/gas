import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gas/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/models/user_model.dart';
import 'core/models/user_info_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late Stream<UserModel?> userProfileStream;
  late UserInfoService userInfoService;
  bool showWait = false;

  List<TextEditingController> controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  List<bool> hasError = [false, false, false];


  @override
  void initState() {
    super.initState();
    userInfoService = UserInfoService();
    userProfileStream = userInfoService.fetchProfileData();
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    userProfileStream = userInfoService.fetchProfileData();
    showWait = false;
  }

  void UpdateData() {
    userInfoService.updateUser(UserModel(name: controllers[0].text,
        username: controllers[1].text,
        bio: controllers[2].text), () {context.pop();    showWait = false;});
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
          child: showWait ? Center(child: CircularProgressIndicator()) : StreamBuilder<UserModel?>(
              stream: userProfileStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  UserModel? userProfile = snapshot.data;
                  controllers[0] = new TextEditingController(text: userProfile?.name ?? '');
                  controllers[1] = new TextEditingController(text: userProfile?.username ?? '');
                  controllers[2] = new TextEditingController(text: userProfile?.bio ?? '');

                  return Column(
                      children: [
                        Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                InkWell(
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 35,
                                    color: AppColors.white,
                                  ),
                                  onTap: () {
                                    context.pop();
                                  },
                                ),
                                Container(
                                  width: 200,
                                  child: Text(
                                    "Edit Profile", textAlign: TextAlign.center,
                                    style: ref
                                        .watch(stylesProvider)
                                        .text
                                        .titleOnBoarding
                                        .copyWith(fontSize: 28),),),
                                InkWell(
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 35,
                                    color: AppColors.white,
                                  ),
                                  onTap: () {
                                    UpdateData();
                                    setState(() {
                                      showWait = true;
                                    });
                                    },
                                ),
                              ],)),
                        SizedBox(height: 10,),
                        Stack(children: [
                          Container(
                            color: AppColors.whiteShadow,
                            height: screenHeight / 600,),
                          Center(child: Container(color: AppColors.white,
                            height: screenHeight / 400,
                            width: screenWidth / 2.5,))
                        ],),
                        SizedBox(height: 30),
                        Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            Column(
                              children: [
                                Stack(children: [
                                  CircleAvatar(
                                    radius: 70,
                                    backgroundImage: userProfile?.imageUrl !=
                                        null
                                        ? NetworkImage(
                                        userProfile!.imageUrl ?? '')
                                        : null,
                                    child: userProfile?.imageUrl == null
                                        ? Text(userProfile?.name != null
                                        ? userProfile!.name![0]
                                        : '', style: ref
                                        .watch(stylesProvider)
                                        .text
                                        .titleOnBoarding
                                        .copyWith(fontSize: 50),)
                                        : null,
                                  ),
                                  Container(margin: EdgeInsets.only(
                                      top: 105, left: 100),
                                    width: 30,
                                    height: 30,
                                    child: Icon(Icons.add_a_photo_rounded, size: 30, color: AppColors.white,))
                                ],),
                                SizedBox(height: 40),
                                Container(
                                  margin: EdgeInsets.only(left: 35),
                                  color: AppColors.whiteShadow,
                                  height: screenHeight / 600,),
                                SizedBox(height: 25),
                                Padding(padding: EdgeInsets.only(left: 35), child: Row(
                                  children: [
                                    Text(
                                      "Name",
                                      style: ref
                                          .watch(stylesProvider)
                                          .text
                                          .titleOnBoarding
                                          .copyWith(fontSize: 20),
                                    ),
                                    SizedBox(width: 90),
                                    Container(width: 200, child: TextField(
                                      autocorrect: false,
                                      controller: controllers[0],
                                      keyboardType: TextInputType.name,
                                      maxLength: 15,
                                      textAlign: TextAlign.left,
                                      decoration: InputDecoration(
                                        hintText: "Write your name...",
                                        hintStyle: ref
                                            .watch(stylesProvider)
                                            .text
                                            .editProfile.copyWith(color: AppColors.whiteShadow55),
                                        counterText: "",
                                        border: InputBorder.none,
                                        errorText: hasError[0] ? 'Value can\'t be empty' : null,
                                      ),
                                      style: ref
                                          .watch(stylesProvider)
                                          .text
                                          .editProfile,
                                      cursorColor: AppColors.white,
                                    )),
                                  ],
                                ),),
                                SizedBox(height: 25),
                                Container(
                                  margin: EdgeInsets.only(left: 35),
                                  color: AppColors.whiteShadow,
                                  height: screenHeight / 600,),
                                SizedBox(height: 25),
                                Padding(padding: EdgeInsets.only(left: 35), child: Row(
                                  children: [
                                    Text(
                                      "Username",
                                      style: ref
                                          .watch(stylesProvider)
                                          .text
                                          .titleOnBoarding
                                          .copyWith(fontSize: 20),
                                    ),
                                    SizedBox(width: 50),
                                    Container(width: 200 ,child: TextField(
                                      autocorrect: false,
                                      controller: controllers[1],
                                      keyboardType: TextInputType.name,
                                      maxLength: 15,
                                      textAlign: TextAlign.left,
                                      decoration: InputDecoration(
                                        hintText: "Write your username...",
                                        hintStyle: ref
                                            .watch(stylesProvider)
                                            .text
                                            .editProfile.copyWith(color: AppColors.whiteShadow55),
                                        counterText: "",
                                        border: InputBorder.none,
                                        errorText: hasError[0] ? 'Value can\'t be empty' : null,
                                      ),
                                      style: ref
                                          .watch(stylesProvider)
                                          .text
                                          .editProfile,
                                      cursorColor: AppColors.white,
                                    )),
                                  ],
                                ),),
                                SizedBox(height: 25),
                                Container(
                                  margin: EdgeInsets.only(left: 35),
                                  color: AppColors.whiteShadow,
                                  height: screenHeight / 600,),
                                SizedBox(height: 25),
                                Padding(padding: EdgeInsets.only(left: 35), child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(padding: EdgeInsets.only(top: 15), child: Text(
                                      "Bio",
                                      style: ref
                                          .watch(stylesProvider)
                                          .text
                                          .titleOnBoarding
                                          .copyWith(fontSize: 20),
                                    )),
                                    SizedBox(width: 115),
                                    Container(width: 200, height: 120, child: TextField(
                                      autocorrect: false,
                                      controller: controllers[2],
                                      keyboardType: TextInputType.multiline,
                                      minLines: 1,
                                      maxLines: 3,
                                      maxLength: 60,
                                      textAlign: TextAlign.left,
                                      decoration: InputDecoration(
                                        counterText: "",
                                        border: InputBorder.none,
                                        hintText: "Write your bio...",
                                        hintStyle: ref
                                            .watch(stylesProvider)
                                            .text
                                            .editProfile.copyWith(color: AppColors.whiteShadow55),
                                        errorText: hasError[0] ? 'Value can\'t be empty' : null,
                                      ),
                                      style: ref
                                          .watch(stylesProvider)
                                          .text
                                          .editProfile.copyWith(height: 1.5),
                                      cursorColor: AppColors.white,
                                    )),
                                  ],
                                ),),
                              ],
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              child: Container(
                                color: Colors.transparent,
                                width: screenWidth / 2,
                                height: screenHeight / 5.5,),
                              onTap: () {},),
                          ],
                        ),
                      ]
                  );
                } else {
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