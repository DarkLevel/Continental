import 'package:flutter/material.dart';

import '../models/game_model.dart';
import '../services/game_storage.dart';
import 'game_detail_screen.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  List<Game> _games = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    final games = await GameStorage.loadGames();

    if (!mounted) {
      return;
    }

    setState(() {
      _games = games.reversed.toList();
      _loading = false;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _deleteGame(Game game) async {
    await GameStorage.deleteGame(game.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _games.removeWhere((item) => item.id == game.id);
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Partida eliminada'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () async {
            final games = await GameStorage.loadGames();

            if (games.any((item) => item.id == game.id)) {
              return;
            }

            games.add(game);

            await GameStorage.saveGames(games);

            if (!mounted) {
              return;
            }

            setState(() {
              _games = games.reversed.toList();
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (!mounted) {
          return;
        }

        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Historial')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _games.isEmpty
            ? const Center(
                child: Text(
                  'No hay partidas jugadas',
                  style: TextStyle(fontSize: 18),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _games.length,
                itemBuilder: (context, index) {
                  final game = _games[index];

                  final ranking = game.players.entries.toList()
                    ..sort(
                      (a, b) => (game.scores[a.key] ?? 0).compareTo(
                        game.scores[b.key] ?? 0,
                      ),
                    );

                  final winnerName = ranking.first.value;

                  final winnerScore = game.scores[ranking.first.key] ?? 0;

                  return Dismissible(
                    key: ValueKey(game.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.only(right: 24),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      await _deleteGame(game);
                      return false;
                    },
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.emoji_events),
                        title: Text(
                          winnerName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${_formatDate(game.date)}'
                          ' · ${game.players.length} jugadores',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$winnerScore puntos',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 20),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  GameDetailScreen(game: game),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
