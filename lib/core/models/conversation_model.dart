import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Conversation {
  final String id;
  final String participant1Id;
  final bool participant1IsAnonymous;
  final String participant2Id;
  final bool participant2IsAnonymous;
  final String? lastMessage;
  final Timestamp? lastMessageTimestamp;

  Conversation({
    required this.id,
    required this.participant1Id,
    required this.participant1IsAnonymous,
    required this.participant2Id,
    required this.participant2IsAnonymous,
    this.lastMessage,
    this.lastMessageTimestamp,
  });

  Conversation.fromData(Map<String, dynamic> data)
      : id = data['id'],
        participant1Id = data['participant1Id'],
        participant1IsAnonymous = data['participant1IsAnonymous'],
        participant2Id = data['participant2Id'],
        participant2IsAnonymous = data['participant2IsAnonymous'],
        lastMessage = data['lastMessage'],
        lastMessageTimestamp = data['lastMessageTimestamp'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant1Id': participant1Id,
      'participant1IsAnonymous': participant1IsAnonymous,
      'participant2Id': participant2Id,
      'participant2IsAnonymous': participant2IsAnonymous,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp,
    };
  }
}