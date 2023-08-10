import 'package:country_picker/country_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gas/styles/colors.dart';
import 'dart:async';

import '../core/ui/anon_appbar_widget.dart';
import '../styles/styles_provider.dart';

import 'package:gas/core/models/phone_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gas/core/models/user_info_service.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:gas/core/models/user_model.dart';

import 'package:go_router/go_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.step});

  final int step;

  @override
  ConsumerState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int step = 0;
  Country country = CountryParser.parseCountryCode('IT');

  List<String> titles = [
    "What's your Name?",
    "#name, what's your Phone Number?",
    "Enter the code we sent to #phone",
    "#name, choose a Username",
  ];

  List<String> placeholders = [
    "Your name",
    "Phone Number",
    "••••••",
    "Your username"
  ];

  List<TextEditingController> controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController()
  ];

  List<bool> hasError = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    step = widget.step;
  }

  int countdownSeconds = 45; // Initial countdown time in seconds
  bool isCountdownActive = false; // Flag to track countdown state
  Timer? countdownTimer; // Timer object
  String _verificationId = '';
  List<Contact> _contacts = [];
  String phoneNumber = '';

  void _onCodeSent(String verificationId) {
    setState(() {
      _verificationId = verificationId;

      titles[step + 1] = titles[step + 1].replaceAll(
          "#phone", '+${country.phoneCode} ${controllers[step].text}');
      //           ref.refresh(phoneVerificationProvider);
      step = step + 1;
      startCountdown();
    });
  }

  void _onCodeSentReAsked(String verificationId) {
    setState(() {
      _verificationId = verificationId;

      startCountdown();
    });
  }

  void _signInWithCredential() async {
    String otp = controllers[2].text;
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId, smsCode: otp);
    try {
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        UserModel? existingUser =
        await UserInfoService().fetchProfileDataRegistration();

        if (existingUser != null) {
          context.push("/");
        } else {
          // Account does not exist, prompt the user to provide a username
          titles[step + 1] =
              titles[step + 1].replaceAll("#name", controllers[0].text);
          step = step + 1;
        }
      }
    } on FirebaseAuthException catch (e) {
      print("invalid OTP");
      // Invalid OTP
    }
  }

  void startCountdown() {
    stopCountdown();
    isCountdownActive = true;
    countdownSeconds = 45;
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (countdownSeconds > 0) {
          countdownSeconds--;
        } else {
          stopCountdown();
        }
      });
    });
  }

  void stopCountdown() {
    if (countdownTimer != null) {
      countdownTimer!.cancel();
      countdownTimer = null;
    }
    setState(() {
      isCountdownActive = false;
    });
  }

  Future<Iterable<Contact>> getContacts() async {
    // Request permission to access contacts
    PermissionStatus permissionStatus = await Permission.contacts.request();
    print("ask permission");

    if (permissionStatus.isGranted) {
      // Permission granted, retrieve contacts
      Iterable<Contact> contacts = await ContactsService.getContacts();
      print("permission contacts given");
      return contacts;
    } else {
      print("no permission contacts");
      // Permission denied, handle accordingly (show error message, etc.)
      return [];
    }
  }

  void contactsToList() {
    getContacts().then((contacts) {
      setState(() {
        _contacts = contacts.toList();
      });
    });
  }

  Widget _step1() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: EdgeInsets.only(top: screenHeight / 6, left: 20, right: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(titles[step],
                  style: ref.watch(stylesProvider).text.titleOnBoarding,
                  textAlign: TextAlign.center),
              Padding(
                padding: EdgeInsets.only(top: screenHeight / 80),
                child: TextField(
                  autofocus: true,
                  autocorrect: false,
                  controller: controllers[step],
       //           keyboardType: TextInputType.,
                  maxLength: 25,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    counterText: "",
                    border: InputBorder.none,
                    hintText: placeholders[step],
                    hintStyle: ref.watch(stylesProvider).text.hintOnBoarding,
                    errorText: hasError[step] ? 'Value can\'t be empty' : null,
                  ),
                  style: ref.watch(stylesProvider).text.bodyOnBoarding,
                  cursorColor: AppColors.brown,
                ),
              ),
            ],
          ),
        ),
        Padding(
            padding: EdgeInsets.symmetric(
                vertical: 20, horizontal: screenWidth / 20),
            child: ElevatedButton(
                style: ref.watch(stylesProvider).button.buttonOnBoarding,
                onPressed: () {
                  if (controllers[step].text.isNotEmpty) {
                    setState(() {
                      titles[step + 1] = titles[step + 1]
                          .replaceAll("#name", controllers[step].text);
                      step = step + 1;
                    });
                  } else {
                    setState(() {
                      hasError[step] = true;
                    });
                  }
                },
                child: const Text('Continue'))),
      ],
    );
  }

  Widget _step2() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: EdgeInsets.only(top: screenHeight / 6, left: 20, right: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(titles[step],
                  style: ref.watch(stylesProvider).text.titleOnBoarding,
                  textAlign: TextAlign.center),
              Padding(
                padding: EdgeInsets.only(top: screenHeight / 100),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        ElevatedButton(
                            onPressed: () {
                              showCountryPicker(
                                countryListTheme: CountryListThemeData(
                                  backgroundColor: AppColors.backgroundDefault,
                                  textStyle: ref
                                      .watch(stylesProvider)
                                      .text
                                      .policyOnBoarding,
                                  padding: null,
                                ),
                                context: context,
                                showPhoneCode:
                                    true, // optional. Shows phone code before the country name.
                                onSelect: (Country country) {
                                  setState(() {
                                    this.country = country;
                                  });
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                elevation: 0),
                            child: Text(country.flagEmoji,
                                style: const TextStyle(fontSize: 30),
                                textAlign: TextAlign.right)),
                      ],
                    ),
                    SizedBox(
                      width: screenWidth / 2.2,
                      child: TextField(
                        autofocus: true,
                        controller: controllers[step],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        decoration: InputDecoration(
                            counterText: "",
                            border: InputBorder.none,
                            hintText: placeholders[step],
                            hintStyle:
                                ref.watch(stylesProvider).text.hintOnBoarding,
                            errorText: hasError[step]
                                ? 'Phone Number Not Valid'
                                : null,
                            errorStyle:
                                ref.watch(stylesProvider).text.errorOnBoarding),
                        style: ref.watch(stylesProvider).text.bodyOnBoarding,
                        cursorColor: AppColors.brown,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
            padding: EdgeInsets.symmetric(
                vertical: 20, horizontal: screenWidth / 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                        style: ref.watch(stylesProvider).text.policyOnBoarding,
                        children: [
                          TextSpan(
                            text: 'By tapping "Continue", you agree to our ',
                            style:
                                ref.watch(stylesProvider).text.policyOnBoarding,
                          ),
                          TextSpan(
                              text: 'Privacy Policy',
                              style: ref
                                  .watch(stylesProvider)
                                  .text
                                  .policyOnBoardingBold,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  print('Privacy Policy');
                                }),
                          TextSpan(
                              text: ' and ',
                              style: ref
                                  .watch(stylesProvider)
                                  .text
                                  .policyOnBoarding),
                          TextSpan(
                              text: 'Terms of Service',
                              style: ref
                                  .watch(stylesProvider)
                                  .text
                                  .policyOnBoardingBold,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  print('Terms of Service ');
                                }),
                        ])),
                SizedBox(
                  height: screenHeight / 100,
                ),
                ElevatedButton(
                    style: ref.watch(stylesProvider).button.buttonOnBoarding,
                    onPressed: () {
                      if (controllers[step].text.length == 10) {
                        phoneNumber = "+" + country.phoneCode + controllers[step].text;
                        PhoneAuthService()
                            .verifyPhoneNumber(phoneNumber, _onCodeSent);
                      } else {
                        setState(() {
                          hasError[step] = true;
                        });
                      }
                    },
                    child: const Text('Continue'))
              ],
            )),
      ],
    );
  }

  Widget _step3() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: EdgeInsets.only(top: screenHeight / 6, left: 20, right: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(titles[step],
                  style: ref.watch(stylesProvider).text.titleOnBoarding,
                  textAlign: TextAlign.center),
              TextField(
                autofocus: true,
                controller: controllers[step],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                maxLength: 6,
                onChanged: (value) => {
                  if (value.length == 6) _signInWithCredential()
                  //   ref.read(phoneVerificationProvider.notifier).verifyPhoneNumber(controllers[step].text)
                },
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: "",
                  border: InputBorder.none,
                  hintText: placeholders[step],
                  hintStyle: ref
                      .watch(stylesProvider)
                      .text
                      .hintOnBoarding
                      .copyWith(fontSize: 45, fontWeight: FontWeight.bold),
                  errorText: hasError[step] ? 'Value can\'t be empty' : null,
                ),
                style: ref.watch(stylesProvider).text.bodyOnBoarding,
                cursorColor: AppColors.brown,
              ),
            ],
          ),
        ),
        Padding(
            padding: EdgeInsets.only(
                bottom: 20, left: screenWidth / 20, right: screenWidth / 20),
            child: Column(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      step = step - 1;
                    });
                  },
                  child: Text('Change the phone number',
                      style:
                          ref.read(stylesProvider).text.policyOnBoardingBold),
                ),
                SizedBox(height: screenHeight / 50),
                ElevatedButton(
                    style: ref.watch(stylesProvider).button.buttonOnBoarding,
                    onPressed: isCountdownActive
                        ? null
                        : () {
                            String phoneNumber =
                                "+" + country.phoneCode + controllers[1].text;
                            PhoneAuthService().verifyPhoneNumber(
                                phoneNumber, _onCodeSentReAsked);
                          },
                    child: Text(
                      isCountdownActive
                          ? 'Resend in $countdownSeconds seconds' // Show countdown
                          : 'Resend Code',
                    ))
              ],
            )),
      ],
    );
  }

  Widget _step4() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: EdgeInsets.only(top: screenHeight / 6, left: 20, right: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(titles[step],
                  style: ref.watch(stylesProvider).text.titleOnBoarding,
                  textAlign: TextAlign.center),
              Padding(
                padding: EdgeInsets.only(top: screenHeight / 80),
                child: TextField(
                  autofocus: true,
                  autocorrect: false,
                  controller: controllers[step],
                  keyboardType: TextInputType.name,
                  maxLength: 10,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    counterText: "",
                    border: InputBorder.none,
                    hintText: placeholders[step],
                    hintStyle: ref.watch(stylesProvider).text.hintOnBoarding,
                    errorText: hasError[step] ? 'Value can\'t be empty' : null,
                  ),
                  style: ref.watch(stylesProvider).text.bodyOnBoarding,
                  cursorColor: AppColors.brown,
                ),
              ),
            ],
          ),
        ),
        Padding(
            padding: EdgeInsets.symmetric(
                vertical: 20, horizontal: screenWidth / 20),
            child: ElevatedButton(
                style: ref.watch(stylesProvider).button.buttonOnBoarding,
                onPressed: () {
                  if (controllers[step].text.isNotEmpty) {
                    String? userId = FirebaseAuth.instance.currentUser?.uid;
                    if (userId != null) {
                      phoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

                      UserInfoService().storeUserInfo(
                        UserModel(
                          id: userId,
                          name: controllers[0].text,
                          username: controllers[3].text,
                          phoneNumber: phoneNumber,
                          imageUrl: "",
                          timestamp: Timestamp.now(),
                        ),
                      );
                    } else {
                      print('User not logged in.');
                    }
                    setState(() {
                      step = step + 1;
                      contactsToList();
                    });
                  } else {
                    setState(() {
                      hasError[step] = true;
                    });
                  }
                },
                child: const Text('Continue'))),
      ],
    );
  }

  Widget _step5() {
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    double screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return Stack(
      children: [
        Padding(padding: EdgeInsets.only(top: screenHeight / 14, bottom: screenHeight / 30),
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: screenHeight/15),
            itemCount: _contacts.length,
            itemBuilder: (context, index) {
              Contact contact = _contacts[index];
              if (contact.phones != null &&
              contact.phones!.isNotEmpty &&
              contact.displayName != null &&
              contact.displayName!.isNotEmpty) {

                String? initials = "";
                if (contact.familyName != null && contact.familyName!.isNotEmpty){
                  initials = contact.displayName![0].toUpperCase() + contact.familyName![0].toUpperCase();
                }else {
                  initials = contact.displayName![0].toUpperCase() + contact.displayName![1].toUpperCase();
                }

                return Container(
                  padding: EdgeInsets.only(
                      left: 20, right: 20, top: 13, bottom: 13),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            CircleAvatar(
                              maxRadius: 38,
                              child: Text(
                                  initials,
                                  style: TextStyle(
                                      fontFamily: 'Helvetica',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: AppColors.white)
                              ),
                            ),
                            SizedBox(width: 16,),
                            Expanded(
                              child: Container(
                                color: Colors.transparent,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(contact.displayName ?? '', style: ref
                                        .watch(stylesProvider)
                                        .text
                                        .contactOnBoarding,),
                                    SizedBox(height: 6,),
                                    Text(contact.phones![0].value.toString(),
                                      style: ref
                                          .watch(stylesProvider)
                                          .text
                                          .numberContactOnBoarding,),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(height: screenHeight / 30,
                          child: ElevatedButton(onPressed: () {}, style: ref
                              .watch(stylesProvider)
                              .button
                              .buttonInvite, child: const Text("INVITE"),))
                    ],
                  ),
                );
              }else{
                return SizedBox();
              }
            },
          ),),
        Align(alignment: Alignment.bottomCenter,
            child: Container(
                height: screenHeight / 10,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.backgroundDefault,
                      spreadRadius: 5,
                      blurRadius: 45,
                      offset: Offset(0, 2), // changes position of shadow
                    ),
                  ],
                )
            )),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
              padding: EdgeInsets.only(
                  left: screenWidth / 20,
                  right: screenWidth / 20,
                  bottom: screenHeight / 42),
              child: ElevatedButton(
                  style: ref
                      .watch(stylesProvider)
                      .button
                      .buttonOnBoarding,
                  onPressed: () {
                    context.push("/");
                  },
                  child: const Text('Continue'))),
        ),
        Container(height: screenHeight / 18,
          margin: EdgeInsets.only(left: screenWidth / 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("CONTACTS USING BEREAL", style: ref
                  .watch(stylesProvider)
                  .text
                  .textInfoContactOnBoarding),
              Text("INVITE YOUR CONTACTS", style: ref
                  .watch(stylesProvider)
                  .text
                  .textInfoContactOnBoarding),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDefault,
        extendBodyBehindAppBar: true,
        appBar: const AnonAppBar(),
        body: SafeArea(
            child: Center(
          child: _renderStep(),
        )),
      ),
    );
  }

  Widget _renderStep() {
    switch (step) {
      case 0:
        return _step1();
      case 1:
        return _step2();
      case 2:
        return _step3();
      case 3:
        return _step4();
      case 4:
        return _step5();
      default:
        return _step1();
    }
  }
}
