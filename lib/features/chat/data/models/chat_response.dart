class ChatResponse {
  final String chatId;
  const ChatResponse({required this.chatId});

  factory ChatResponse.fromJson(Map<String, dynamic> json) =>
      ChatResponse(chatId: json['chatId']?.toString() ?? '');
}

