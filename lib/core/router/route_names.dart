class Routes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const contacts = '/contacts';
  static const chat = '/chat/:chatId';
  static const communityList = '/communities';
  static const communityDetail = '/communities/:communityId';
  static const notifications = '/notifications';
  static const search = '/search';
  static const profile = '/profile/:userId';
  static const settings = '/settings';

  // Builders
  static String chatPath(String chatId) => '/chat/$chatId';
  static String communityDetailPath(String id) => '/communities/$id';
  static String profilePath(String userId) => '/profile/$userId';
}
