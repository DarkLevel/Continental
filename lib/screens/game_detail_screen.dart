import 'package:flutter/material.dart';

import '../models/game_model.dart';

class GameDetailScreen extends StatelessWidget {
  final Game game;

  const GameDetailScreen({super.key, required this.game});

  static const List<String> _roundNames = [
    '2 tríos',
    '1 trío + 1 escalera',
    '2 escaleras',
    '3 tríos',
    '2 tríos + 1 escalera',
    '1 trío + 2 escaleras',
    '3 escaleras',
  ];

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ranking = game.players.entries.toList()
      ..sort(
        (a, b) => (game.scores[a.key] ?? 0).compareTo(game.scores[b.key] ?? 0),
      );

    final winner = ranking.first;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de partida')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _formatDate(game.date),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          const Icon(Icons.emoji_events, size: 64),
          const SizedBox(height: 8),

          Text(
            winner.value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),

          const Text('Ganador', textAlign: TextAlign.center),

          const SizedBox(height: 24),

          const Text(
            'Clasificación final',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          ...ranking.asMap().entries.map((entry) {
            final position = entry.key + 1;
            final player = entry.value;
            final score = game.scores[player.key] ?? 0;

            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('$position')),
                title: Text(
                  player.value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  '$score puntos',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          const Text(
            'Resumen de rondas',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (game.rounds.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Esta partida no contiene el detalle de las rondas.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            _buildRoundsTable(context),
        ],
      ),
    );
  }

  Widget _buildRoundsTable(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowHeight: 52,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 56,
          columns: [
            const DataColumn(
              label: Text(
                'Jugador',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...List.generate(game.rounds.length, (index) {
              return DataColumn(
                label: Tooltip(
                  message: index < _roundNames.length
                      ? _roundNames[index]
                      : 'Ronda ${index + 1}',
                  child: Text(
                    'R${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
            const DataColumn(
              label: Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: game.players.entries.map((player) {
            final total = game.scores[player.key] ?? 0;

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    player.value,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                ...List.generate(game.rounds.length, (roundIndex) {
                  final points = game.rounds[roundIndex][player.key] ?? 0;

                  final isWinner = points == -25;

                  return DataCell(
                    Text(
                      points > 0 ? '+$points' : '$points',
                      style: TextStyle(
                        fontWeight: isWinner
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isWinner
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                  );
                }),

                DataCell(
                  Text(
                    '$total',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
