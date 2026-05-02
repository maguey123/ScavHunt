import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _keyGameId   = 'session_gameId';
  static const _keyTeamName = 'session_teamName';
  static const _keyPlayerId = 'session_playerId';

  static Future<void> save({
    required String gameId,
    required String teamName,
    required String playerId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGameId,   gameId);
    await prefs.setString(_keyTeamName, teamName);
    await prefs.setString(_keyPlayerId, playerId);
  }

  static Future<Map<String, String>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final gameId   = prefs.getString(_keyGameId);
    final teamName = prefs.getString(_keyTeamName);
    final playerId = prefs.getString(_keyPlayerId);
    if (gameId == null || teamName == null || playerId == null) return null;
    return {'gameId': gameId, 'teamName': teamName, 'playerId': playerId};
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyGameId);
    await prefs.remove(_keyTeamName);
    await prefs.remove(_keyPlayerId);
  }
}
