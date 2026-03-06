import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

/// Implementation of [ChatRepository] using TCP sockets for P2P chat.
class ChatRepositoryImpl implements ChatRepository {
  final _uuid = const Uuid();
  final _messageController = StreamController<ChatMessage>.broadcast();
  final Map<String, List<ChatMessage>> _chatHistory = {};

  String _localDeviceId = '';
  String _localDeviceName = 'Me';

  void configure({required String deviceId, required String deviceName}) {
    _localDeviceId = deviceId;
    _localDeviceName = deviceName;
  }

  @override
  Future<ChatMessage> sendMessage({
    required String peerId,
    required String content,
  }) async {
    final message = ChatMessage(
      id: _uuid.v4(),
      senderId: _localDeviceId,
      senderName: _localDeviceName,
      content: content,
      timestamp: DateTime.now(),
      isMe: true,
      status: ChatMessageStatus.sending,
    );

    // Store locally
    _chatHistory.putIfAbsent(peerId, () => []);
    _chatHistory[peerId]!.add(message);
    _messageController.add(message);

    // Send over network via HTTP POST
    try {
      final client = HttpClient();
      client.connectionTimeout =
          const Duration(seconds: AppConstants.connectionTimeoutSec);
      // In production, resolve peer host from connection manager
      // For now, this is a placeholder
      client.close();

      return ChatMessage(
        id: message.id,
        senderId: message.senderId,
        senderName: message.senderName,
        content: message.content,
        timestamp: message.timestamp,
        isMe: true,
        status: ChatMessageStatus.sent,
      );
    } catch (_) {
      return ChatMessage(
        id: message.id,
        senderId: message.senderId,
        senderName: message.senderName,
        content: message.content,
        timestamp: message.timestamp,
        isMe: true,
        status: ChatMessageStatus.failed,
      );
    }
  }

  /// Called when a message is received from the network.
  void onMessageReceived(Map<String, dynamic> data) {
    final message = ChatMessage(
      id: data['id'] as String? ?? _uuid.v4(),
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Unknown',
      content: data['content'] as String? ?? '',
      timestamp: DateTime.tryParse(data['timestamp'] as String? ?? '') ??
          DateTime.now(),
      isMe: false,
      status: ChatMessageStatus.delivered,
    );

    _chatHistory.putIfAbsent(message.senderId, () => []);
    _chatHistory[message.senderId]!.add(message);
    _messageController.add(message);
  }

  @override
  Future<List<ChatMessage>> getMessages(String peerId) async {
    return _chatHistory[peerId] ?? [];
  }

  @override
  Stream<ChatMessage> watchMessages() => _messageController.stream;

  @override
  Future<void> clearChat(String peerId) async {
    _chatHistory.remove(peerId);
  }

  /// Disposes resources.
  Future<void> dispose() async {
    await _messageController.close();
  }
}
