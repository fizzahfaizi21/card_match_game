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
