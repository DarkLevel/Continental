import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/card_value_model.dart';
import '../models/game_model.dart';

class GameStorage {
  static const String _gamesKey = 'games';
  static const String _currentGameKey = 'current_game';

  static Future<List<Game>> loadGames() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString(_gamesKey);

    if (data == null) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(data);

    return decoded.map((item) {
      final players = Map<String, String>.from(item['players'] as Map);

      final rawPlayerCards = item['playerCards'] as Map?;

      final Map<String, Map<CardValue, int>> playerCards;

      if (rawPlayerCards == null) {
        playerCards = {
          for (final playerId in players.keys)
            playerId: {for (final card in CardValue.values) card: 0},
        };
      } else {
        playerCards = {
          for (final entry in rawPlayerCards.entries)
            entry.key as String: _cardsFromJson(
              Map<String, dynamic>.from(entry.value as Map),
            ),
        };
      }

      return Game(
        id: item['id'] as String,
        date: DateTime.parse(item['date'] as String),
        players: players,
        currentRound: item['currentRound'] as int? ?? 1,
        rounds: ((item['rounds'] as List?) ?? [])
            .map((round) => Map<String, int>.from(round as Map))
            .toList(),
        scores: Map<String, int>.from(item['scores'] as Map),
        finished: item['finished'] as bool? ?? true,
        playerCards: playerCards,
        currentPlayerId:
            item['currentPlayerId'] as String? ?? players.keys.first,
        winnerId: item['winnerId'] as String?,
      );
    }).toList();
  }

  static Future<void> saveGames(List<Game> games) async {
    final prefs = await SharedPreferences.getInstance();

    final data = games.map((game) {
      return _gameToJson(game);
    }).toList();

    await prefs.setString(_gamesKey, jsonEncode(data));
  }

  static Future<void> deleteGame(String gameId) async {
    final games = await loadGames();

    games.removeWhere((game) => game.id == gameId);

    await saveGames(games);
  }

  static Future<Game?> loadCurrentGame() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString(_currentGameKey);

    if (data == null) {
      return null;
    }

    final decoded = jsonDecode(data);

    return _gameFromJson(decoded);
  }

  static Future<void> saveCurrentGame(Game game) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_currentGameKey, jsonEncode(_gameToJson(game)));
  }

  static Future<void> deleteCurrentGame() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_currentGameKey);
  }

  static Map<String, dynamic> _gameToJson(Game game) {
    return {
      'id': game.id,
      'date': game.date.toIso8601String(),
      'players': game.players,
      'currentRound': game.currentRound,
      'rounds': game.rounds,
      'scores': game.scores,
      'finished': game.finished,
      'playerCards': {
        for (final entry in game.playerCards.entries)
          entry.key: _cardsToJson(entry.value),
      },
      'currentPlayerId': game.currentPlayerId,
      'winnerId': game.winnerId,
    };
  }

  static Game _gameFromJson(dynamic data) {
    final item = Map<String, dynamic>.from(data as Map);

    final players = Map<String, String>.from(item['players'] as Map);

    final rawPlayerCards = item['playerCards'] as Map?;

    final Map<String, Map<CardValue, int>> playerCards;

    if (rawPlayerCards == null) {
      playerCards = {
        for (final playerId in players.keys)
          playerId: {for (final card in CardValue.values) card: 0},
      };
    } else {
      playerCards = {
        for (final entry in rawPlayerCards.entries)
          entry.key as String: _cardsFromJson(
            Map<String, dynamic>.from(entry.value as Map),
          ),
      };
    }

    return Game(
      id: item['id'] as String,
      date: DateTime.parse(item['date'] as String),
      players: players,
      currentRound: item['currentRound'] as int? ?? 1,
      rounds: ((item['rounds'] as List?) ?? [])
          .map((round) => Map<String, int>.from(round as Map))
          .toList(),
      scores: Map<String, int>.from(item['scores'] as Map),
      finished: item['finished'] as bool? ?? false,
      playerCards: playerCards,
      currentPlayerId: item['currentPlayerId'] as String? ?? players.keys.first,
      winnerId: item['winnerId'] as String?,
    );
  }

  static Map<String, int> _cardsToJson(Map<CardValue, int> cards) {
    return {for (final entry in cards.entries) entry.key.name: entry.value};
  }

  static Map<CardValue, int> _cardsFromJson(Map<String, dynamic> cards) {
    return {
      for (final entry in cards.entries)
        CardValue.values.byName(entry.key): entry.value as int,
    };
  }
}
