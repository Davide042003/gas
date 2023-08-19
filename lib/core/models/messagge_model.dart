import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Message {
  final String id;
  final String content;
  final String senderId;
  final String receiverId;
  final String? idPost;
  final Timestamp timestamp;

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.receiverId,
    this.idPost,
    required this.timestamp,
  });

  Message.fromData(Map<String, dynamic> data)
      : id = data['id'],
        content = data['content'],
        senderId = data['senderId'],
        receiverId = data['receiverId'],
        idPost = data['idPost'],
        timestamp = data['timestamp'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'senderId': senderId,
      'receiverId': receiverId,
      'idPost': idPost,
      'timestamp': timestamp,
    };
  }
}