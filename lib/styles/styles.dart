import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'colors.dart';

@immutable
class AppStyle {
  final _Text text = _Text();
  final _Button button = _Button();
}

@immutable
class _Text {
  TextStyle get titleFont => const TextStyle(fontFamily: 'Helvetica');
  TextStyle get contentFont => const TextStyle(fontFamily: 'Helvetica');

  late final TextStyle titleOnBoarding = contentFont.copyWith(fontWeight: FontWeight.bold, fontSize: 19, color: AppColors.white);
  late final TextStyle hintOnBoarding = contentFont.copyWith(fontWeight: FontWeight.w400, fontSize: 26, color: AppColors.whiteShadow);
  late final TextStyle bodyOnBoarding = contentFont.copyWith(fontWeight: FontWeight.normal, fontSize: 28, color: AppColors.brown);
  late final TextStyle policyOnBoarding = contentFont.copyWith(fontWeight: FontWeight.w400, fontSize: 15, color: AppColors.white, height: 1.2);
  late final TextStyle policyOnBoardingBold = contentFont.copyWith(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.white, height: 1.2);
  late final TextStyle continueButton = contentFont.copyWith(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.brownShadow);
  late final TextStyle errorOnBoarding = contentFont.copyWith(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.brown);


  late final TextStyle title = titleFont.copyWith(fontWeight: FontWeight.w700, fontSize: 30);

  late final TextStyle hint =
  titleFont.copyWith(fontWeight: FontWeight.w700, fontSize: 36, color: Colors.white);

  late final TextStyle hintSearchInput =
  titleFont.copyWith(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white);

  late final TextStyle body = contentFont.copyWith(fontWeight: FontWeight.w400, fontSize: 16);
  late final TextStyle bodyBold = contentFont.copyWith(fontWeight: FontWeight.w700, fontSize: 16);
  late final TextStyle bodySmall = contentFont.copyWith(fontWeight: FontWeight.w400, fontSize: 12);
  late final TextStyle bodySmallBold = contentFont.copyWith(fontWeight: FontWeight.w700, fontSize: 12);
}
@immutable
class _Button {
  TextStyle get font => const TextStyle(fontFamily: 'Helvetica');

  final ButtonStyle buttonOnBoarding = ElevatedButton.styleFrom(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.brownShadow,
      minimumSize: const Size.fromHeight(60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(45)),
      elevation: 0,
      textStyle: _Text().continueButton);
}
