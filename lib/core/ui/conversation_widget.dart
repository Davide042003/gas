import 'package:flutter/material.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:gas/styles/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationWidget extends StatefulWidget {
  final String profilePictureUrl;
  final String username;
  final String lastMessage;
  final bool isAnonymous;
  final Timestamp timestamp;

  ConversationWidget({
    required this.profilePictureUrl,
    required this.username,
    required this.lastMessage,
    required this.isAnonymous,
    required this.timestamp,
  });

  @override
  _ConversationWidgetState createState() => _ConversationWidgetState();
}

class _ConversationWidgetState extends State<ConversationWidget> {

  @override
  Widget build(BuildContext context) {
    String truncatedLastMessage = widget.lastMessage.length > 15
        ? widget.lastMessage.substring(0, 15) + '...'
        : widget.lastMessage;

    return Container(
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
                              widget.username != null && widget.username != "" ? widget.username![0] : '',
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
                            widget.username ?? '',
                            style: TextStyle(
                                fontFamily: 'Helvetica',
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: AppColors.white),
                          ),
                          SizedBox(height: 6),
                          Text(
                            truncatedLastMessage ?? '',
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
                  Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      _formatTimestamp(widget.timestamp),
                      style: TextStyle(
                        fontFamily: 'Helvetica',
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
