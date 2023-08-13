import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gas/core/models/answer_post_model.dart';
import 'package:flutter/material.dart';

class PostModel {
  final String? id;
  String? postId;
  final String? question;
  final List<String>? images;
  final List<String>? answersList;
  final bool? isAnonymous;
  final bool? isMyFriends;
  final Map<int, List<AnswerPostModel>>? answersTap; // Map of int keys to lists of AnswerPostModel
  final Timestamp? timestamp;
  Color? colorBackground;

  PostModel({
    this.id,
    this.question,
    this.images,
    this.answersList,
    this.isAnonymous,
    this.isMyFriends,
    this.answersTap,
    this.timestamp,
    this.colorBackground,
  });

  PostModel.fromData(Map<String, dynamic> data)
      : id = data['id'],
        question = data['question'],
        images = List<String>.from(data['images'] ?? []),
        answersList = List<String>.from(data['answersList'] ?? []),
        isAnonymous = data['isAnonymous'],
        isMyFriends = data['isMyFriends'],
        answersTap = (data['answersTap'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(
            int.parse(key),
            (value as List<dynamic>)
                .map((answerData) => AnswerPostModel.fromData(answerData))
                .toList(),
          ),
        ),
        timestamp = data['timestamp'],
        colorBackground = data['color'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'images': images,
      'answersList': answersList,
      'isAnonymous': isAnonymous,
      'isMyFriends': isMyFriends,
      'answersTap': answersTap?.map((key, value) => MapEntry(key.toString(), value.map((answer) => answer.toJson()).toList())),
      'timestamp': timestamp,
      'colorBackground' : colorBackground,
    };
  }
}
