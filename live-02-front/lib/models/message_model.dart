enum MessageType {
  normal,
  vip,
  gift,
  system,
  moderator,
}

class MessageModel {
  final String id;
  final String message;
  final String userId;
  final String streamId;
  final String? userName;
  final MessageType type;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.message,
    required this.userId,
    required this.streamId,
    this.userName,
    required this.type,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json[''id'']?.toString() ?? '''',
      message: json[''content''] ?? json[''message''] ?? '''',
      userId: json[''user_id'']?.toString() ?? '''',
      streamId: json[''stream_id'']?.toString() ?? '''',
      type: _parseType(json[''message_type''] ?? json[''type''] ?? ''chat''),
      createdAt: DateTime.tryParse(json[''created_at'']?.toString() ?? '''') ?? DateTime.now(),
    );
  }

  factory MessageModel.fromSupabase(Map<String, dynamic> json) => MessageModel.fromJson(json);

  static MessageType _parseType(String typeStr) {
    switch (typeStr) {
      case ''vip'':
        return MessageType.vip;
      case ''gift'':
        return MessageType.gift;
      case ''system'':
        return MessageType.system;
      case ''moderator'':
        return MessageType.moderator;
      default:
        return MessageType.normal;
    }
  }

  String get avatarChar =>
      userName?.substring(0, 1).toUpperCase() ??
      userId.substring(0, 1).toUpperCase();

  bool get isVip => type == MessageType.vip;
  bool get isModerator => type == MessageType.moderator;
  bool get isSystem => type == MessageType.system;
}
