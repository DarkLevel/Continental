import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_model.dart';

class PlayerStorage {
  static const String _playersKey = 'players';

  static Future<List<Player>> loadPlayers() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString(_playersKey);

    if (data == null) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(data);

    return decoded.map((item) {
      return Player(id: item['id'] as String, name: item['name'] as String);
    }).toList();
  }

  static Future<void> savePlayers(List<Player> players) async {
    final prefs = await SharedPreferences.getInstance();

    final data = players.map((player) {
      return {'id': player.id, 'name': player.name};
    }).toList();

    await prefs.setString(_playersKey, jsonEncode(data));
  }
}
