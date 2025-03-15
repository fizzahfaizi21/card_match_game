import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameModel(),
      child: const CardMatchingApp(),
    ),
  );
}

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
              'assets/ghostcard.png',
              fit: BoxFit.cover,
            ),
            backWidget: card.isMatched
                ? Container(
                    color: Colors.white,
                    child: Image.asset(
                      'assets/${card.imageAsset}',
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    'assets/${card.imageAsset}',
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
