import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  // ── Player session ─────────────────────────────────────────────────────────
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

  // ── Managed (admin) session ────────────────────────────────────────────────
  static const _keyMgmtGameId   = 'mgmt_gameId';
  static const _keyMgmtJoinCode = 'mgmt_joinCode';
  static const _keyMgmtTitle    = 'mgmt_title';

  static Future<void> saveManaged({
    required String gameId,
    required String joinCode,
    String title = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMgmtGameId,   gameId);
    await prefs.setString(_keyMgmtJoinCode, joinCode);
    await prefs.setString(_keyMgmtTitle,    title);
  }

  static Future<Map<String, String>?> loadManaged() async {
    final prefs = await SharedPreferences.getInstance();
    final gameId   = prefs.getString(_keyMgmtGameId);
    final joinCode = prefs.getString(_keyMgmtJoinCode);
    final title    = prefs.getString(_keyMgmtTitle) ?? '';
    if (gameId == null || joinCode == null) return null;
    return {'gameId': gameId, 'joinCode': joinCode, 'title': title};
  }

  static Future<void> clearManaged() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMgmtGameId);
    await prefs.remove(_keyMgmtJoinCode);
    await prefs.remove(_keyMgmtTitle);
  }
}
