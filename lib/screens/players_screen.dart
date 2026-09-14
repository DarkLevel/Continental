import 'package:flutter/material.dart';

import '../models/player_model.dart';
import '../services/player_storage.dart';

class PlayersScreen extends StatefulWidget {
  final List<Player> players;

  const PlayersScreen({super.key, required this.players});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  Future<void> _addPlayer() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nuevo jugador'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );

    if (name == null || name.trim().isEmpty) {
      return;
    }

    final trimmedName = name.trim();

    final alreadyExists = widget.players.any(
      (player) => player.name.toLowerCase() == trimmedName.toLowerCase(),
    );

    if (alreadyExists) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya existe un jugador con ese nombre')),
      );

      return;
    }

    final player = Player(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: trimmedName,
    );

    setState(() {
      widget.players.add(player);
    });

    await PlayerStorage.savePlayers(widget.players);
  }

  Future<void> _editPlayer(Player player) async {
    final controller = TextEditingController(text: player.name);

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar jugador'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (name == null || name.trim().isEmpty) {
      return;
    }

    final trimmedName = name.trim();

    final alreadyExists = widget.players.any(
      (item) =>
          item.id != player.id &&
          item.name.toLowerCase() == trimmedName.toLowerCase(),
    );

    if (alreadyExists) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya existe un jugador con ese nombre')),
      );

      return;
    }

    setState(() {
      player.name = trimmedName;
    });

    await PlayerStorage.savePlayers(widget.players);
  }

  Future<void> _removePlayer(Player player) async {
    setState(() {
      widget.players.removeWhere((item) => item.id == player.id);
    });

    await PlayerStorage.savePlayers(widget.players);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${player.name} eliminado'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () async {
            setState(() {
              widget.players.add(player);
            });

            await PlayerStorage.savePlayers(widget.players);

            if (!mounted) {
              return;
            }

            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = widget.players.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

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
        appBar: AppBar(title: const Text('Jugadores')),
        body: sortedPlayers.isEmpty
            ? const Center(
                child: Text('No hay jugadores', style: TextStyle(fontSize: 18)),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedPlayers.length,
                itemBuilder: (context, index) {
                  final player = sortedPlayers[index];

                  return Dismissible(
                    key: ValueKey(player.id),
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
                      await _removePlayer(player);
                      return false;
                    },
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(
                          player.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: () {
                            _editPlayer(player);
                          },
                          icon: const Icon(Icons.edit),
                          tooltip: 'Editar',
                        ),
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addPlayer,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
