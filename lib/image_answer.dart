import 'package:flutter/material.dart';
import 'package:gas/styles/colors.dart';
import 'fractional_range_clipper_vertical.dart';

class ImageAnswer extends StatefulWidget {
  final double answersCount;
  final String imageUrl;
  final bool hasVoted;
  final CurvedAnimation curvedAnimation;
  final Function() clickAnswer;

  ImageAnswer({
    required this.answersCount,
    required this.imageUrl,
    required this.hasVoted,
    required this.curvedAnimation,
    required this.clickAnswer,
  });

  @override
  _ImageAnswerState createState() => _ImageAnswerState();
}

class _ImageAnswerState extends State<ImageAnswer> with SingleTickerProviderStateMixin {
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
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: screenWidth / 2.3,
                height: screenHeight / 4,
                decoration: BoxDecoration(
                  image: widget.imageUrl.isNotEmpty
                      ? DecorationImage(
                    image: NetworkImage(widget.imageUrl),
                    fit: BoxFit.cover,
                  )
                      : null,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              widget.hasVoted
                  ? AnimatedBuilder(
                animation: widget.curvedAnimation,
                builder: (BuildContext context, Widget? child) {
                  final clipper = FractionalRangeClipperVertical(
                    begin: 0,
                    end: widget.answersCount * widget.curvedAnimation.value,
                  );

                  return ClipPath(
                    clipper: clipper,
                    clipBehavior: Clip.hardEdge,
                    child: Container(
                      width: screenWidth / 2.3,
                      height: (screenHeight / 4) * widget.answersCount,
                      decoration: BoxDecoration(
                        color: AppColors.fadeImageAnswer.withOpacity(.61),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
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
