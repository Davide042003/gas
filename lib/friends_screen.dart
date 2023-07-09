import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gas/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gas/styles/styles_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  bool _searchBoxFocused = false;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

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

    return Scaffold(
      backgroundColor: AppColors.backgroundDefault,
      body: SafeArea(
        child: Column(
            children: [
              Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(margin: EdgeInsets.only(left: 140),
                    child: Image.asset('assets/img/logo.png', height: 40),
                    width: 100,),
                  InkWell(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 35,
                      color: AppColors.white,
                    ),
                    onTap: () {
                      context.pop();
                    },
                  ),
                ],)),
              SizedBox(height: 10,),
              Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.white),
                    child: Focus(
                      child: TextField(
                        controller: _searchController,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search, color: _searchBoxFocused ? AppColors.brownShadow : AppColors.a,),
                            iconColor: AppColors.a,
                            border: InputBorder.none,
                            hintText: 'Add or search friends',
                            hintStyle: ref
                                .watch(stylesProvider)
                                .text
                                .hintOnBoarding.copyWith(color: AppColors.a, fontSize: 16)),
                        style: ref
                            .watch(stylesProvider)
                            .text
                            .hintOnBoarding.copyWith(color: AppColors.brown, fontSize: 16),
                        cursorColor: AppColors.brownShadow,
                      ),
                      onFocusChange: (value) {
                        setState(() {
                          if (value) {
                            _searchBoxFocused = true;
                          } else {
                            _searchController.clear();
                            _searchBoxFocused = false;
                          }
                        });
                      },
                    ),
                  ),),
                  Visibility(
                      visible: _searchBoxFocused,
                      child: FadeInRight(
                        duration: const Duration(milliseconds: 300),
                        controller: (controller) =>
                        _animationController = controller,
                        child: TextButton(
                          child: Text("Cancel", style: ref.watch(stylesProvider).text.editProfile.copyWith(fontSize: 18),),
                          onPressed: () {
                            setState(() {
                              FocusScope.of(context).unfocus();
                            });
                          },
                        ),
                      ))
                ],
              )),
            ]
        ),
      ),
    );
  }
}
