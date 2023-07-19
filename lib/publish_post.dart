import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gas/styles/colors.dart';
import 'package:gas/core/ui/anon_appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:ionicons/ionicons.dart';
import 'package:go_router/go_router.dart';

class PublishPostPage extends ConsumerStatefulWidget {
  final VoidCallback goToInitialPage;

  PublishPostPage({required this.goToInitialPage});

  @override
  _PublishPostPageState createState() => _PublishPostPageState();
}

class _PublishPostPageState extends ConsumerState<PublishPostPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Container(
        height: screenHeight * 0.925,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30)),
          color: AppColors.backgroundDefault,
        ),
        child: SafeArea(
            child: Column(children: [
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    child: Icon(
                      Icons.close_rounded,
                      size: 35,
                      color: AppColors.white,
                    ),
                    onTap: () {
                      widget.goToInitialPage();
                    },
                  ),
                  SizedBox(
                    width: 75,
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 25),
                    child: Image.asset('assets/img/logo.png', height: 40),
                    width: 100,
                  ),
                ],
              )),
          SizedBox(
            height: 8,
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
              ))
            ],
          ),
          SizedBox(
            height: 18,
          ),
          Container(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Ask a Question to People",
                  style: ref
                      .watch(stylesProvider)
                      .text
                      .numberContactOnBoarding
                      .copyWith(color: AppColors.white)),
            ],
          )),
          Spacer(),
          Padding(
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
                      Text("ANONYMOUS",
                          style: ref.watch(stylesProvider).text.invite)
                    ],
                  ),
                  Spacer(),
                  ElevatedButton.icon(
                      icon: Icon(
                        Ionicons.play,
                        color: AppColors.white,
                        size: 28,
                      ),
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.transparent,
                        elevation: 0,
                      ),
                      label: Text("Skip",
                          style: ref.watch(stylesProvider).text.skipHome)),
                ],
              ))),
        ])),
      ),
    );
  }
}
