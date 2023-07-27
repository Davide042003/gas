import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gas/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';
import 'user_notifier.dart';

class OtherProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  OtherProfileScreen({required this.userId});

  @override
  _OtherProfileScreenState createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends ConsumerState<OtherProfileScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundDefault,
      body: SafeArea(
        child: Consumer(
          builder: (context, watch, child) {
            final userProfileFuture = ref.watch(otherUserProfileProvider(widget.userId));

            return userProfileFuture.when(
              data: (userProfile) {
                if (userProfile != null) {
                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            InkWell(
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: 35,
                                color: AppColors.white,
                              ),
                              onTap: () {
                                context.pop();
                              },
                            ),
                            Container(
                              width: 200,
                              child: Text(
                                userProfile.username ?? '',
                                textAlign: TextAlign.center,
                                style: ref.watch(stylesProvider).text.titleOnBoarding.copyWith(fontSize: 28),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10,),
                      Stack(
                        children: [
                          Container(
                            color: AppColors.whiteShadow,
                            height: screenHeight / 600,
                          ),
                          Center(
                            child: Container(
                              color: AppColors.white,
                              height: screenHeight / 400,
                              width: screenWidth / 2.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
              loading: () => Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Text('Error fetching data.'),
              ),
            );
          },
        ),
      ),
    );
  }
}
