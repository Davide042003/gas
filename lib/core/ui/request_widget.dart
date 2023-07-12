import 'package:flutter/material.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:gas/styles/colors.dart';

class RequestWidget extends StatelessWidget {
  final String profilePictureUrl;
  final String name;
  final String username;
  final Function() onAcceptFriendRequest;
  final Function() onDeleteSentRequest;

  RequestWidget({
    required this.profilePictureUrl,
    required this.name,
    required this.username,
    required this.onAcceptFriendRequest,
    required this.onDeleteSentRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
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
          ElevatedButton(
            onPressed: () {
              onAcceptFriendRequest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.a,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35)),
              elevation: 0,
              textStyle: TextStyle(
                  fontFamily: 'Helvetica',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.white),
            ),
            child: const Text("ACCEPT"),
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
