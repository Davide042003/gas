import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gas/styles/colors.dart';
import 'package:gas/core/ui/anon_appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:ionicons/ionicons.dart';

class HomeScreen extends ConsumerStatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
        child: Column(
            children: [
              Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(onPressed: () {}, child: Text("Chat", style: ref
                      .watch(stylesProvider)
                      .text
                      .appBarHome)),
                  Container(margin: EdgeInsets.only(left: 25),
                    child: Image.asset('assets/img/logo.png', height: 40),
                    width: 100,),
                  TextButton(onPressed: () {}, child: Text("Profile", style: ref
                      .watch(stylesProvider)
                      .text
                      .appBarHome)),
                ],)),
              Stack(children: [
                Container(
                  color: AppColors.whiteShadow, height: screenHeight / 600,),
                Center(child: Container(color: AppColors.white,
                  height: screenHeight / 400,
                  width: screenWidth / 3,))
              ],),
              Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Container(child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(onPressed: () {},
                          icon: Icon(Ionicons.people, color: AppColors.white,
                            size: 28,)),
                      SizedBox(width: screenWidth/9,),
                      TextButton(
                          onPressed: () {}, child: Text("My Friends", style: ref
                          .watch(stylesProvider)
                          .text
                          .numberContactOnBoarding
                          .copyWith(color: AppColors.white))),
                      TextButton(
                          onPressed: () {}, child: Text("Global", style: ref
                          .watch(stylesProvider)
                          .text
                          .numberContactOnBoarding)),
                    ],))),
              Spacer(),
              Padding(padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          IconButton(onPressed: () {},
                              icon: Icon(Ionicons.eye, color: AppColors.white,
                                size: 32,)),
                          Text("ANONYMOUS", style: ref.watch(stylesProvider).text.invite)
                        ],
                      ),
                      Spacer(),
                      IconButton(onPressed: () {},
                          icon: Icon(Ionicons.play, color: AppColors.white,
                            size: 28,)),
                      Text("Skip", style: ref.watch(stylesProvider).text.skipHome,)
                    ],))),
            ]
        ),
      ),
    );
  }
}
