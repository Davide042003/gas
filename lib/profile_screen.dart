import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gas/styles/colors.dart';
import 'package:gas/core/ui/anon_appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:ionicons/ionicons.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {

  Color color = AppColors.backgroundDefault;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset the background color every time the page is displayed
    color = AppColors.backgroundDefault; // Set the initial background color
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
      backgroundColor: color,
      body: SafeArea(
        child: Column(
            children: [
              Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 35,
                      color: AppColors.white,
                    ),
                    onTap: () {context.pop();},
                  ),
                  Container(
                    child: Text("Profile", textAlign:TextAlign.center, style: ref.watch(stylesProvider).text.titleOnBoarding.copyWith(fontSize: 28),),
                    width: 100,),
                  InkWell(
                    child: Icon(
                      Icons.settings,
                      size: 35,
                      color: AppColors.white,
                    ),
                    onTap: () {context.pop();},
                  ),
                ],)),
              SizedBox(height: 10,),
              Stack(children: [
                Container(
                  color: AppColors.whiteShadow, height: screenHeight / 600,),
                Center(child: Container(color: AppColors.white,
                  height: screenHeight / 400,
                  width: screenWidth / 3,))
              ],),
            ]
        ),
      ),
    );
  }
}