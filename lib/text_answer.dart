import 'package:flutter/material.dart';
import 'package:gas/styles/colors.dart';
import 'fractional_range_clipper.dart';

class TextAnswer extends StatefulWidget {
  final double answersCount;
  final String answerText;
  final bool hasVoted;
  final CurvedAnimation curvedAnimation;
  final Function() clickAnswer;

  TextAnswer({
    required this.answersCount,
    required this.answerText,
    required this.hasVoted,
    required this.curvedAnimation,
    required this.clickAnswer,
  });

  @override
  _TextAnswerState createState() => _TextAnswerState();
}

class _TextAnswerState extends State<TextAnswer> with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        GestureDetector(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                width: screenWidth / 3.3,
                height: screenHeight / 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    widget.answerText!,
                    style: TextStyle(
                      fontFamily: 'Helvetica',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brown,
                    ),
                  ),
                ),
              ),
              widget.hasVoted
                  ? AnimatedBuilder(
                animation: widget.curvedAnimation,
                builder: (BuildContext context, Widget? child) {
                  final clipper = FractionalRangeClipper(
                    begin: 0,
                    end: widget.answersCount * widget.curvedAnimation.value,
                  );

                  return ClipPath(
                    clipper: clipper,
                    clipBehavior: Clip.hardEdge,
                    child: Container(
                      width: screenWidth / 3.3,
                      height: screenHeight / 16,
                      decoration: BoxDecoration(
                        color: AppColors.fadeImageAnswer.withOpacity(.61),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                },
              )
                  : Container(),
            ],
          ),
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            if (!widget.hasVoted) {
              await widget.clickAnswer();
            }
          },
        ),
        SizedBox(
          height: screenHeight / 50,
        ),
        widget.hasVoted
            ? Text(
          "${(widget.answersCount * 100).round()}%",
          style: TextStyle(
            fontFamily: 'Helvetica',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppColors.white,
          ),
        )
            : SizedBox(),
      ],
    );
  }
}
