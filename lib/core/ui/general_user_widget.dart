import 'package:flutter/material.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:gas/styles/colors.dart';
import 'package:gas/bottom_sheet_profile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';

class GeneralUserWidget extends StatelessWidget {
  final String profilePicture;
  final String name;
  final String username;
  final String id;
  final Function() onTap;

  GeneralUserWidget({
    required this.profilePicture,
    required this.name,
    required this.username,
    required this.id,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return InkWell(
        onTap: () {
          BottomSheetProfile.showOtherProfileBottomSheet(context, id);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 38,
                      child: Stack(
                        children: [
                          // Show CachedNetworkImage if userProfile?.imageUrl is not empty
                          if (profilePicture != null && profilePicture != "")
                            CachedNetworkImage(
                              imageUrl: profilePicture,
                              imageBuilder: (context, imageProvider) => Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              progressIndicatorBuilder: (context, url, downloadProgress) =>
                                  Center(child: CupertinoActivityIndicator()), // Show CircularProgressIndicator while loading
                              errorWidget: (context, url, error) => Icon(Icons.error),
                            ),

                          if (profilePicture == null || profilePicture == "")
                            Center(
                              child: Text(
                                name != null && name != "" ? name![0] : '',
                                style: TextStyle(
                                    fontFamily: 'Helvetica',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26,
                                    color: AppColors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        color: Colors.transparent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(name ?? '',
                                style: TextStyle(
                                    fontFamily: 'Helvetica',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: AppColors.white)),
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
                height: screenHeight / 30,
                child: ElevatedButton(
                  onPressed: onTap,
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
                          color: AppColors.white)),
                  child: const Text("ADD"),
                ),
              ),
            ],
          ),
        ));
  }
}
