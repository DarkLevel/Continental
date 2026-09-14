import 'package:flutter/material.dart';

import '../models/player_model.dart';
import 'round_screen.dart';

class NewGameScreen extends StatefulWidget {
  final List<Player> players;

  const NewGameScreen({super.key, required this.players});

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  final Set<String> _selectedPlayerIds = {};

  void _togglePlayer(Player player, bool selected) {
    setState(() {
      if (selected) {
        _selectedPlayerIds.add(player.id);
      } else {
        _selectedPlayerIds.remove(player.id);
      }
    });
  }

  void _startGame() {
    if (_selectedPlayerIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos 2 jugadores')),
      );
      return;
    }

    final selectedPlayers = widget.players
        .where((player) => _selectedPlayerIds.contains(player.id))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoundScreen(players: selectedPlayers),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = widget.players.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva partida')),
      body: widget.players.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No tienes jugadores creados.\n\n'
                  'Ve a Jugadores para añadirlos antes de empezar una partida.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '¿Quién juega?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_selectedPlayerIds.length} jugadores seleccionados',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: sortedPlayers.length,
                      itemBuilder: (context, index) {
                        final player = sortedPlayers[index];
                        final isSelected = _selectedPlayerIds.contains(
                          player.id,
                        );

                        return Card(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              _togglePlayer(player, value ?? false);
                            },
                            secondary: CircleAvatar(
                              backgroundColor: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                              foregroundColor: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : null,
                              child: Text(player.name[0].toUpperCase()),
                            ),
                            title: Text(
                              player.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _startGame,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text(
                          'Empezar partida',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
