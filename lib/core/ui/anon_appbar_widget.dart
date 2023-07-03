import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AnonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AnonAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Center(child: Image.asset('assets/img/logo.png', height: 40)),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
