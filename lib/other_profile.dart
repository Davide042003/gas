import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gas/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/models/user_model.dart';
import 'core/models/user_info_service.dart';
import 'package:flutter/cupertino.dart';

class OtherProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  OtherProfileScreen({required this.userId});

  @override
  _OtherProfileScreenState createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends ConsumerState<OtherProfileScreen> {

  @override
  void initState() {
    super.initState();
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
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
              stream:  UserInfoService().fetchOtherProfileData(widget.userId),
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
                                  width: 200,
                                  child: Text(
                                    userProfile?.username ?? '', textAlign: TextAlign.center,
                                    style: ref
                                        .watch(stylesProvider)
                                        .text
                                        .titleOnBoarding
                                        .copyWith(fontSize: 28),),),
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