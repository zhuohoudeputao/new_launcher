import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

FlashcardModel flashcardModel = FlashcardModel();

MyProvider providerFlashcard = MyProvider(
    name: "Flashcard",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Study flashcards',
      keywords: 'flashcard flash cards study learn memorize quiz deck review',
      action: () {
        Global.infoModel.addInfo("AddFlashcard", "Add Flashcard Deck",
            subtitle: "Tap to create a new flashcard deck",
            icon: Icon(Icons.school),
            onTap: () => _showAddDeckDialog(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await flashcardModel.init();
  Global.infoModel.addInfoWidget(
      "Flashcard",
      ChangeNotifierProvider.value(
          value: flashcardModel,
          builder: (context, child) => FlashcardCard()),
      title: "Flashcard Study");
}

Future<void> _update() async {
  await flashcardModel.refresh();
}

void _showAddDeckDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AddDeckDialog(),
  );
}

void _showEditDeckDialog(BuildContext context, int index, FlashcardDeck deck) {
  showDialog(
    context: context,
    builder: (context) => EditDeckDialog(index: index, deck: deck),
  );
}

void _showAddCardDialog(BuildContext context, int deckIndex) {
  showDialog(
    context: context,
    builder: (context) => AddCardDialog(deckIndex: deckIndex),
  );
}

void _showStudyDialog(BuildContext context, int deckIndex, FlashcardDeck deck) {
  showDialog(
    context: context,
    builder: (context) => StudyDialog(deckIndex: deckIndex, deck: deck),
  );
}

class FlashcardDeck {
  final String name;
  final List<FlashcardItem> cards;
  final DateTime createdAt;
  final int correctCount;
  final int incorrectCount;

  FlashcardDeck({
    required this.name,
    List<FlashcardItem>? cards,
    DateTime? createdAt,
    this.correctCount = 0,
    this.incorrectCount = 0,
  })  : cards = cards ?? [],
        createdAt = createdAt ?? DateTime.now();

  int get totalCards => cards.length;
  int get studiedCards => correctCount + incorrectCount;
  double get accuracy {
    if (studiedCards == 0) return 0;
    return correctCount / studiedCards * 100;
  }

  String toJson() {
    return jsonEncode({
      'name': name,
      'cards': cards.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
    });
  }

  static FlashcardDeck fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return FlashcardDeck(
      name: map['name'] as String,
      cards: (map['cards'] as List)
          .map((c) => FlashcardItem.fromJson(c as String))
          .toList(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      correctCount: map['correctCount'] as int? ?? 0,
      incorrectCount: map['incorrectCount'] as int? ?? 0,
    );
  }

  FlashcardDeck copyWith({
    String? name,
    List<FlashcardItem>? cards,
    DateTime? createdAt,
    int? correctCount,
    int? incorrectCount,
  }) {
    return FlashcardDeck(
      name: name ?? this.name,
      cards: cards ?? this.cards,
      createdAt: createdAt ?? this.createdAt,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
    );
  }
}

class FlashcardItem {
  final String front;
  final String back;
  final DateTime createdAt;

  FlashcardItem({
    required this.front,
    required this.back,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String toJson() {
    return jsonEncode({
      'front': front,
      'back': back,
      'createdAt': createdAt.toIso8601String(),
    });
  }

  static FlashcardItem fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return FlashcardItem(
      front: map['front'] as String,
      back: map['back'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  FlashcardItem copyWith({
    String? front,
    String? back,
    DateTime? createdAt,
  }) {
    return FlashcardItem(
      front: front ?? this.front,
      back: back ?? this.back,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class FlashcardModel extends ChangeNotifier {
  static const int maxDecks = 10;
  static const int maxCardsPerDeck = 50;
  static const String _storageKey = 'flashcard_decks';

  List<FlashcardDeck> _decks = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<FlashcardDeck> get decks => _decks;
  int get totalDecks => _decks.length;
  int get totalCards => _decks.fold(0, (sum, d) => sum + d.totalCards);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final deckStrings = prefs.getStringList(_storageKey) ?? [];
    _decks = deckStrings.map((s) => FlashcardDeck.fromJson(s)).toList();
    _isInitialized = true;
    Global.loggerModel
        .info("Flashcard initialized with ${_decks.length} decks", source: "Flashcard");
    notifyListeners();
  }

  Future<void> refresh() async {
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final deckStrings = _decks.map((d) => d.toJson()).toList();
    await prefs.setStringList(_storageKey, deckStrings);
  }

  void addDeck(String name) {
    if (_decks.length >= maxDecks) {
      _decks.removeAt(0);
    }
    _decks.add(FlashcardDeck(name: name));
    Global.loggerModel.info("Added deck: $name", source: "Flashcard");
    _save();
    notifyListeners();
  }

  void updateDeck(int index, String name) {
    if (index >= 0 && index < _decks.length) {
      _decks[index] = _decks[index].copyWith(name: name);
      Global.loggerModel.info("Updated deck at index $index", source: "Flashcard");
      _save();
      notifyListeners();
    }
  }

  void deleteDeck(int index) {
    if (index >= 0 && index < _decks.length) {
      final name = _decks[index].name;
      _decks.removeAt(index);
      Global.loggerModel.info("Deleted deck: $name", source: "Flashcard");
      _save();
      notifyListeners();
    }
  }

  void addCard(int deckIndex, String front, String back) {
    if (deckIndex >= 0 && deckIndex < _decks.length) {
      final deck = _decks[deckIndex];
      if (deck.cards.length >= maxCardsPerDeck) {
        deck.cards.removeAt(0);
      }
      final newCards = List<FlashcardItem>.from(deck.cards);
      newCards.add(FlashcardItem(front: front, back: back));
      _decks[deckIndex] = deck.copyWith(cards: newCards);
      Global.loggerModel.info("Added card to deck ${deck.name}", source: "Flashcard");
      _save();
      notifyListeners();
    }
  }

  void deleteCard(int deckIndex, int cardIndex) {
    if (deckIndex >= 0 && deckIndex < _decks.length) {
      final deck = _decks[deckIndex];
      if (cardIndex >= 0 && cardIndex < deck.cards.length) {
        final newCards = List<FlashcardItem>.from(deck.cards);
        newCards.removeAt(cardIndex);
        _decks[deckIndex] = deck.copyWith(cards: newCards);
        Global.loggerModel.info("Deleted card from deck ${deck.name}", source: "Flashcard");
        _save();
        notifyListeners();
      }
    }
  }

  void recordStudyResult(int deckIndex, bool isCorrect) {
    if (deckIndex >= 0 && deckIndex < _decks.length) {
      final deck = _decks[deckIndex];
      _decks[deckIndex] = deck.copyWith(
        correctCount: deck.correctCount + (isCorrect ? 1 : 0),
        incorrectCount: deck.incorrectCount + (isCorrect ? 0 : 1),
      );
      Global.loggerModel.info(
          "Recorded study result for deck ${deck.name}: ${isCorrect ? 'correct' : 'incorrect'}",
          source: "Flashcard");
      _save();
      notifyListeners();
    }
  }

  Future<void> clearAllDecks() async {
    _decks.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    Global.loggerModel.info("Cleared all decks", source: "Flashcard");
    notifyListeners();
  }
}

class FlashcardCard extends StatefulWidget {
  @override
  State<FlashcardCard> createState() => _FlashcardCardState();
}

class _FlashcardCardState extends State<FlashcardCard> {
  @override
  Widget build(BuildContext context) {
    final flashcard = context.watch<FlashcardModel>();

    if (!flashcard.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.school, size: 24),
              SizedBox(width: 12),
              Text("Flashcard Study: Loading..."),
            ],
          ),
        ),
      );
    }

    return Card.filled(
      color: Theme.of(context).cardColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Flashcard Study",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  if (flashcard.totalDecks > 0)
                    Text(
                      "${flashcard.totalDecks} decks, ${flashcard.totalCards} cards",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              if (flashcard.decks.isEmpty)
                Text(
                  "No decks. Tap + to create one!",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ...flashcard.decks.asMap().entries.map((entry) {
                final index = entry.key;
                final deck = entry.value;
                return _buildDeckItem(context, flashcard, index, deck);
              }),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.add, size: 18),
                    onPressed: () => _showAddDeckDialog(context),
                    tooltip: "Add deck",
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (flashcard.decks.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.delete_sweep, size: 18),
                      onPressed: () => _showClearConfirmDialog(context, flashcard),
                      tooltip: "Clear all decks",
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeckItem(
      BuildContext context, FlashcardModel flashcard, int index, FlashcardDeck deck) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showStudyDialog(context, index, deck),
                onLongPress: () => _showEditDeckDialog(context, index, deck),
                child: Row(
                  children: [
                    Icon(Icons.folder, size: 20, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        deck.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (deck.studiedCards > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "${deck.accuracy.toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    "${deck.totalCards} cards",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.play_arrow, size: 16),
                    onPressed: deck.totalCards > 0
                        ? () => _showStudyDialog(context, index, deck)
                        : null,
                    tooltip: "Study",
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      minimumSize: Size(32, 32),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_card, size: 16),
                    onPressed: () => _showAddCardDialog(context, index),
                    tooltip: "Add card",
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                      minimumSize: Size(32, 32),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearConfirmDialog(BuildContext context, FlashcardModel flashcard) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear all decks?"),
        content: Text("This will delete all ${flashcard.totalDecks} decks and ${flashcard.totalCards} cards permanently."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              flashcard.clearAllDecks();
              Navigator.pop(context);
            },
            child: Text("Clear"),
          ),
        ],
      ),
    );
  }
}

class AddDeckDialog extends StatefulWidget {
  @override
  State<AddDeckDialog> createState() => _AddDeckDialogState();
}

class _AddDeckDialogState extends State<AddDeckDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Deck"),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: "e.g., Vocabulary, Math Formulas",
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              flashcardModel.addDeck(_controller.text.trim());
              Navigator.pop(context);
            }
          },
          child: Text("Add"),
        ),
      ],
    );
  }
}

class EditDeckDialog extends StatefulWidget {
  final int index;
  final FlashcardDeck deck;

  const EditDeckDialog({required this.index, required this.deck});

  @override
  State<EditDeckDialog> createState() => _EditDeckDialogState();
}

class _EditDeckDialogState extends State<EditDeckDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.deck.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Deck"),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: "Deck name",
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            flashcardModel.deleteDeck(widget.index);
            Navigator.pop(context);
          },
          child: Text("Delete"),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              flashcardModel.updateDeck(widget.index, _controller.text.trim());
              Navigator.pop(context);
            }
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}

class AddCardDialog extends StatefulWidget {
  final int deckIndex;

  const AddCardDialog({required this.deckIndex});

  @override
  State<AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<AddCardDialog> {
  final TextEditingController _frontController = TextEditingController();
  final TextEditingController _backController = TextEditingController();

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Card"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _frontController,
            decoration: InputDecoration(
              labelText: "Front (Question)",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          SizedBox(height: 12),
          TextField(
            controller: _backController,
            decoration: InputDecoration(
              labelText: "Back (Answer)",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            if (_frontController.text.trim().isNotEmpty &&
                _backController.text.trim().isNotEmpty) {
              flashcardModel.addCard(
                widget.deckIndex,
                _frontController.text.trim(),
                _backController.text.trim(),
              );
              Navigator.pop(context);
            }
          },
          child: Text("Add"),
        ),
      ],
    );
  }
}

class StudyDialog extends StatefulWidget {
  final int deckIndex;
  final FlashcardDeck deck;

  const StudyDialog({required this.deckIndex, required this.deck});

  @override
  State<StudyDialog> createState() => _StudyDialogState();
}

class _StudyDialogState extends State<StudyDialog> {
  int _currentIndex = 0;
  bool _showBack = false;
  late List<FlashcardItem> _cards;

  @override
  void initState() {
    super.initState();
    _cards = widget.deck.cards;
  }

  void _flipCard() {
    setState(() {
      _showBack = !_showBack;
    });
  }

  void _nextCard(bool isCorrect) {
    flashcardModel.recordStudyResult(widget.deckIndex, isCorrect);
    setState(() {
      _showBack = false;
      if (_currentIndex < _cards.length - 1) {
        _currentIndex++;
      }
    });
  }

  void _previousCard() {
    setState(() {
      _showBack = false;
      if (_currentIndex > 0) {
        _currentIndex--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return AlertDialog(
        title: Text("Empty Deck"),
        content: Text("Add some cards to this deck first."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      );
    }

    final card = _cards[_currentIndex];

    return AlertDialog(
      title: Row(
        children: [
          Text(widget.deck.name),
          Spacer(),
          Text(
            "${_currentIndex + 1}/${_cards.length}",
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      content: GestureDetector(
        onTap: _flipCard,
        child: Container(
          width: double.maxFinite,
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _showBack ? "Answer" : "Question",
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: 16),
              Text(
                _showBack ? card.back : card.front,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                "Tap to flip",
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: _currentIndex > 0 ? _previousCard : null,
              tooltip: "Previous",
            ),
            if (_showBack)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Theme.of(context).colorScheme.error),
                    onPressed: () => _nextCard(false),
                    tooltip: "Incorrect",
                  ),
                  IconButton(
                    icon: Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
                    onPressed: () => _nextCard(true),
                    tooltip: "Correct",
                  ),
                ],
              ),
            IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: _currentIndex < _cards.length - 1
                  ? () {
                      setState(() {
                        _showBack = false;
                        _currentIndex++;
                      });
                    }
                  : null,
              tooltip: "Next",
            ),
          ],
        ),
      ],
    );
  }
}