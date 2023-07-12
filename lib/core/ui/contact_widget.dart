import 'package:flutter/material.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:gas/styles/colors.dart';

class ContactWidget extends StatelessWidget {
  final Animation<double> animation;
  final String profilePicture;
  final String name;
  final String username;
  final String nameContact;
  final Function() onTap;

  ContactWidget({
    required this.animation,
    required this.profilePicture,
    required this.name,
    required this.username,
    required this.nameContact,
    required this.onTap,
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

    return SizeTransition(
      sizeFactor: animation,
      child: Container(
        padding: EdgeInsets.only(left: 20, right: 20, top: 13, bottom: 13),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    maxRadius: 38,
                    backgroundImage: profilePicture.isNotEmpty
                        ? NetworkImage(profilePicture)
                        : null,
                    child: profilePicture.isEmpty
                        ? Text(
                      name.isNotEmpty ? name[0] : '',
                      style: TextStyle(fontFamily: 'Helvetica',
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppColors.white),
                    )
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
                              style: TextStyle(fontFamily: 'Helvetica',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: AppColors.white)
                          ),
                          SizedBox(height: 6),
                          Text(
                            username ?? '',
                            style: TextStyle(fontFamily: 'Helvetica',
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: AppColors.whiteShadow),
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.account_circle_rounded, size: 25),
                              SizedBox(width: 5),
                              Text(
                                nameContact ?? '',
                                style: TextStyle(fontFamily: 'Helvetica',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: AppColors.whiteShadow),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: screenHeight / 30,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.a,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35)),
                    elevation: 0,
                    textStyle: TextStyle(fontFamily: 'Helvetica', fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.white)),
                child: const Text("ADD"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}