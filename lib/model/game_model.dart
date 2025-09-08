import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import 'dart:math';

class GameModel {
  static const int gridSize = 4;

  late List<List<int>> board;
  int score = 0;
  final Random random = Random();

  GameModel() {
    resetGame();
  }

  void resetGame() {
    board = List.generate(gridSize, (_) => List.filled(gridSize, 0));
    score = 0;
    _spawnTile();
    _spawnTile();
  }

  List<List<int>> getBoard() {
    return List.generate(
        gridSize, (i) => List.from(board[i])); // deep copy for safe use
  }

  void _spawnTile() {
    final empty = <Point<int>>[];
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (board[y][x] == 0) empty.add(Point(x, y));
      }
    }
    if (empty.isNotEmpty) {
      final pos = empty[random.nextInt(empty.length)];
      board[pos.y][pos.x] = random.nextDouble() < 0.9 ? 2 : 4;
    }
  }

  bool move(String direction) {
    final before = getBoard();
    switch (direction) {
      case 'up':
        _moveUp();
        break;
      case 'down':
        _moveDown();
        break;
      case 'left':
        _moveLeft();
        break;
      case 'right':
        _moveRight();
        break;
    }
    final after = getBoard();
    if (!_boardsEqual(before, after)) {
      _spawnTile();
      return true;
    }
    return false;
  }

  void _moveLeft() {
    for (int y = 0; y < gridSize; y++) {
      List<int> row = board[y].where((e) => e != 0).toList();
      for (int i = 0; i < row.length - 1; i++) {
        if (row[i] == row[i + 1]) {
          row[i] *= 2;
          score += row[i];
          row[i + 1] = 0;
        }
      }
      row = row.where((e) => e != 0).toList();
      while (row.length < gridSize) {
        row.add(0);
      }
      board[y] = row;
    }
  }

  void _moveRight() {
    for (int y = 0; y < gridSize; y++) {
      List<int> row = board[y].reversed.where((e) => e != 0).toList();
      for (int i = 0; i < row.length - 1; i++) {
        if (row[i] == row[i + 1]) {
          row[i] *= 2;
          score += row[i];
          row[i + 1] = 0;
        }
      }
      row = row.where((e) => e != 0).toList();
      while (row.length < gridSize) {
        row.add(0);
      }
      board[y] = row.reversed.toList();
    }
  }

  void _moveUp() {
    for (int x = 0; x < gridSize; x++) {
      List<int> col = [];
      for (int y = 0; y < gridSize; y++) {
        if (board[y][x] != 0) col.add(board[y][x]);
      }
      for (int i = 0; i < col.length - 1; i++) {
        if (col[i] == col[i + 1]) {
          col[i] *= 2;
          score += col[i];
          col[i + 1] = 0;
        }
      }
      col = col.where((e) => e != 0).toList();
      while (col.length < gridSize) {
        col.add(0);
      }
      for (int y = 0; y < gridSize; y++) {
        board[y][x] = col[y];
      }
    }
  }

  void _moveDown() {
    for (int x = 0; x < gridSize; x++) {
      List<int> col = [];
      for (int y = gridSize - 1; y >= 0; y--) {
        if (board[y][x] != 0) col.add(board[y][x]);
      }
      for (int i = 0; i < col.length - 1; i++) {
        if (col[i] == col[i + 1]) {
          col[i] *= 2;
          score += col[i];
          col[i + 1] = 0;
        }
      }
      col = col.where((e) => e != 0).toList();
      while (col.length < gridSize) {
        col.add(0);
      }
      for (int y = gridSize - 1, k = 0; y >= 0; y--, k++) {
        board[y][x] = col[k];
      }
    }
  }

  bool _boardsEqual(List<List<int>> a, List<List<int>> b) {
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (a[y][x] != b[y][x]) return false;
      }
    }
    return true;
  }

  bool isGameOver() {
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (board[y][x] == 0) return false;
        if (x + 1 < gridSize && board[y][x] == board[y][x + 1]) return false;
        if (y + 1 < gridSize && board[y][x] == board[y + 1][x]) return false;
      }
    }
    return true;
  }
}

class Game2048Page extends StatefulWidget {
  const Game2048Page({super.key});

  @override
  State<Game2048Page> createState() => _Game2048PageState();
}

class _Game2048PageState extends State<Game2048Page>
    with TickerProviderStateMixin {
  late GameModel gameModel;
  late AnimationController _animationController;
  late AnimationController _scoreAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    gameModel = GameModel();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: Curves.bounceOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scoreAnimationController.dispose();
    super.dispose();
  }

  void _onSwipe(String direction) {
    final oldScore = gameModel.score;
    if (gameModel.move(direction)) {
      setState(() {});
      _animationController.forward().then((_) {
        _animationController.reverse();
      });

      if (gameModel.score > oldScore) {
        _scoreAnimationController.forward().then((_) {
          _scoreAnimationController.reverse();
        });
      }

      if (gameModel.isGameOver()) {
        _showGameOverDialog();
      }
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return AlertDialog(
              backgroundColor:
                  themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Game Over!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 24,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 60,
                    color:
                        themeProvider.isDarkMode ? Colors.amber : Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Final Score: ${gameModel.score}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.isDarkMode
                          ? Colors.white70
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Exit',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.red[300]
                          : Colors.red,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.isDarkMode
                        ? Colors.teal
                        : const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      gameModel.resetGame();
                    });
                  },
                  child: const Text('Play Again'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getTileColor(int value, bool isDarkMode) {
    if (value == 0) return isDarkMode ? Colors.grey[700]! : Colors.grey[200]!;

    final colors = isDarkMode
        ? {
            2: Colors.grey[600]!,
            4: Colors.grey[500]!,
            8: Colors.orange[700]!,
            16: Colors.orange[600]!,
            32: Colors.red[700]!,
            64: Colors.red[600]!,
            128: Colors.yellow[700]!,
            256: Colors.yellow[600]!,
            512: Colors.green[700]!,
            1024: Colors.green[600]!,
            2048: Colors.blue[700]!,
          }
        : {
            2: Colors.grey[100]!,
            4: Colors.grey[200]!,
            8: Colors.orange[200]!,
            16: Colors.orange[300]!,
            32: Colors.red[200]!,
            64: Colors.red[300]!,
            128: Colors.yellow[200]!,
            256: Colors.yellow[300]!,
            512: Colors.green[200]!,
            1024: Colors.green[300]!,
            2048: Colors.blue[300]!,
          };

    return colors[value] ??
        (isDarkMode ? Colors.purple[700]! : Colors.purple[300]!);
  }

  Color _getTextColor(int value, bool isDarkMode) {
    if (value == 0) return Colors.transparent;
    if (value <= 4) return isDarkMode ? Colors.white : Colors.grey[800]!;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode
              ? Colors.grey[900]
              : const Color(0xFFF8F9FA),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: themeProvider.isDarkMode
                ? Colors.grey[800]
                : const Color(0xFF1565C0),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: themeProvider.isDarkMode
                      ? [
                          Colors.grey[800]!,
                          Colors.grey[700]!,
                          Colors.teal[600]!,
                        ]
                      : [
                          const Color(0xFF1565C0),
                          const Color(0xFF42A5F5),
                          const Color(0xFF81C784),
                        ],
                ),
              ),
            ),
            title: const Text(
              '2048 Game',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    themeProvider.toggleTheme();
                  },
                ),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: themeProvider.isDarkMode
                    ? [
                        Colors.grey[900]!,
                        Colors.grey[850]!,
                      ]
                    : [
                        const Color(0xFFF8F9FA),
                        const Color(0xFFFFFFFF),
                      ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Score Section
                    AnimatedBuilder(
                      animation: _scoreAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_scoreAnimation.value * 0.1),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: themeProvider.isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: themeProvider.isDarkMode
                                      ? Colors.black26
                                      : Colors.grey.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      'SCORE',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: themeProvider.isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${gameModel.score}',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: themeProvider.isDarkMode
                                            ? Colors.teal
                                            : const Color(0xFF1565C0),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  height: 50,
                                  width: 1,
                                  color: themeProvider.isDarkMode
                                      ? Colors.grey[600]
                                      : Colors.grey[300],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      'BEST',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: themeProvider.isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${gameModel.score}', // You can implement best score tracking
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: themeProvider.isDarkMode
                                            ? Colors.amber
                                            : Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode
                            ? Colors.grey[800]?.withOpacity(0.5)
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                        border: themeProvider.isDarkMode
                            ? Border.all(color: Colors.grey[600]!, width: 0.5)
                            : null,
                      ),
                      child: Text(
                        'Swipe to move tiles. Combine tiles with the same number to reach 2048!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: themeProvider.isDarkMode
                              ? Colors.grey[300]
                              : Colors.blue[800],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Game Board
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: AnimatedBuilder(
                            animation: _scaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _scaleAnimation.value,
                                child: GestureDetector(
                                  onPanEnd: (details) {
                                    final velocity =
                                        details.velocity.pixelsPerSecond;
                                    if (velocity.dx.abs() > velocity.dy.abs()) {
                                      if (velocity.dx > 0) {
                                        _onSwipe('right');
                                      } else {
                                        _onSwipe('left');
                                      }
                                    } else {
                                      if (velocity.dy > 0) {
                                        _onSwipe('down');
                                      } else {
                                        _onSwipe('up');
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: themeProvider.isDarkMode
                                          ? Colors.grey[700]
                                          : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: themeProvider.isDarkMode
                                              ? Colors.black26
                                              : Colors.grey.withOpacity(0.3),
                                          spreadRadius: 2,
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: GridView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                      ),
                                      itemCount: 16,
                                      itemBuilder: (context, index) {
                                        final row = index ~/ 4;
                                        final col = index % 4;
                                        final value = gameModel.board[row][col];

                                        return AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 150),
                                          decoration: BoxDecoration(
                                            color: _getTileColor(value,
                                                themeProvider.isDarkMode),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: value != 0
                                                ? [
                                                    BoxShadow(
                                                      color: themeProvider
                                                              .isDarkMode
                                                          ? Colors.black38
                                                          : Colors.grey
                                                              .withOpacity(0.2),
                                                      spreadRadius: 1,
                                                      blurRadius: 4,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: value != 0
                                                ? AnimatedDefaultTextStyle(
                                                    duration: const Duration(
                                                        milliseconds: 150),
                                                    style: TextStyle(
                                                      fontSize: value < 100
                                                          ? 28
                                                          : value < 1000
                                                              ? 24
                                                              : 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: _getTextColor(
                                                          value,
                                                          themeProvider
                                                              .isDarkMode),
                                                    ),
                                                    child: Text('$value'),
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Control Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              gameModel.resetGame();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeProvider.isDarkMode
                                ? Colors.teal
                                : const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text(
                            'New Game',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
