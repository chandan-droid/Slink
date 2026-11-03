abstract class ChatRepository {
  Future<String> startChat(String recipientId);
  Future<Map<String, dynamic>> getChatDetails(String chatId);
}
