import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String? id;
  final String? question;
  final List<String>? images;
  final List<String>? answersList;
  final bool? isAnonymous;
  final bool? isMyFriends;
  final List<List<String>>? answersTap;
  final Timestamp? timestamp;

  PostModel({
    this.id,
    this.question,
    this.images,
    this.answersList,
    this.isAnonymous,
    this.isMyFriends,
    this.answersTap,
    this.timestamp,
  });

  PostModel.fromData(Map<String, dynamic> data)
      : id = data['id'],
        question = data['question'],
        images = List<String>.from(data['images'] ?? []),
        answersList = List<String>.from(data['answersList'] ?? []),
        isAnonymous = data['isAnonymous'],
        isMyFriends = data['isMyFriends'],
        answersTap = data['answersTap'],
        timestamp = data['timestamp'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'images': images,
      'answersList': answersList,
      'isAnonymous': isAnonymous,
      'isMyFriends': isMyFriends,
      'answersTap' : answersTap,
      'timestamp': timestamp,
    };
  }
}
