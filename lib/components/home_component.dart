import 'package:flutter/material.dart';

class HomeComponent extends StatelessWidget {
  const HomeComponent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Your home component UI here
      child: Column(
        children: [
          Text("Welcome to Talkwise"),
          // Add other elements from your FlutterFlow home component
        ],
      ),
    );
  }
}