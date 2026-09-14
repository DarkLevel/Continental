import 'package:flutter/material.dart';

import 'models/player_model.dart';
import 'screens/games_screen.dart';
import 'screens/new_game_screen.dart';
import 'screens/players_screen.dart';
import 'screens/round_screen.dart';
import 'services/game_storage.dart';
import 'services/player_storage.dart';

void main() {
  runApp(const ContinentalApp());
}

class ContinentalApp extends StatelessWidget {
  const ContinentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Continental',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,

        scaffoldBackgroundColor: const Color(0xFFF3F1EA),

        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF789985),
              brightness: Brightness.light,
            ).copyWith(
              // VERDE SALVIA — color principal
              primary: const Color(0xFF789985),
              onPrimary: Colors.white,
              primaryContainer: const Color(0xFFC9DCCF),
              onPrimaryContainer: const Color(0xFF304A38),

              // AZUL LAVANDA — contraste principal
              secondary: const Color(0xFF8197B5),
              onSecondary: Colors.white,
              secondaryContainer: const Color(0xFFD0DCEB),
              onSecondaryContainer: const Color(0xFF35445A),

              // AMARILLO MANTEQUILLA — destacados
              tertiary: const Color(0xFFC5AE70),
              onTertiary: const Color(0xFF4B4024),
              tertiaryContainer: const Color(0xFFE9DDB5),
              onTertiaryContainer: const Color(0xFF51472B),

              // SUPERFICIES
              surface: const Color(0xFFFFFCF7),
              onSurface: const Color(0xFF353936),

              // ROJO ROSADO — errores / eliminar
              error: const Color(0xFFB97878),
              onError: Colors.white,
              errorContainer: const Color(0xFFEBCACA),
              onErrorContainer: const Color(0xFF573333),
            ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFC9DCCF),
          foregroundColor: Color(0xFF304A38),
          centerTitle: true,
          elevation: 0,
        ),

        cardTheme: CardThemeData(
          color: const Color(0xFFFFFCF7),
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFCF7),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD2D5CF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF789985), width: 2),
          ),
        ),

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF789985),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF647C9A),
            side: const BorderSide(color: Color(0xFF9EADC1), width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF8197B5),
          foregroundColor: Colors.white,
        ),

        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF718378),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Player> _players = [];

  bool _loading = true;
  bool _hasCurrentGame = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final savedPlayers = await PlayerStorage.loadPlayers();
    final currentGame = await GameStorage.loadCurrentGame();

    if (!mounted) {
      return;
    }

    setState(() {
      _players
        ..clear()
        ..addAll(savedPlayers);

      _hasCurrentGame = currentGame != null;
      _loading = false;
    });
  }

  Future<void> _openPlayers() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlayersScreen(players: _players)),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _openNewGame() async {
    if (_hasCurrentGame) {
      final shouldStartNewGame = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Partida en curso'),
            content: const Text(
              'Ya tienes una partida en curso. '
              'Si empiezas una nueva, perderás la posibilidad '
              'de continuar la actual.',
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
                child: const Text('Nueva partida'),
              ),
            ],
          );
        },
      );

      if (shouldStartNewGame != true) {
        return;
      }

      await GameStorage.deleteCurrentGame();

      if (!mounted) {
        return;
      }

      setState(() {
        _hasCurrentGame = false;
      });
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewGameScreen(players: _players)),
    );

    await _loadData();
  }

  Future<void> _continueGame() async {
    final game = await GameStorage.loadCurrentGame();

    if (!mounted || game == null) {
      return;
    }

    final players = game.players.entries.map((entry) {
      return Player(id: entry.key, name: entry.value);
    }).toList();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoundScreen(players: players, savedGame: game),
      ),
    );

    await _loadData();
  }

  Future<void> _openGames() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GamesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('CONTINENTAL')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Gestor de puntuaciones',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              if (_hasCurrentGame) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _continueGame,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'Continuar partida',
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _openNewGame,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Nueva partida',
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _openPlayers,
                  icon: const Icon(Icons.people),
                  label: const Text(
                    'Jugadores',
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _openGames,
                  icon: const Icon(Icons.history),
                  label: const Text(
                    'Historial',
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
