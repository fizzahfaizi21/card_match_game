import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:provider/provider.dart';

// Global navigator key for accessing context from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameModel(),
      child: const CardMatchingApp(),
    ),
  );
}

class CardMatchingApp extends StatelessWidget {
  const CardMatchingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Matching Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      navigatorKey: navigatorKey,
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Game model class for state management
class GameModel extends ChangeNotifier {
  final List<String> cardImages = [
    'birdie.jpg',
    'kitty.jpg',
    'doggy.jpg',
    'birdie.jpg',
    'kitty.jpg',
    'doggy.jpg',
  ];

  late List<Card> cards;
  int? firstCardIndex;
  int? secondCardIndex;
  bool canFlip = true;
  int matchedPairs = 0;
  int totalPairs = 3; // We have 3 pairs of cards
  bool gameWon = false;
  int score = 0;

  // Timer properties
  Timer? timer;
  int secondsElapsed = 0;
  bool timerRunning = false;

  GameModel() {
    initGame();
  }

  void initGame() {
    // Reset game state
    firstCardIndex = null;
    secondCardIndex = null;
    canFlip = true;
    matchedPairs = 0;
    gameWon = false;
    score = 0;
    secondsElapsed = 0;
    timerRunning = false;
    if (timer != null) {
      timer!.cancel();
      timer = null;
    }

    // Shuffle cards
    List<String> shuffledImages = List.from(cardImages);
    shuffledImages.shuffle();

    // Create card objects
    cards = List.generate(
      shuffledImages.length,
      (index) => Card(
        id: index,
        imageAsset: shuffledImages[index],
        isFlipped: false,
        isMatched: false,
      ),
    );

    notifyListeners();
  }

  void startTimer() {
    if (!timerRunning) {
      timerRunning = true;
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        secondsElapsed++;
        notifyListeners();
      });
    }
  }

  void stopTimer() {
    timerRunning = false;
    timer?.cancel();
    timer = null;
  }

  void flipCard(int index) {
    if (!canFlip || cards[index].isFlipped || cards[index].isMatched) return;

    // Start timer on first card flip
    if (!timerRunning) {
      startTimer();
    }

    if (firstCardIndex == null) {
      // First card flipped
      firstCardIndex = index;
      cards[index].isFlipped = true;
      notifyListeners();
    } else if (secondCardIndex == null && index != firstCardIndex) {
      // Second card flipped
      secondCardIndex = index;
      cards[index].isFlipped = true;
      canFlip = false;
      notifyListeners();

      // Check for a match
      checkForMatch();
    }
  }

  void checkForMatch() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (cards[firstCardIndex!].imageAsset ==
          cards[secondCardIndex!].imageAsset) {
        // Match found
        cards[firstCardIndex!].isMatched = true;
        cards[secondCardIndex!].isMatched = true;
        matchedPairs++;
        score += 10; // Add points for match

        // Check for win
        if (matchedPairs == totalPairs) {
          gameWon = true;
          stopTimer();

          // Show victory dialog when all pairs are matched
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final context = navigatorKey.currentContext;
            if (context != null) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => VictoryDialog(
                  score: score,
                  timeElapsed: secondsElapsed,
                ),
              );
            }
          });
        }
      } else {
        // No match
        cards[firstCardIndex!].isFlipped = false;
        cards[secondCardIndex!].isFlipped = false;
        score = score > 2 ? score - 2 : 0; // Deduct points for mismatch
      }

      // Reset selected cards
      firstCardIndex = null;
      secondCardIndex = null;
      canFlip = true;
      notifyListeners();
    });
  }
}

// Card data model
class Card {
  final int id;
  final String imageAsset;
  bool isFlipped;
  bool isMatched;

  Card({
    required this.id,
    required this.imageAsset,
    required this.isFlipped,
    required this.isMatched,
  });
}

// Game screen that displays the card grid and game info
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameModel = Provider.of<GameModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Matching Game'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Game info panel
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Timer display
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer),
                      const SizedBox(width: 8),
                      Text(
                        'Time: ${gameModel.secondsElapsed}s',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Score display
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star),
                      const SizedBox(width: 8),
                      Text(
                        'Score: ${gameModel.score}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Card grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                  childAspectRatio: 0.7,
                ),
                itemCount: gameModel.cards.length,
                itemBuilder: (context, index) {
                  return CardWidget(index: index);
                },
              ),
            ),
          ),

          // Restart button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                gameModel.initGame();
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Restart Game',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Animated card widget
class CardWidget extends StatelessWidget {
  final int index;

  const CardWidget({
    super.key,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameModel>(
      builder: (context, gameModel, child) {
        final card = gameModel.cards[index];

        return GestureDetector(
          onTap: () {
            if (gameModel.gameWon) {
              // Show game won message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'You won! Final score: ${gameModel.score}, Time: ${gameModel.secondsElapsed}s',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              return;
            }
            gameModel.flipCard(index);
          },
          child: FlipCard(
            isFlipped: card.isFlipped,
            frontWidget: Image.asset(
              'lib/assets/ghostcard.png',
              fit: BoxFit.cover,
            ),
            backWidget: card.isMatched
                ? Container(
                    color: Colors.white,
                    child: Image.asset(
                      'lib/assets/${card.imageAsset}',
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    'lib/assets/${card.imageAsset}',
                    fit: BoxFit.cover,
                  ),
          ),
        );
      },
    );
  }
}

// Flip card animation widget
class FlipCard extends StatefulWidget {
  final bool isFlipped;
  final Widget frontWidget;
  final Widget backWidget;

  const FlipCard({
    super.key,
    required this.isFlipped,
    required this.frontWidget,
    required this.backWidget,
  });

  @override
  FlipCardState createState() => FlipCardState();
}

class FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _frontRotation;
  late Animation<double> _backRotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _frontRotation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: pi / 2)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(pi / 2),
        weight: 50,
      ),
    ]).animate(_controller);

    _backRotation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(pi / 2),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: pi / 2, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Front side (card back)
        AnimatedBuilder(
          animation: _frontRotation,
          builder: (context, child) {
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_frontRotation.value);
            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: widget.frontWidget,
            );
          },
        ),
        // Back side (card front)
        AnimatedBuilder(
          animation: _backRotation,
          builder: (context, child) {
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_backRotation.value);
            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: widget.isFlipped ? widget.backWidget : Container(),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Victory dialog that appears when all pairs are matched
class VictoryDialog extends StatelessWidget {
  final int score;
  final int timeElapsed;

  const VictoryDialog({
    super.key,
    required this.score,
    required this.timeElapsed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '🎉 Victory! 🎉',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Congratulations! You\'ve matched all pairs!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Time: $timeElapsed seconds',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'Final Score: $score points',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            // Reset the game
            final gameModel = Provider.of<GameModel>(context, listen: false);
            gameModel.initGame();
            Navigator.of(context).pop();
          },
          child: const Text('Play Again'),
        ),
      ],
    );
  }
}
