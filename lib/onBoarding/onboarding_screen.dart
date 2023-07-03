import 'package:country_picker/country_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../anon_appbar_widget.dart';

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
    return Column();
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
    return Scaffold(
      appBar: const AnonAppBar(),
      body: SafeArea(
          child: Center(
            child: _renderStep(),
          )),
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