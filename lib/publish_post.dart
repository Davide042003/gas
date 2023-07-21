import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gas/styles/colors.dart';
import 'package:gas/core/ui/anon_appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:ionicons/ionicons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'core/models/post_service.dart';
import 'core/models/post_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublishPostPage extends ConsumerStatefulWidget {
  final VoidCallback goToInitialPage;

  PublishPostPage({required this.goToInitialPage});

  @override
  _PublishPostPageState createState() => _PublishPostPageState();
}

class _PublishPostPageState extends ConsumerState<PublishPostPage> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  final PostService postService =
      PostService(userId: FirebaseAuth.instance.currentUser?.uid ?? '');

  bool myFriends = true;
  bool isPics = true;
  bool isAnonymous = false;
  bool extraText = false;

  XFile? _selectedImage_1;
  XFile? _selectedImage_2;

  TextEditingController questionController = TextEditingController();

  bool isPublishing = false;

  List<TextEditingController> controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    controllers[0].text = "Si";
    controllers[1].text = "No";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _showImagePicker(BuildContext context, bool containerLeft) {
    print("open action sheet photo profile");
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text('Select Photo'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                context.pop();
                _pickImage(ImageSource.gallery, containerLeft);
              },
              child: Text('Choose from Gallery'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                context.pop();
                _pickImage(ImageSource.camera, containerLeft);
              },
              child: Text('Take a Photo'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              context.pop();
            },
            child: Text('Cancel'),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source, bool containerLeft) async {
    final picker = ImagePicker();

    final XFile? pickedFile = await picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 2);

    if (pickedFile != null) {
      print("got image");

      if (containerLeft) {
        setState(() {
          _selectedImage_1 = pickedFile;
          print("image 1 got");
        });
      } else {
        setState(() {
          _selectedImage_2 = pickedFile;
        });
      }

      // You can pass the imageFile to the next step or store it in a variable or state
    } else {
      // User canceled the image selection
      print("no image");
    }
  }

  bool checkIfCanPublish() {
    if (questionController.text.isNotEmpty) {
      if (isPics) {
        if (_selectedImage_1 != null && _selectedImage_2 != null) {
          return true;
        }
      } else {
        if (extraText == false) {
          if (controllers[0].text.isNotEmpty &&
              controllers[1].text.isNotEmpty) {
            return true;
          }
        } else {
          if (controllers[0].text.isNotEmpty &&
              controllers[1].text.isNotEmpty &&
              controllers[2].text.isNotEmpty) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<void> publishPost() async {

    setState(() {
      isPublishing = true;
    });

    List<List<String>> tapsAnswers = [[], []];

    if (isPics) {
      List<String> imagesList = [];
      imagesList.add(await postService.saveImage(File(_selectedImage_1!.path)));
      imagesList.add(await postService.saveImage(File(_selectedImage_2!.path)));

      await postService.publishPost(PostModel(
        id: userId,
        question: questionController.text,
        images: imagesList,
        answersList: [],
        isAnonymous: isAnonymous,
        isMyFriends: myFriends,
        answersTap: tapsAnswers,
        timestamp: Timestamp.now(),
      ));
    } else {
      List<String> answersList = [];
      answersList.add(controllers[0].text);
      answersList.add(controllers[1].text);

      if (extraText) {
        answersList.add(controllers[2].text);
        tapsAnswers.add([]);
      }

      await postService.publishPost(PostModel(
        id: userId,
        question: questionController.text,
        images: [],
        answersList: answersList,
        isAnonymous: isAnonymous,
        isMyFriends: myFriends,
        answersTap: tapsAnswers,
        timestamp: Timestamp.now(),
      ));
    }

    setState(() {
      isPublishing = false;
    });
    widget.goToInitialPage();

  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
        backgroundColor: isPublishing ? AppColors.backgroundDefault : AppColors.white,
        body: isPublishing ? Center(child:CircularProgressIndicator()) : Column(
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
                  height: screenHeight / 12,
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
                        controller: questionController,
                        onChanged: (_) => setState(() {}),
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
                            fontSize: 24)),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    final Offset initialOffset = isPics
                        ? const Offset(-1.0, 0.0)
                        : const Offset(1.0, 0.0);
                    return SlideTransition(
                      position:
                          Tween<Offset>(begin: initialOffset, end: Offset.zero)
                              .animate(animation),
                      child: child,
                    );
                  },
                  child: isPics
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              child: Container(
                                width: screenWidth / 2.3,
                                height: screenHeight / 4,
                                decoration: BoxDecoration(
                                  image: _selectedImage_1 != null
                                      ? DecorationImage(
                                          image: AssetImage(
                                              _selectedImage_1!.path),
                                          fit: BoxFit.cover)
                                      : null,
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                // Add your content for the first white container here
                              ),
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                _showImagePicker(context, true);
                              },
                            ),
                            GestureDetector(
                              child: Container(
                                width: screenWidth / 2.3,
                                height: screenHeight / 4,
                                decoration: BoxDecoration(
                                  image: _selectedImage_2 != null
                                      ? DecorationImage(
                                          image: AssetImage(
                                              _selectedImage_2!.path),
                                          fit: BoxFit.cover)
                                      : null,
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                // Add your content for the first white container here
                              ),
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                _showImagePicker(context, false);
                              },
                            ),
                          ],
                        )
                      : Container(
                          width: screenWidth,
                          height: screenHeight / 4,
                          margin: EdgeInsets.symmetric(horizontal: 30),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: screenWidth / 8,
                                    height: screenWidth / 8,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12))),
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Container(
                                    width: screenWidth / 1.5,
                                    height: screenHeight / 40,
                                    child: TextField(
                                        maxLines: 1,
                                        textAlign: TextAlign.left,
                                        textAlignVertical:
                                            TextAlignVertical.bottom,
                                        controller: controllers[0],
                                        onChanged: (_) => setState(() {}),
                                        decoration: InputDecoration.collapsed(
                                          hintText: 'Scrivi la tua risposta...',
                                          hintStyle: TextStyle(
                                              fontFamily: 'Helvetica',
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.whiteShadow55,
                                              fontSize: 20),
                                        ),
                                        style: TextStyle(
                                            fontFamily: 'Helvetica',
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.white,
                                            fontSize: 20)),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 30,
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: screenWidth / 8,
                                    height: screenWidth / 8,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12))),
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Container(
                                    width: screenWidth / 1.5,
                                    height: screenHeight / 40,
                                    child: TextField(
                                        maxLines: 1,
                                        textAlign: TextAlign.left,
                                        textAlignVertical:
                                            TextAlignVertical.bottom,
                                        controller: controllers[1],
                                        onChanged: (_) => setState(() {}),
                                        decoration: InputDecoration.collapsed(
                                          hintText: 'Scrivi la tua risposta...',
                                          hintStyle: TextStyle(
                                              fontFamily: 'Helvetica',
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.whiteShadow55,
                                              fontSize: 20),
                                        ),
                                        style: TextStyle(
                                            fontFamily: 'Helvetica',
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.white,
                                            fontSize: 20)),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 30,
                              ),
                              extraText
                                  ? Row(
                                      children: [
                                        Container(
                                          width: screenWidth / 8,
                                          height: screenWidth / 8,
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(12))),
                                        ),
                                        SizedBox(
                                          width: 20,
                                        ),
                                        Container(
                                          width: screenWidth / 1.5,
                                          height: screenHeight / 40,
                                          child: TextField(
                                              maxLines: 1,
                                              textAlign: TextAlign.left,
                                              textAlignVertical:
                                                  TextAlignVertical.bottom,
                                              controller: controllers[2],
                                              onChanged: (_) => setState(() {}),
                                              decoration:
                                                  InputDecoration.collapsed(
                                                hintText:
                                                    'Scrivi la tua risposta...',
                                                hintStyle: TextStyle(
                                                    fontFamily: 'Helvetica',
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppColors.whiteShadow55,
                                                    fontSize: 20),
                                              ),
                                              style: TextStyle(
                                                  fontFamily: 'Helvetica',
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.white,
                                                  fontSize: 20)),
                                        ),
                                      ],
                                    )
                                  : Row(children: [
                                      InkWell(
                                          onTap: () {
                                            setState(() {
                                              extraText = true;
                                            });
                                          },
                                          child: Container(
                                            width: screenWidth / 8,
                                            height: screenWidth / 8,
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(12))),
                                            child: Center(
                                                child: Text(
                                              "+",
                                              style: TextStyle(
                                                  fontFamily: 'Helvetica',
                                                  fontSize: 33,
                                                  fontWeight: FontWeight.bold),
                                            )),
                                          ))
                                    ]),
                            ],
                          ),
                        ),
                ),
                SizedBox(
                  height: 115,
                ),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 45,
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              if (isAnonymous == true) {
                                isAnonymous = false;
                              } else {
                                isAnonymous = true;
                              }
                            });
                          },
                          icon: Icon(
                            isAnonymous ? Ionicons.eye_off : Ionicons.eye,
                            size: 40,
                            color: AppColors.white,
                          ),
                          label: Text(
                            isAnonymous ? "ANONYMOUS" : "VISIBLE",
                            style: ref
                                .watch(stylesProvider)
                                .text
                                .invite
                                .copyWith(fontSize: 17),
                          ),
                          style: ElevatedButton.styleFrom(
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.transparent),
                        ),
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
                        checkIfCanPublish()
                            ? InkWell(
                                onTap: () async {
                                  publishPost();
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
                              )
                            : SizedBox(),
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
