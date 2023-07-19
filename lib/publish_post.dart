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
  bool myFriends = true;
  bool isPics = true;

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
        body: Column(
          children: [
            Container(
              height: screenHeight * 0.91,
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
                    SizedBox(
                      height: screenHeight/9,
                    ),
                    Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    height: screenHeight / 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.bottom,
                      decoration: InputDecoration.collapsed(
                        hintText: 'Scrivi la tua domanda...',
                        hintStyle: TextStyle(
                            fontFamily: 'Helvetica',
                            fontWeight: FontWeight.bold,
                            color: AppColors.whiteShadow55,
                            fontSize: 24),
                      ),
                      style: TextStyle(
                          fontFamily: 'Helvetica',
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                          fontSize: 24)
                    ),
                  ),
                ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        final Offset initialOffset =
                        isPics ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
                        return SlideTransition(
                          position: Tween<Offset>(begin: initialOffset, end: Offset.zero)
                              .animate(animation),
                          child: child,
                        );
                      },
                      child: isPics
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            width: screenWidth / 2.3,
                            height: screenHeight / 4,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            // Add your content for the first white container here
                          ),
                          Container(
                            width: screenWidth / 2.3,
                            height: screenHeight / 4,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            // Add your content for the second white container here
                          ),
                        ],
                      )
                          : Container(
                        width: screenWidth, // Adjust the width as needed
                        height: screenHeight / 4, // Adjust the height as needed
                        decoration: BoxDecoration(
                          color: Colors.grey, // Change the color to your desired background color
                          borderRadius: BorderRadius.circular(20),
                        ),
                        // Add your content for the single container here when isPics is false
                      ),
                    ),
                Spacer(),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: screenWidth / 1.8,
                          height: screenHeight / 16,
                          decoration: BoxDecoration(
                            color: AppColors.a,
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      myFriends = true;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: myFriends
                                          ? AppColors.brown
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(50),
                                        bottomLeft: Radius.circular(50),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "My Friends",
                                        style: TextStyle(
                                          fontFamily: 'Helvetica',
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      myFriends = false;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: myFriends
                                          ? Colors.transparent
                                          : AppColors.brown,
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(50),
                                        bottomRight: Radius.circular(50),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Global",
                                        style: TextStyle(
                                          fontFamily: 'Helvetica',
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        InkWell(
                          onTap: () {
                            print("publish post");
                          },
                          child: Container(
                            width: 55,
                            height: screenHeight / 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.white,
                            ),
                            child: Icon(
                              Ionicons.arrow_forward,
                              color: AppColors.brown,
                              size: 35,
                            ),
                          ),
                        ),
                      ],
                    ))),
              ])),
            ),
            Container(
              width: screenWidth,
              height: screenHeight / 15,
              child: isPics
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: screenWidth / 2.7,
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation:
                                0, // Set elevation to 0 to remove the button shadow
                            primary: Colors
                                .transparent, // Set transparent background color
                            onPrimary: Colors.black, // Set text color
                          ),
                          onPressed: () {
                            setState(() {
                              isPics = true;
                            });
                          },
                          child: Text(
                            "FOTO",
                            style: TextStyle(
                                fontFamily: "Helvetica",
                                fontSize: 20,
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            primary: Colors.transparent,
                            onPrimary: Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              isPics = false;
                            });
                          },
                          child: Text(
                            "TESTO",
                            style: TextStyle(
                                fontFamily: "Helvetica",
                                fontSize: 20,
                                color: Colors.black.withOpacity(.3),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: screenWidth / 7.5,
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation:
                                0, // Set elevation to 0 to remove the button shadow
                            primary: Colors
                                .transparent, // Set transparent background color
                            onPrimary: Colors.black, // Set text color
                          ),
                          onPressed: () {
                            setState(() {
                              isPics = true;
                            });
                          },
                          child: Text(
                            "FOTO",
                            style: TextStyle(
                                fontFamily: "Helvetica",
                                fontSize: 20,
                                color: Colors.black.withOpacity(.3),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            primary: Colors.transparent,
                            onPrimary: Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              isPics = false;
                            });
                          },
                          child: Text(
                            "TESTO",
                            style: TextStyle(
                                fontFamily: "Helvetica",
                                fontSize: 20,
                                color: isPics
                                    ? Colors.black.withOpacity(.3)
                                    : Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
            )
          ],
        ));
  }
}
