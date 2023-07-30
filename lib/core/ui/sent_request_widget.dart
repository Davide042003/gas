import 'package:flutter/material.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:gas/styles/colors.dart';
import 'package:gas/bottom_sheet_profile.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SentRequestWidget extends StatelessWidget {
  final String profilePictureUrl;
  final String name;
  final String username;
  final String id;
  final Function() onDeleteSentRequest;

  SentRequestWidget({
    required this.profilePictureUrl,
    required this.name,
    required this.username,
    required this.id,
    required this.onDeleteSentRequest,
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
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 13),
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
                          if (profilePictureUrl != null && profilePictureUrl != "")
                            CachedNetworkImage(
                              imageUrl: profilePictureUrl,
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
                                  Center(child: CircularProgressIndicator(value: downloadProgress.progress)), // Show CircularProgressIndicator while loading
                              errorWidget: (context, url, error) => Icon(Icons.error),
                            ),

                          if (profilePictureUrl == null || profilePictureUrl == "")
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
                child: Center(child: Text("ADDED")),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
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
        ));
  }
}
