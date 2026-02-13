# WebSocket Message Handling Fix - Summary

## Problem
Messages sent from one user were not being received correctly on the other user's device.

## Root Causes Identified

1. **Incorrect WebSocket Payload Format**: Flutter was sending ChatMessage format, but backend expected a simpler payload with `chatId`, `content`, `recipientId`, `senderId`

2. **Missing chatId in Message Sending**: The chatId parameter wasn't being passed through the chain from UI to WebSocket service

3. **Date Format Mismatch**: Backend sends dates in format "yyyy-MM-dd HH:mm:ss" but Flutter was expecting ISO-8601 format

## Changes Made

### 1. WebSocketService (`websocket_service.dart`)

**Updated `sendMessage()` method:**
```dart
void sendMessage({
  required String content,
  required String recipientId,
  String? recipientName,
  String? chatId,
}) {
  // Backend expects: chatId, content, recipientId, senderId
  final messagePayload = {
    'chatId': chatId ?? generateChatId(_currentUserId!, recipientId),
    'content': content,
    'recipientId': recipientId,
    'senderId': _currentUserId,
  };

  _stompClient!.send(
    destination: AppConstants.wsSendMessage, // '/app/chat.sendMessage'
    body: jsonEncode(messagePayload),
  );
}
```

**Key Changes:**
- Sends plain Map payload instead of ChatMessage object
- Includes all required fields: chatId, content, recipientId, senderId
- Auto-generates chatId if not provided

### 2. ChatMessage Model (`chat_message.dart`)

**Enhanced to handle MessageDTO from backend:**

```dart
factory ChatMessage.fromJson(Map<String, dynamic> json) {
  DateTime parseTimestamp() {
    if (json['createdAt'] != null) {
      // Backend sends format: "yyyy-MM-dd HH:mm:ss"
      final dateStr = json['createdAt'] as String;
      if (dateStr.contains(' ')) {
        final parts = dateStr.split(' ');
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');
        return DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
          int.parse(timeParts[2]),
        );
      }
    }
    return DateTime.now();
  }
  // ... rest of parsing
}
```

**Key Changes:**
- Added support for MessageDTO format from backend
- Custom date parser for "yyyy-MM-dd HH:mm:ss" format
- Added fields: `chatId`, `senderUsername`, `status`

### 3. ChatProvider (`chat_provider.dart`)

**Updated `sendMessage()` to accept and pass chatId:**

```dart
void sendMessage({
  required String content,
  required String recipientId,
  required String senderId,
  String? recipientName,
  String? chatId,
}) {
  final effectiveChatId = chatId ?? _currentChatId ?? generateChatId(senderId, recipientId);
  
  _webSocketService.sendMessage(
    content: content,
    recipientId: recipientId,
    recipientName: recipientName,
    chatId: effectiveChatId,
  );
  // ... rest of method
}
```

**Added `generateChatId()` method:**
```dart
String generateChatId(String userId1, String userId2) {
  // Generate a consistent chat ID by sorting user IDs
  final ids = [userId1, userId2]..sort();
  return '${ids[0]}_${ids[1]}';
}
```

### 4. ChatScreen (`chat_screen.dart`)

**Updated to pass chatId when sending:**
```dart
void _sendMessage() {
  context.read<ChatProvider>().sendMessage(
    content: content,
    recipientId: widget.recipient.id,
    senderId: authProvider.currentUser!.id,
    recipientName: widget.recipient.username,
    chatId: widget.chatId,  // ✅ Now passing chatId
  );
}
```

## Backend Integration Points

### Message Flow:
1. **Sending**: Flutter → `/app/chat.sendMessage` → Backend saves → Sends to recipient at `/user/{recipientId}/queue/messages`
2. **Receiving**: Backend → `/user/queue/messages` → Flutter parses MessageDTO → Displays in chat

### WebSocket Destinations Used:
- **Send Message**: `/app/chat.sendMessage`
- **Receive Message**: `/user/queue/messages`
- **Typing Indicator**: `/app/chat.typing` → `/user/queue/typing`
- **User Status**: `/topic/user.status`
- **Add User**: `/app/chat.addUser`
- **Mark Read**: `/app/chat.markRead`

## Testing Checklist

✅ **Message Sending**: Payload format matches backend expectation
✅ **Message Receiving**: MessageDTO parsing handles backend date format
✅ **Chat ID Generation**: Consistent between sender and receiver
✅ **WebSocket Destinations**: All match backend configuration
✅ **User Authentication**: JWT token passed in WebSocket headers

## Expected Behavior

1. **User A sends message**:
   - Flutter sends: `{chatId: "user1_user2", content: "Hello", recipientId: "user2", senderId: "user1"}`
   - Backend receives at `/app/chat.sendMessage`
   - Backend saves to database
   - Backend sends MessageDTO to User B at `/user/user2/queue/messages`

2. **User B receives message**:
   - Flutter subscribed to `/user/queue/messages`
   - Receives MessageDTO: `{id, chatId, senderId, senderUsername, content, status, createdAt}`
   - Parses date format "yyyy-MM-dd HH:mm:ss"
   - Displays in chat UI

## Debugging Tips

If messages still not appearing:

1. **Check WebSocket Connection**: 
   ```dart
   print('WebSocket connected: ${webSocketService.isConnected}');
   ```

2. **Check Message Sending**:
   ```dart
   print('Sending message: $messagePayload');
   ```

3. **Check Message Receiving**:
   ```dart
   print('📨 Received message: ${chatMessage.content}');
   ```

4. **Check Backend Logs**: Look for:
   - `📨 Received message from {senderId} in chat {chatId}`
   - `✅ Message delivered to user {recipientId}`

5. **Verify ChatId**: Both users must use the same chatId format (sorted user IDs)

## Important Notes

- ChatId is generated consistently by sorting user IDs alphabetically
- Backend uses Principal.getName() to get authenticated userId
- WebSocket authentication uses JWT token in 'Authorization' header
- Messages are not echoed back to sender by backend (only sent to recipient)

