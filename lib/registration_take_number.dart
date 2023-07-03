import 'package:flutter/material.dart';

class RegistrationTakeNumber extends StatelessWidget {
  const RegistrationTakeNumber({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone Number Screen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PhoneNumberScreen(),
    );
  }
}

class PhoneNumberScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phone Number Screen'),
      ),
      body: Container(
        color: Colors.orange, // Colored background
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Enter your phone number:',
              style: TextStyle(fontSize: 20.0),
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}