import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? id;
  final String? name;
  final String? username;
  final String? phoneNumber;
  final String? bio;
  final String? imageUrl;
  final Timestamp? timestamp;
  String? displayName;

  UserModel({this.id, this.name, this.username, this.phoneNumber, this.bio, this.imageUrl, this.timestamp, this.displayName});

  UserModel.fromData(Map<String, dynamic> data):
        id = data['id'],
        name = data['name'],
        username = data['username'],
        phoneNumber = data['phoneNumber'],
        bio = data['bio'],
        imageUrl = data['imageUrl'],
        timestamp = data['timestamp'],
  displayName = data['displayName'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
      'displayName' : displayName
    };
  }
}