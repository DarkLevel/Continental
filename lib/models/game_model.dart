import 'card_value_model.dart';

class Game {
  final String id;
  final DateTime date;
  final Map<String, String> players;
  final int currentRound;
  final List<Map<String, int>> rounds;
  final Map<String, int> scores;
  final bool finished;

  final Map<String, Map<CardValue, int>> playerCards;
  final String currentPlayerId;
  final String? winnerId;

  Game({
    required this.id,
    required this.date,
    required this.players,
    required this.currentRound,
    required this.rounds,
    required this.scores,
    required this.finished,
    required this.playerCards,
    required this.currentPlayerId,
    this.winnerId,
  });
}
