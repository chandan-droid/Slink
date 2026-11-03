# Slink Flutter Frontend — Architecture & Structure

> Derived from the `slink-server` modular monolith (modules: `auth`, `users`, `chat`, `message`, `presence`, `notification`).

---

## Guiding Principles

- **Feature-first folder layout** — each domain module from the server gets its own feature folder.
- **Clean Architecture per feature** — `data → domain → presentation` layers inside every feature.
- **Riverpod** for state management (providers, notifiers, async state).
- **go_router** for navigation with deep-link and auth-guard support.
- **stomp_dart_client** for the Spring STOMP WebSocket (matches the server's `/ws` endpoint).
- **Hive / Isar** for local message caching and offline-first behavior.
- **flutter_contacts** for reading device phone book and matching against `/api/users`.

---

## Project Root

```
slink_flutter/
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   ├── app.dart                          # MaterialApp + GoRouter bootstrap
│   │
│   ├── core/                             # Cross-cutting, no business logic
│   │   ├── config/
│   │   │   ├── app_config.dart           # base URLs, env vars
│   │   │   └── theme/
│   │   │       ├── app_theme.dart
│   │   │       ├── app_colors.dart
│   │   │       └── app_text_styles.dart
│   │   ├── network/
│   │   │   ├── dio_client.dart           # Dio singleton, JWT interceptor, refresh logic
│   │   │   ├── api_endpoints.dart        # all REST path constants
│   │   │   └── network_exceptions.dart
│   │   ├── websocket/
│   │   │   ├── stomp_service.dart        # connect/disconnect, send frame helpers
│   │   │   ├── stomp_destinations.dart   # /app/chat.sendMessage, /user/queue/…
│   │   │   └── stomp_provider.dart       # Riverpod provider
│   │   ├── storage/
│   │   │   ├── secure_storage.dart       # flutter_secure_storage — JWT, refresh token
│   │   │   └── local_db.dart             # Hive/Isar init, box accessors
│   │   ├── router/
│   │   │   ├── app_router.dart           # GoRouter definition
│   │   │   └── route_names.dart
│   │   ├── utils/
│   │   │   ├── date_utils.dart
│   │   │   ├── phone_utils.dart          # E.164 normalisation
│   │   │   └── contact_matcher.dart      # merge device contacts ↔ platform users
│   │   └── widgets/                      # truly shared, stateless UI atoms
│   │       ├── avatar_widget.dart
│   │       ├── online_badge.dart
│   │       ├── typing_indicator.dart
│   │       ├── message_status_icon.dart  # tick marks (SENT/DELIVERED/READ)
│   │       ├── empty_state.dart
│   │       └── error_view.dart
│   │
│   ├── features/
│   │   ├── auth/
│   │   ├── contacts/
│   │   ├── chat/
│   │   ├── message/
│   │   ├── group/
│   │   ├── community/
│   │   ├── presence/
│   │   ├── notification/
│   │   └── search/
│   │
│   └── l10n/                             # ARB files for localisation
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
├── pubspec.yaml
└── analysis_options.yaml
```

---

## Feature: `auth`

Maps to server module **`slink-auth`** — endpoints `POST /api/auth/register`, `/login`, `/logout`.

```
features/auth/
├── data/
│   ├── models/
│   │   ├── login_request.dart
│   │   ├── register_request.dart
│   │   └── auth_response.dart            # { token, userId, username }
│   └── repositories/
│       └── auth_repository_impl.dart     # calls Dio, writes JWT to SecureStorage
├── domain/
│   ├── entities/
│   │   └── auth_token.dart
│   └── repositories/
│       └── auth_repository.dart          # abstract
├── presentation/
│   ├── providers/
│   │   └── auth_provider.dart            # AsyncNotifier<AuthState>
│   ├── screens/
│   │   ├── login_screen.dart             # phone/email + password, JWT → SecureStorage
│   │   └── register_screen.dart
│   └── widgets/
│       ├── phone_email_field.dart        # toggles between phone & email input
│       └── auth_form_button.dart
```

**Key notes**
- Login accepts **phone number OR email** (server `LoginRequest` carries `phoneNumber`; extend if server adds email login).
- On success store `accessToken` in `flutter_secure_storage`; attach as `Authorization: Bearer …` via Dio interceptor.
- Logout calls `POST /api/auth/logout`, then clears secure storage and disconnects STOMP.

---

## Feature: `contacts`

Maps to server module **`slink-users`** — `GET /api/users`, `/me`, `/{userId}`.
Also handles the phone-book matching requirement.

```
features/contacts/
├── data/
│   ├── models/
│   │   └── user_summary_dto.dart         # id, username, phoneNumber, email
│   └── repositories/
│       └── contacts_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── platform_user.dart            # + bool isPhoneContact, String? localName
│   └── repositories/
│       └── contacts_repository.dart
├── presentation/
│   ├── providers/
│   │   ├── contacts_provider.dart        # fetches /api/users, merges with device contacts
│   │   └── current_user_provider.dart    # fetches /api/users/me
│   ├── screens/
│   │   ├── contacts_screen.dart          # two sections: "On Slink" phone contacts, "All users"
│   │   └── user_profile_screen.dart      # tapping a user opens their profile
│   └── widgets/
│       ├── contact_tile.dart             # avatar, name, online badge, "Message" CTA
│       └── phone_contact_badge.dart      # small label "In your contacts"
```

**Contact matching logic** (`core/utils/contact_matcher.dart`)

```
1. Request CONTACTS permission (permission_handler).
2. Read all device contacts via flutter_contacts (displayName, phones[]).
3. Normalise all phone numbers to E.164.
4. Fetch GET /api/users → List<UserSummaryDto>.
5. For each platform user, check if their phoneNumber is in the device set.
6. Tag matching users with isPhoneContact = true.
7. Sort: phone contacts first, then rest alphabetically.
```

---

## Feature: `chat`

Maps to server module **`slink-chat`** — endpoints `POST /api/chat/start`, `/community/start`.

```
features/chat/
├── data/
│   ├── models/
│   │   ├── chat_response.dart            # { chatId }
│   │   └── conversation_type.dart        # DIRECT | GROUP
│   └── repositories/
│       └── chat_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── conversation.dart             # chatId, type, members, lastMessage, unreadCount
│   └── repositories/
│       └── chat_repository.dart
├── presentation/
│   ├── providers/
│   │   └── conversation_list_provider.dart   # list of active conversations
│   ├── screens/
│   │   └── conversations_screen.dart     # home tab — all chats sorted by recency
│   └── widgets/
│       ├── conversation_tile.dart        # avatar, name, last message preview, timestamp, unread badge
│       └── new_chat_fab.dart             # floating button → contacts picker → POST /api/chat/start
```

---

## Feature: `message`

Maps to server modules **`slink-message`** (REST + WebSocket).

REST: `GET /api/messages/history/{chatId}`, `POST /api/messages/mark-read/{messageId}`
WebSocket (STOMP):
- **Send** → `/app/chat.sendMessage`
- **Receive** → `/user/queue/messages`
- **Mark read** → `/app/chat.markRead`
- **Typing** → `/app/chat.typing` / `/user/queue/typing`
- **Receipts** → `/user/{senderId}/queue/receipts`

```
features/message/
├── data/
│   ├── models/
│   │   ├── message_dto.dart              # id, chatId, senderId, senderUsername,
│   │   │                                #   recipientId, content, status, createdAt
│   │   └── message_status.dart          # SENDING|SENT|DELIVERED|READ|FAILED|DELETED
│   ├── local/
│   │   └── message_local_source.dart    # Hive box — stores messages per chatId
│   └── repositories/
│       └── message_repository_impl.dart # merges remote history + local cache
├── domain/
│   ├── entities/
│   │   └── message.dart
│   └── repositories/
│       └── message_repository.dart
├── presentation/
│   ├── providers/
│   │   ├── message_list_provider.dart   # StateNotifier<List<Message>> per chatId
│   │   │                                # seeded from Hive, updated via STOMP
│   │   ├── typing_provider.dart         # Map<chatId, bool> isTyping
│   │   └── send_message_provider.dart   # handles optimistic insert → STOMP send
│   ├── screens/
│   │   └── chat_screen.dart             # main 1-to-1 chat view
│   └── widgets/
│       ├── message_bubble.dart          # sent/received, tail, colour theming
│       ├── message_input_bar.dart       # text field + send button, emits typing events
│       ├── message_status_row.dart      # double-tick (DELIVERED), blue-tick (READ)
│       ├── date_separator.dart          # "Today", "Yesterday", date label between messages
│       └── offline_banner.dart          # shown when STOMP is disconnected
```

**Offline & reconnect flow**
1. On app start / reconnect: `GET /api/messages/history/{chatId}?since=<lastSeenTimestamp>` for each open chat.
2. STOMP `addUser` frame → server marks user ONLINE, flushes any queued messages via `/user/queue/messages`.
3. Unread notifications fetched from `GET /api/notifications`.

---

## Feature: `group`

Uses `ConversationType.GROUP` from the chat domain. Server stores groups as `Chat` entities with `GROUP` type.

```
features/group/
├── data/
│   ├── models/
│   │   ├── group_dto.dart                # chatId, name, description, imageUrl, members
│   │   └── group_member_dto.dart         # userId, role (ADMIN|MEMBER)
│   └── repositories/
│       └── group_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── group.dart
│   │   └── group_member.dart
│   └── repositories/
│       └── group_repository.dart
├── presentation/
│   ├── providers/
│   │   ├── group_list_provider.dart
│   │   └── group_detail_provider.dart
│   ├── screens/
│   │   ├── group_chat_screen.dart        # same MessageList widget, group context
│   │   ├── create_group_screen.dart      # name, image, pick members
│   │   └── group_settings_screen.dart    # admin: add/remove members, edit details
│   └── widgets/
│       ├── member_chip.dart
│       └── group_avatar.dart             # stacked avatars if no group image
```

---

## Feature: `community`

Maps to server domain `Community` + `CommunityMember` with `CommunityMemberRole`. A community contains multiple `Chat` rooms.

```
features/community/
├── data/
│   ├── models/
│   │   ├── community_dto.dart            # id, name, description, isPublic, memberCount
│   │   ├── community_member_dto.dart     # userId, role (ADMIN|MODERATOR|MEMBER)
│   │   └── community_room_dto.dart       # chatId, title (room inside the community)
│   └── repositories/
│       └── community_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── community.dart
│   │   ├── community_member.dart
│   │   └── community_room.dart
│   └── repositories/
│       └── community_repository.dart
├── presentation/
│   ├── providers/
│   │   ├── community_list_provider.dart
│   │   ├── community_detail_provider.dart
│   │   └── community_room_provider.dart
│   ├── screens/
│   │   ├── community_list_screen.dart    # browse public communities
│   │   ├── community_detail_screen.dart  # rooms list, member count, join/leave
│   │   ├── community_room_screen.dart    # large-scale chat — uses same message widgets
│   │   ├── create_community_screen.dart
│   │   └── community_admin_screen.dart   # manage members, rooms, moderators
│   └── widgets/
│       ├── community_card.dart
│       ├── room_list_tile.dart
│       └── member_role_badge.dart        # ADMIN | MODERATOR label
```

**Create community room** calls `POST /api/chat/community/start?communityId=&title=`.

---

## Feature: `presence`

Maps to server module **`slink-presence`**. Statuses: `ONLINE | OFFLINE | AWAY`.
Server publishes to `/topic/user.status` via WebSocket.

```
features/presence/
├── data/
│   ├── models/
│   │   └── presence_dto.dart             # userId, status, lastSeen
│   └── repositories/
│       └── presence_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── user_presence.dart
│   └── repositories/
│       └── presence_repository.dart
├── presentation/
│   └── providers/
│       └── presence_provider.dart        # Map<userId, OnlineStatus>
│                                         # updated via STOMP /topic/user.status
```

`OnlineBadge` and `PresenceText` widgets in `core/widgets/` consume `presenceProvider`.

---

## Feature: `notification`

Maps to server module **`slink-notification`**.
REST: `GET /api/notifications`, `/count`, `POST /mark-all-read`.
WebSocket: `/user/queue/notifications`.
Types: `NEW_MESSAGE | READ_RECEIPT | USER_STATUS_CHANGE | SYSTEM`.

```
features/notification/
├── data/
│   ├── models/
│   │   └── notification_dto.dart         # id, type, payload, isRead, createdAt
│   └── repositories/
│       └── notification_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── app_notification.dart
│   └── repositories/
│       └── notification_repository.dart
├── presentation/
│   ├── providers/
│   │   ├── notification_list_provider.dart
│   │   └── unread_count_provider.dart    # drives the bell badge
│   ├── screens/
│   │   └── notifications_screen.dart
│   └── widgets/
│       └── notification_tile.dart
```

Push notifications (background): integrate **Firebase Cloud Messaging** (FCM). Store the FCM token in the user's device record via a `PATCH /api/users/me/device` endpoint (to be added to the server if not present).

---

## Feature: `search`

```
features/search/
├── data/
│   └── repositories/
│       └── search_repository_impl.dart   # combines /api/users?q=, local message Hive query
├── domain/
│   └── repositories/
│       └── search_repository.dart
├── presentation/
│   ├── providers/
│   │   └── search_provider.dart          # debounced AsyncNotifier
│   ├── screens/
│   │   └── search_screen.dart            # unified: users / messages / groups / communities
│   └── widgets/
│       ├── search_result_section.dart    # labelled section header
│       └── message_search_tile.dart      # snippet + chat context
```

Search is client-filtered against the already-fetched user list for contacts. For message search, query the local Hive store; for group/community search, call the relevant API with a `?q=` param.

---

## Navigation (GoRouter)

```dart
// route_names.dart
class Routes {
  static const login         = '/login';
  static const register      = '/register';
  static const home          = '/';            // conversations tab
  static const contacts      = '/contacts';
  static const chat          = '/chat/:chatId';
  static const groupChat     = '/group/:chatId';
  static const communityList = '/communities';
  static const communityDetail = '/communities/:communityId';
  static const communityRoom   = '/communities/:communityId/rooms/:chatId';
  static const search        = '/search';
  static const notifications = '/notifications';
  static const profile       = '/profile/:userId';
  static const settings      = '/settings';
}
```

Auth guard: `redirect` checks `SecureStorage.getToken()`. Unauthenticated → `/login`.

Home uses a `StatefulShellRoute` with a `BottomNavigationBar`:
1. **Chats** — conversations list
2. **Communities** — community browser
3. **Contacts** — platform users + phone-book matches
4. **Notifications** — with unread badge
5. **Profile** — current user settings

---

## WebSocket / STOMP Integration

```dart
// core/websocket/stomp_service.dart

class SlinkStompService {
  // Connects to ws://<host>/ws with Authorization header (JWT)
  void connect(String token);

  // Called after connection — registers user as ONLINE
  void registerUser();            // → /app/chat.addUser

  // Send a chat message
  void sendMessage(SendMessagePayload p);  // → /app/chat.sendMessage

  // Mark a message read
  void markRead(MarkReadPayload p);        // → /app/chat.markRead

  // Send typing indicator
  void sendTyping(String conversationId, String recipientId); // → /app/chat.typing

  // Subscriptions (called once on connect)
  void _subscribeAll() {
    // personal message queue
    client.subscribe('/user/queue/messages', _onMessage);
    // typing events
    client.subscribe('/user/queue/typing', _onTyping);
    // read receipts
    client.subscribe('/user/queue/receipts', _onReceipt);
    // notifications
    client.subscribe('/user/queue/notifications', _onNotification);
    // broadcast presence
    client.subscribe('/topic/user.status', _onPresenceChange);
  }
}
```

The `stompServiceProvider` is a `Provider<SlinkStompService>`. All feature providers that need real-time data `watch` a `StreamProvider` that wraps the STOMP callbacks.

---

## Key Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  # State management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^14.0.0

  # Networking
  dio: ^5.7.0
  stomp_dart_client: ^2.0.0          # STOMP over WebSocket

  # Storage
  flutter_secure_storage: ^9.2.2     # JWT
  hive_flutter: ^1.1.0               # offline message cache
  hive: ^2.2.3

  # Contacts
  flutter_contacts: ^1.1.9+1
  permission_handler: ^11.3.1

  # Push Notifications
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^17.2.2

  # Utilities
  intl: ^0.19.0
  timeago: ^3.7.0
  cached_network_image: ^3.4.1
  image_picker: ^1.1.2               # group/community image upload

dev_dependencies:
  riverpod_generator: ^2.4.3
  build_runner: ^2.4.12
  hive_generator: ^2.0.1
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
```

---

## Data Flow Summary

```
User taps "Send"
  │
  ▼
MessageInputBar
  │  (calls)
  ▼
sendMessageProvider.send(content)
  │  optimistic insert into local Hive + notify messageListProvider
  ▼
SlinkStompService.sendMessage({ chatId, recipientId, content })
  │  WebSocket frame → /app/chat.sendMessage
  ▼
Server broadcasts to /user/queue/messages for recipient
  │
  ▼  (STOMP callback on recipient device)
messageListProvider.append(incomingMessage)
  │
  ▼
MessageBubble rendered

Read receipt flow:
  Bubble appears on screen → markRead called →
  /app/chat.markRead → server pushes to /user/{senderId}/queue/receipts →
  sender's MessageStatusIcon updates to blue ticks (READ)
```

---

## Testing Layout

```
test/
├── unit/
│   ├── auth/
│   │   └── auth_repository_test.dart
│   ├── contacts/
│   │   └── contact_matcher_test.dart     # E.164 normalisation, matching logic
│   ├── message/
│   │   └── message_repository_test.dart
│   └── presence/
│       └── presence_provider_test.dart
├── widget/
│   ├── message_bubble_test.dart
│   ├── contact_tile_test.dart
│   └── conversation_tile_test.dart
└── integration/
    ├── auth_flow_test.dart               # login → home navigation
    └── chat_flow_test.dart               # send → receive round-trip (mock STOMP)
```

---

## Summary Table

| Server Module | Flutter Feature | Primary Transport |
|---|---|---|
| `slink-auth` | `features/auth` | REST |
| `slink-users` | `features/contacts` | REST + device contacts |
| `slink-chat` | `features/chat`, `group`, `community` | REST |
| `slink-message` | `features/message` | STOMP WS + REST (history) |
| `slink-presence` | `features/presence` | STOMP WS `/topic/user.status` |
| `slink-notification` | `features/notification` | REST + STOMP WS + FCM |
| — | `features/search` | REST + local Hive |
