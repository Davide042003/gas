import 'package:country_picker/country_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gas/styles/colors.dart';

import '../core/ui/anon_appbar_widget.dart';
import '../styles/styles_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.step});

  final int step;

  @override
  ConsumerState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int step = 0;
  Country country = CountryParser.parseCountryCode('FR');

  List<String> titles = [
    "Enter your Phone Number",
    "Enter the Code we sent to #phone",
    "What's your Name?",
    "#name, choose your Username"
  ];

  List<String> placeholders = [
    "Phone Number",
    "••••••",
    "Your name",
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

  Widget _step1() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical:screenHeight/6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                titles[step],
                style: ref.watch(stylesProvider).text.titleOnBoarding,
              ),
              Padding(
                padding: EdgeInsets.only(top: screenHeight/100),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        ElevatedButton(
                            onPressed: () {
                              showCountryPicker(
                                countryListTheme: CountryListThemeData(backgroundColor: AppColors.white, textStyle: ref.watch(stylesProvider).text.policyOnBoarding.copyWith(color: Colors.black)),
                                context: context,
                                showPhoneCode: true, // optional. Shows phone code before the country name.
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
                            child: Text(country.flagEmoji, style: const TextStyle(fontSize: 30), textAlign: TextAlign.right)),
                      ],
                    ),
                    SizedBox(
                      width: screenWidth/2.2,
                      child: TextField(
                        controller: controllers[step],
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        decoration: InputDecoration(
                          counterText: "",
                          border: InputBorder.none,
                          hintText: placeholders[step],
                          hintStyle: ref.watch(stylesProvider).text.hintOnBoarding,
                          errorText: hasError[step] ? 'Phone Number Not Valid' : null,
                          errorStyle: ref.watch(stylesProvider).text.errorOnBoarding
                        ),
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
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: screenWidth/20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                        style: ref.watch(stylesProvider).text.policyOnBoarding,
                        children: [
                          TextSpan(text: 'By tapping "Continue", you agree to our ', style: ref.watch(stylesProvider).text.policyOnBoarding,),
                          TextSpan(
                              text: 'Privacy Policy',
                              style: ref.watch(stylesProvider).text.policyOnBoardingBold,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  print('Privacy Policy');
                                }),
                          TextSpan(text: ' and ', style: ref.watch(stylesProvider).text.policyOnBoarding),
                          TextSpan(
                              text: 'Terms of Service',
                              style: ref.watch(stylesProvider).text.policyOnBoardingBold,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  print('Terms of Service ');
                                }),
                        ])),
                SizedBox(
                  height: screenHeight/100,
                ),
                ElevatedButton(
                    style: ref.watch(stylesProvider).button.buttonOnBoarding,
                    onPressed: () {
                      if (controllers[step].text.isNotEmpty) {
                        setState(() {
                          titles[step + 1] =
                              titles[step + 1].replaceAll("#phone", '+${country.phoneCode} ${controllers[step].text}');
               //           ref.refresh(phoneVerificationProvider);
                          step = step + 1;
                        });
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

  Widget _step2() {
    return Column();
  }

  Widget _step3() {
    return Column();
  }

  Widget _step4() {
    return Column();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDefault,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
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
      default:
        return _step1();
    }
  }
}