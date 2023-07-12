import 'package:flutter/material.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:gas/styles/colors.dart';

class SentRequestWidget extends StatelessWidget {
  final String profilePictureUrl;
  final String name;
  final String username;
  final Function() onDeleteSentRequest;

  SentRequestWidget({
    required this.profilePictureUrl,
    required this.name,
    required this.username,
    required this.onDeleteSentRequest,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    double screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 13),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  maxRadius: 38,
                  backgroundImage: profilePictureUrl.isNotEmpty
                      ? NetworkImage(profilePictureUrl)
                      : null,
                  child: profilePictureUrl.isEmpty
                      ? Text(name.isNotEmpty ? name[0] : '',
                      style: TextStyle(
                          fontFamily: 'Helvetica',
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          color: AppColors.white))
                      : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Container(
                    color: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          name ?? '',
                          style: TextStyle(
                              fontFamily: 'Helvetica',
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: AppColors.white),
                        ),
                        SizedBox(height: 6),
                        Text(
                          username ?? '',
                          style: TextStyle(
                              fontFamily: 'Helvetica',
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: AppColors.whiteShadow),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: screenHeight / 27,
            width: screenWidth / 5,
            child:
            Center(child: Text("ADDED")),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                  Radius.circular(20)),
              color: AppColors.a,
            ),
          ),
          SizedBox(width: 10),
          InkWell(
            onTap: () {
              onDeleteSentRequest();
            },
            child: Icon(
              Icons.close_rounded,
              size: 25,
              color: AppColors.a,
            ),
          ),
        ],
      ),
    );
  }
}