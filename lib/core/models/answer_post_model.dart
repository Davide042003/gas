import 'package:cloud_firestore/cloud_firestore.dart';

class AnswerPostModel {
  final String? id;
  final bool? isAnonymous;
  final Timestamp? timestamp;

  AnswerPostModel({
    this.id,
    this.isAnonymous,
    this.timestamp,
  });

  AnswerPostModel.fromData(Map<String, dynamic> data)
      : id = data['id'],
        isAnonymous = data['isAnonymous'],
        timestamp = data['timestamp'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isAnonymous': isAnonymous,
      'timestamp': timestamp,
    };
  }
}
