import 'package:flutter/material.dart';

import '../models/card_value_model.dart';
import '../models/game_model.dart';
import '../models/player_model.dart';
import '../services/game_storage.dart';
import '../widgets/card_counter.dart';

class RoundScreen extends StatefulWidget {
  final List<Player> players;
  final Game? savedGame;

  const RoundScreen({super.key, required this.players, this.savedGame});

  @override
  State<RoundScreen> createState() => _RoundScreenState();
}

class _RoundScreenState extends State<RoundScreen> {
  late Player _currentPlayer;

  Map<String, Map<CardValue, int>> _playerCards = {};

  Player? _winner;

  int _currentRound = 1;

  final Map<String, int> _scores = {};

  final List<Map<String, int>> _rounds = [];

  bool _gameFinished = false;

  bool _showScoreTable = true;

  late final String _gameId;

  late final DateTime _gameDate;

  @override
  void initState() {
    super.initState();

    final savedGame = widget.savedGame;

    if (savedGame != null) {
      _gameId = savedGame.id;
      _gameDate = savedGame.date;

      _currentRound = savedGame.currentRound;

      _rounds.addAll(
        savedGame.rounds.map((round) => Map<String, int>.from(round)),
      );

      for (final player in widget.players) {
        _scores[player.id] = savedGame.scores[player.id] ?? 0;
      }

      _playerCards = {
        for (final player in widget.players)
          player.id: {
            for (final card in CardValue.values)
              card: savedGame.playerCards[player.id]?[card] ?? 0,
          },
      };

      _currentPlayer = _getPlayersByScore().first;

      if (savedGame.winnerId != null) {
        final winnerId = savedGame.winnerId;

        _winner = widget.players.firstWhere(
          (player) => player.id == winnerId,
          orElse: () => _getPlayersByScore().first,
        );
      }
    } else {
      _gameId = DateTime.now().millisecondsSinceEpoch.toString();
      _gameDate = DateTime.now();

      for (final player in widget.players) {
        _scores[player.id] = 0;
      }

      _currentPlayer = _getPlayersByScore().first;

      _playerCards = {
        for (final player in widget.players)
          player.id: {for (final card in CardValue.values) card: 0},
      };

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _saveInProgressGame();
      });
    }
  }

  Map<CardValue, int> get _currentCards {
    return _playerCards.putIfAbsent(
      _currentPlayer.id,
      () => {for (final card in CardValue.values) card: 0},
    );
  }

  String get _roundName {
    const rounds = [
      '2 tríos',
      '1 trío + 1 escalera',
      '2 escaleras',
      '3 tríos',
      '2 tríos + 1 escalera',
      '1 trío + 2 escaleras',
      '3 escaleras',
      '2 tríos + 2 escaleras',
    ];

    return rounds[_currentRound - 1];
  }

  int _calculatePoints(Map<CardValue, int> cards) {
    return cards.entries.fold(0, (total, entry) {
      return total + (entry.key.points * entry.value);
    });
  }

  List<Player> _getPlayersByScore() {
    final players = widget.players.toList()
      ..sort((a, b) {
        final scoreA = _scores[a.id] ?? 0;
        final scoreB = _scores[b.id] ?? 0;

        if (scoreA != scoreB) {
          return scoreA.compareTo(scoreB);
        }

        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return players;
  }

  void _addCard(CardValue card) {
    setState(() {
      _currentCards[card] = (_currentCards[card] ?? 0) + 1;
    });

    _saveInProgressGame();
  }

  void _removeCard(CardValue card) {
    if ((_currentCards[card] ?? 0) == 0) {
      return;
    }

    setState(() {
      _currentCards[card] = (_currentCards[card] ?? 0) - 1;
    });

    _saveInProgressGame();
  }

  void _finishRound() {
    final zeroPlayers = widget.players.where((player) {
      final points = _calculatePoints(_playerCards[player.id] ?? {});

      return points == 0;
    }).toList();

    if (zeroPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debe haber un jugador con 0 puntos para ganar la ronda.',
          ),
        ),
      );

      return;
    }

    if (zeroPlayers.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solo un jugador puede tener 0 puntos. '
            'Ese jugador será el ganador.',
          ),
        ),
      );

      return;
    }

    final winner = zeroPlayers.first;

    setState(() {
      _winner = winner;
    });

    _saveInProgressGame();
  }

  int _roundPoints(Player player) {
    if (_winner?.id == player.id) {
      return -25;
    }

    return _calculatePoints(_playerCards[player.id]!);
  }

  Future<void> _nextRound() async {
    final roundScores = <String, int>{};

    for (final player in widget.players) {
      final points = _roundPoints(player);

      roundScores[player.id] = points;

      _scores[player.id] = (_scores[player.id] ?? 0) + points;
    }

    _rounds.add(roundScores);

    if (_currentRound == 8) {
      await _saveFinishedGame();

      if (!mounted) {
        return;
      }

      setState(() {
        _gameFinished = true;
      });

      return;
    }

    final nextPlayer = _getPlayersByScore().first;

    setState(() {
      _currentRound++;
      _winner = null;
      _currentPlayer = nextPlayer;
      _showScoreTable = true;

      _playerCards = {
        for (final player in widget.players)
          player.id: {for (final card in CardValue.values) card: 0},
      };
    });

    await _saveInProgressGame();
  }

  Future<void> _saveInProgressGame() async {
    final game = Game(
      id: _gameId,
      date: _gameDate,
      players: {for (final player in widget.players) player.id: player.name},
      currentRound: _currentRound,
      rounds: List<Map<String, int>>.from(_rounds),
      scores: {
        for (final player in widget.players) player.id: _scores[player.id] ?? 0,
      },
      finished: false,
      playerCards: {
        for (final entry in _playerCards.entries)
          entry.key: Map<CardValue, int>.from(entry.value),
      },
      currentPlayerId: _currentPlayer.id,
      winnerId: _winner?.id,
    );

    await GameStorage.saveCurrentGame(game);
  }

  Future<void> _saveFinishedGame() async {
    final games = await GameStorage.loadGames();

    final game = Game(
      id: _gameId,
      date: _gameDate,
      players: {for (final player in widget.players) player.id: player.name},
      currentRound: _currentRound,
      rounds: List<Map<String, int>>.from(_rounds),
      scores: {
        for (final player in widget.players) player.id: _scores[player.id] ?? 0,
      },
      finished: true,
      playerCards: {
        for (final entry in _playerCards.entries)
          entry.key: Map<CardValue, int>.from(entry.value),
      },
      currentPlayerId: _currentPlayer.id,
      winnerId: _winner?.id,
    );

    games.add(game);

    await GameStorage.saveGames(games);
    await GameStorage.deleteCurrentGame();
  }

  Future<bool> _confirmExitGame(BuildContext dialogContext) async {
    final shouldExit = await showDialog<bool>(
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('¿Salir de la partida?'),
          content: const Text(
            'La partida se guardará y podrás continuarla más tarde.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Guardar y salir'),
            ),
          ],
        );
      },
    );

    return shouldExit ?? false;
  }

  Future<void> _selectPlayer() async {
    final players = _getPlayersByScore();

    final player = await showDialog<Player>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('¿A quién puntuar?'),
          children: players.map((player) {
            final isCurrent = player.id == _currentPlayer.id;

            return SimpleDialogOption(
              onPressed: () {
                Navigator.of(context).pop(player);
              },
              child: Row(
                children: [
                  Icon(
                    isCurrent
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      player.name,
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );

    if (player == null) {
      return;
    }

    setState(() {
      _currentPlayer = player;
    });

    await _saveInProgressGame();
  }

  Widget _buildScoreTable() {
    final ranking = _getPlayersByScore();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showScoreTable = !_showScoreTable;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.scoreboard, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Puntuación',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${_scores[_currentPlayer.id] ?? 0} pts',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _showScoreTable
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),
          if (_showScoreTable)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 4),
                  ...ranking.map((player) {
                    final score = _scores[player.id] ?? 0;
                    final isCurrent = player.id == _currentPlayer.id;
                    final roundPoints = _calculatePoints(
                      _playerCards[player.id] ?? {},
                    );

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (isCurrent)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(Icons.person, size: 16),
                                  ),
                                Flexible(
                                  child: Text(
                                    '${player.name} ($roundPoints)',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$score puntos',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlayer() {
    final currentPoints = _calculatePoints(_currentCards);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        onTap: _selectPlayer,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Icon(
                Icons.person,
                size: 29,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _currentPlayer.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              Text(
                '$currentPoints pts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.swap_vert,
                size: 26,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundResult() {
    final ranking = widget.players.toList()
      ..sort((a, b) => _roundPoints(a).compareTo(_roundPoints(b)));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Icon(Icons.emoji_events, size: 58),
            const SizedBox(height: 8),
            const Text(
              'Resultado de la ronda',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${_winner!.name} ha ganado',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.builder(
                itemCount: ranking.length,
                itemBuilder: (context, index) {
                  final player = ranking[index];
                  final points = _roundPoints(player);
                  final isWinner = player.id == _winner!.id;

                  return Card(
                    color: isWinner
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(
                        player.name,
                        style: TextStyle(
                          fontWeight: isWinner
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            points > 0 ? '+$points' : '$points',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isWinner
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                          Text(
                            'Total: '
                            '${(_scores[player.id] ?? 0) + points}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _nextRound,
                    child: Text(
                      _currentRound == 8
                          ? 'Finalizar partida'
                          : 'Confirmar resultado ronda',
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _winner = null;
                      });

                      _saveInProgressGame();
                    },
                    child: const Text('Volver', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalResult() {
    final ranking = widget.players.toList()
      ..sort((a, b) => (_scores[a.id] ?? 0).compareTo(_scores[b.id] ?? 0));

    final winningScore = _scores[ranking.first.id] ?? 0;

    final winners = ranking.where((player) {
      return (_scores[player.id] ?? 0) == winningScore;
    }).toList();

    final hasTie = winners.length > 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 14),
            Icon(hasTie ? Icons.handshake : Icons.emoji_events, size: 76),
            const SizedBox(height: 10),
            Text(
              hasTie ? 'Empate' : 'Partida terminada',
              style: const TextStyle(fontSize: 29, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              hasTie
                  ? winners.map((player) => player.name).join(' y ')
                  : winners.first.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              hasTie ? 'Han quedado empatados' : '¡Enhorabuena!',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: ranking.length,
                itemBuilder: (context, index) {
                  final player = ranking[index];
                  final points = _scores[player.id] ?? 0;
                  final isWinner = points == winningScore;

                  return Card(
                    color: isWinner
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(
                        player.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: isWinner
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: Text(
                        '$points puntos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isWinner
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  'Volver al inicio',
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _gameFinished,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _gameFinished) {
          return;
        }

        final navigator = Navigator.of(context);

        final shouldExit = await _confirmExitGame(context);

        if (!mounted || !shouldExit) {
          return;
        }

        await _saveInProgressGame();

        if (!mounted) {
          return;
        }

        navigator.popUntil((route) => route.isFirst);
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Ronda $_currentRound de 8')),
        body: _gameFinished
            ? _buildFinalResult()
            : _winner == null
            ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: Column(
                      children: [
                        Text(
                          _roundName,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Ronda $_currentRound de 8',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildScoreTable(),
                  _buildCurrentPlayer(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: CardValue.values.length,
                      itemBuilder: (context, index) {
                        final card = CardValue.values[index];

                        return CardCounter(
                          card: card,
                          quantity: _currentCards[card] ?? 0,
                          onAdd: () => _addCard(card),
                          onRemove: () => _removeCard(card),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_calculatePoints(_currentCards)} '
                                'puntos',
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed: _finishRound,
                              child: const Text(
                                'Terminar ronda',
                                style: TextStyle(fontSize: 17),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : _buildRoundResult(),
      ),
    );
  }
}
