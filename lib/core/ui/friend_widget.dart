import 'package:flutter/material.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:gas/styles/colors.dart';
import 'package:gas/bottom_sheet_profile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';

class FriendWidget extends StatefulWidget {
  final String profilePictureUrl;
  final String name;
  final String username;
  final String id;
  final Function() onDeleteFriend;
  final Function() onNo;
  final Function() onTap;

  FriendWidget({
    required this.profilePictureUrl,
    required this.name,
    required this.username,
    required this.id,
    required this.onDeleteFriend,
    required this.onNo,
    required this.onTap,
  });

  @override
  _FriendWidgetState createState() => _FriendWidgetState();
}

class _FriendWidgetState extends State<FriendWidget> {
  bool isLoading = false;

  void showDialogWithChoices() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Choose an option'),
          content: Text('Your friend will not see you anymore'),
          actions: [
            CupertinoDialogAction(
              child: Text('Annulla'),
              onPressed: () {
                setState(() {
                  isLoading = false;
                });
                widget.onNo();
              },
            ),
            CupertinoDialogAction(
              child: Text('Elimina'),
              onPressed: () async {
                setState(() {
                  isLoading = false;
                });
                widget.onDeleteFriend();
              },
            ),
          ],
        );
      },
    );
  }

  void updateLoading(bool newValue) {
    setState(() {
      isLoading = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        BottomSheetProfile.showOtherProfileBottomSheet(context, widget.id);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 38,
                    child: Stack(
                      children: [
                        if (widget.profilePictureUrl != null && widget.profilePictureUrl != "")
                          CachedNetworkImage(
                            imageUrl: widget.profilePictureUrl,
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
                                Center(child: CupertinoActivityIndicator()),
                            errorWidget: (context, url, error) => Icon(Icons.error),
                          ),

                        if (widget.profilePictureUrl == null || widget.profilePictureUrl == "")
                          Center(
                            child: Text(
                              widget.name != null && widget.name != "" ? widget.name![0] : '',
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
                            widget.name ?? '',
                            style: TextStyle(
                                fontFamily: 'Helvetica',
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: AppColors.white),
                          ),
                          SizedBox(height: 6),
                          Text(
                            widget.username ?? '',
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
            SizedBox(width: 10),
            InkWell(
              onTap: () async {
                setState(() {
                  isLoading = true;
                });
                widget.onTap();
                showDialogWithChoices();
              },
              child: isLoading
                  ? Container(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
                  : Icon(
                Icons.close_rounded,
                size: 25,
                color: AppColors.a,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
