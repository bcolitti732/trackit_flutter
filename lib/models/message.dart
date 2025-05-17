class Message {
  final String senderId;
  final String rxId;
  final String? content;
  final DateTime created;
  final bool acknowledged;
  final String roomId;

  Message({
    required this.senderId,
    required this.rxId,
    this.content,
    required this.created,
    required this.acknowledged,
    required this.roomId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      senderId: json['senderId'] as String,
      rxId: json['rxId'] as String,
      content: json['content'] as String?,
      created: DateTime.parse(json['created'] as String),
      acknowledged: json['acknowledged'] as bool,
      roomId: json['roomId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'rxId': rxId,
      'content': content,
      'created': created.toIso8601String(),
      'acknowledged': acknowledged,
      'roomId': roomId,
    };
  }
}