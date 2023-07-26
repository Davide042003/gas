import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gas/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/models/user_model.dart';
import 'core/models/user_info_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'user_notifier.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_native_image/flutter_native_image.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  List<TextEditingController> controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  final List<FocusNode> focusNodes = [
    FocusNode(),
    FocusNode(),
    FocusNode(),
  ];

  bool firstOpen = true;

  List<bool> hasError = [false, false, false];
  final userInfoService = UserInfoService();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    focusNodes[0].unfocus();
    focusNodes[1].unfocus();
    focusNodes[2].unfocus();

    super.dispose();
  }

  Future<void> UpdateData() async {
    await userInfoService.updateUser(
        UserModel(
          name: controllers[0].text,
          username: controllers[1].text,
          bio: controllers[2].text,
        ), () {
      context.pop();
    });

    ref.refresh(userProfileFutureProvider);
  }

  Future<void> UpdateProfilePic(File? imageGot) async {
    await userInfoService.updateUser(
        UserModel(
          imageUrl: imageGot != null
              ? await userInfoService.saveImage(imageGot)
              : null,
        ),
        () {});

    ref.refresh(userProfileFutureProvider);
  }

  void DeleteProfilePic() {
    userInfoService.updateUser(
        UserModel(
          imageUrl: "",
        ), () {
      print("changed");
    });

    ref.refresh(userProfileFutureProvider);
  }

  void _showImagePicker(BuildContext context, String? imageUrl) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text('Select Photo'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                context.pop();
                _pickImage(ImageSource.gallery, imageUrl);
              },
              child: Text('Choose from Gallery'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                context.pop();
                _pickImage(ImageSource.camera, imageUrl);
              },
              child: Text('Take a Photo'),
            ),
            if (imageUrl != "")
              CupertinoActionSheetAction(
                onPressed: () {
                  context.pop();
                  userInfoService.deleteImageProfile(imageUrl!);
                  DeleteProfilePic();
                },
                child: Text('Delete Profile Photo',
                    style: TextStyle(color: Colors.red)),
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

  Future<void> _pickImage(ImageSource source, String? imageUrl) async {
    final picker = ImagePicker();

    final XFile? pickedFile = await picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 2,
    );

    if (pickedFile != null) {
      imageUrl != "" ? userInfoService.deleteImageProfile(imageUrl!) : null;

      File compressedImage = await compressFile(File(pickedFile.path));
      UpdateProfilePic(compressedImage);
    } else {
      print("no image");
    }
  }

  Future<File> compressFile(File file) async{
    File compressedFile = await FlutterNativeImage.compressImage(file.path,
      quality: 1,);
    return compressedFile;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
        backgroundColor: AppColors.backgroundDefault,
        body: GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: SafeArea(
            child: Consumer(
              builder: (context, watch, child) {
                final userProfileAsyncValue =
                    ref.watch(userProfileFutureProvider);

                return userProfileAsyncValue.when(
                  data: (userProfile) {
                    if (userProfile != null) {
                      if (firstOpen) {
                        controllers[0] =
                            TextEditingController(text: userProfile.name ?? '');
                        controllers[1] = TextEditingController(
                            text: userProfile.username ?? '');
                        controllers[2] =
                            TextEditingController(text: userProfile.bio ?? '');

                        controllers[0].selection = TextSelection.collapsed(
                            offset: controllers[0].text.length);
                        controllers[1].selection = TextSelection.collapsed(
                            offset: controllers[1].text.length);
                        controllers[2].selection = TextSelection.collapsed(
                            offset: controllers[2].text.length);

                        firstOpen = false;
                      }

                      return Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
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
                                    "Edit Profile",
                                    textAlign: TextAlign.center,
                                    style: ref
                                        .watch(stylesProvider)
                                        .text
                                        .titleOnBoarding
                                        .copyWith(fontSize: 28),
                                  ),
                                ),
                                InkWell(
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 35,
                                    color: AppColors.white,
                                  ),
                                  onTap: () {
                                    UpdateData();
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 10,
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
                                    width: screenWidth / 2.5),
                              ),
                            ],
                          ),
                          Expanded(
                            child: ListView(
                              children: [
                                SizedBox(height: 30),
                                Stack(
                                  alignment: Alignment.topCenter,
                                  children: [
                                    Column(
                                      children: [
                                        Stack(
                                          children: [
                                            CircleAvatar(
                                              radius: 70,
                                              child: Stack(
                                                children: [
                                                  if (userProfile?.imageUrl !=
                                                          null &&
                                                      userProfile.imageUrl !=
                                                          "")
                                                    CachedNetworkImage(
                                                      imageUrl:
                                                          userProfile.imageUrl!,
                                                      imageBuilder: (context,
                                                              imageProvider) =>
                                                          Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          image:
                                                              DecorationImage(
                                                            image:
                                                                imageProvider,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                      progressIndicatorBuilder: (context,
                                                              url,
                                                              downloadProgress) =>
                                                          Center(
                                                              child: CircularProgressIndicator(
                                                                  value: downloadProgress
                                                                      .progress)),
                                                      errorWidget: (context,
                                                              url, error) =>
                                                          Icon(Icons.error),
                                                    ),
                                                  if (userProfile?.imageUrl ==
                                                          null ||
                                                      userProfile.imageUrl ==
                                                          "")
                                                    Center(
                                                      child: Text(
                                                        userProfile?.name !=
                                                                    null &&
                                                                userProfile
                                                                        .name !=
                                                                    ""
                                                            ? userProfile
                                                                .name![0]
                                                            : '',
                                                        style: ref
                                                            .watch(
                                                                stylesProvider)
                                                            .text
                                                            .titleOnBoarding
                                                            .copyWith(
                                                                fontSize: 50),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                                margin: EdgeInsets.only(
                                                    top: 105, left: 100),
                                                width: 30,
                                                height: 30,
                                                child: Icon(
                                                  Icons.add_a_photo_rounded,
                                                  size: 30,
                                                  color: AppColors.white,
                                                )),
                                          ],
                                        ),
                                        SizedBox(height: 40),
                                        Container(
                                          margin: EdgeInsets.only(left: 35),
                                          color: AppColors.whiteShadow,
                                          height: screenHeight / 600,
                                        ),
                                        SizedBox(height: 25),
                                        Padding(
                                          padding: EdgeInsets.only(left: 35),
                                          child: Row(
                                            children: [
                                              Text(
                                                "Name",
                                                style: ref
                                                    .watch(stylesProvider)
                                                    .text
                                                    .titleOnBoarding
                                                    .copyWith(fontSize: 20),
                                              ),
                                              SizedBox(width: 80),
                                              Container(
                                                width: 210,
                                                child: TextField(
                                                  autocorrect: false,
                                                  controller: controllers[0],
                                                  focusNode: focusNodes[0],
                                                  textInputAction: TextInputAction.done,
                                                  keyboardType:
                                                      TextInputType.name,
                                                  maxLength: 25,
                                                  textAlign: TextAlign.left,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        "Write your name...",
                                                    hintStyle: ref
                                                        .watch(stylesProvider)
                                                        .text
                                                        .editProfile
                                                        .copyWith(
                                                            color: AppColors
                                                                .whiteShadow55),
                                                    counterText: "",
                                                    border: InputBorder.none,
                                                    errorText: hasError[0]
                                                        ? 'Value can\'t be empty'
                                                        : null,
                                                  ),
                                                  style: ref
                                                      .watch(stylesProvider)
                                                      .text
                                                      .editProfile,
                                                  cursorColor: AppColors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 25),
                                        Container(
                                          margin: EdgeInsets.only(left: 35),
                                          color: AppColors.whiteShadow,
                                          height: screenHeight / 600,
                                        ),
                                        SizedBox(height: 25),
                                        Padding(
                                          padding: EdgeInsets.only(left: 35),
                                          child: Row(
                                            children: [
                                              Text(
                                                "Username",
                                                style: ref
                                                    .watch(stylesProvider)
                                                    .text
                                                    .titleOnBoarding
                                                    .copyWith(fontSize: 20),
                                              ),
                                              SizedBox(width: 40),
                                              Container(
                                                width: 210,
                                                child: TextField(
                                                  autocorrect: false,
                                                  controller: controllers[1],
                                                  focusNode: focusNodes[1],
                                                  textInputAction: TextInputAction.done,
                                                  keyboardType:
                                                      TextInputType.name,
                                                  maxLength: 15,
                                                  textAlign: TextAlign.left,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        "Write your username...",
                                                    hintStyle: ref
                                                        .watch(stylesProvider)
                                                        .text
                                                        .editProfile
                                                        .copyWith(
                                                            color: AppColors
                                                                .whiteShadow55),
                                                    counterText: "",
                                                    border: InputBorder.none,
                                                    errorText: hasError[0]
                                                        ? 'Value can\'t be empty'
                                                        : null,
                                                  ),
                                                  style: ref
                                                      .watch(stylesProvider)
                                                      .text
                                                      .editProfile,
                                                  cursorColor: AppColors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 25),
                                        Container(
                                          margin: EdgeInsets.only(left: 35),
                                          color: AppColors.whiteShadow,
                                          height: screenHeight / 600,
                                        ),
                                        SizedBox(height: 25),
                                        Padding(
                                          padding: EdgeInsets.only(left: 35),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 15),
                                                  child: Text(
                                                    "Bio",
                                                    style: ref
                                                        .watch(stylesProvider)
                                                        .text
                                                        .titleOnBoarding
                                                        .copyWith(fontSize: 20),
                                                  )),
                                              SizedBox(width: 105),
                                              Container(
                                                width: 210,
                                                height: 120,
                                                child: TextField(
                                                  autocorrect: false,
                                                  controller: controllers[2],
                                                  focusNode: focusNodes[2],
                                                  textInputAction: TextInputAction.done,
                                                  keyboardType:
                                                      TextInputType.multiline,
                                                  minLines: 1,
                                                  maxLines: 3,
                                                  maxLength: 60,
                                                  textAlign: TextAlign.left,
                                                  decoration: InputDecoration(
                                                    counterText: "",
                                                    border: InputBorder.none,
                                                    hintText:
                                                        "Write your bio...",
                                                    hintStyle: ref
                                                        .watch(stylesProvider)
                                                        .text
                                                        .editProfile
                                                        .copyWith(
                                                            color: AppColors
                                                                .whiteShadow55),
                                                    errorText: hasError[0]
                                                        ? 'Value can\'t be empty'
                                                        : null,
                                                  ),
                                                  style: ref
                                                      .watch(stylesProvider)
                                                      .text
                                                      .editProfile
                                                      .copyWith(height: 1.5),
                                                  cursorColor: AppColors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      child: Container(
                                        color: Colors.transparent,
                                        width: screenWidth / 2,
                                        height: screenHeight / 5.5,
                                      ),
                                      onTap: () => _showImagePicker(
                                          context, userProfile?.imageUrl),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Text('Error fetching profile data.'),
                  ),
                );
              },
            ),
          ),
        ));
  }
}
