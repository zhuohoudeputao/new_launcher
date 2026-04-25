import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

MotivationalQuoteModel motivationalQuoteModel = MotivationalQuoteModel();

MyProvider providerMotivationalQuote = MyProvider(
    name: "MotivationalQuote",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Show quote',
      keywords: 'quote motivational inspiration inspire daily wisdom quote motivation',
      action: () {
        motivationalQuoteModel.getRandomQuote();
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await motivationalQuoteModel.init();
  Global.infoModel.addInfoWidget(
      "MotivationalQuote",
      ChangeNotifierProvider.value(
          value: motivationalQuoteModel,
          builder: (context, child) => MotivationalQuoteCard()),
      title: "Motivational Quote");
}

Future<void> _update() async {
  await motivationalQuoteModel.refresh();
}

class Quote {
  final String text;
  final String author;

  Quote({required this.text, required this.author});

  String get fullText => '"$text" - $author';
}

class MotivationalQuoteModel extends ChangeNotifier {
  static const String _lastQuoteDateKey = 'motivational_quote_last_date';
  static const String _lastQuoteIndexKey = 'motivational_quote_last_index';
  static const String _favoritesKey = 'motivational_quote_favorites';
  
  static final List<Quote> _quotes = [
    Quote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs"),
    Quote(text: "In the middle of difficulty lies opportunity.", author: "Albert Einstein"),
    Quote(text: "Success is not final, failure is not fatal: it is the courage to continue that counts.", author: "Winston Churchill"),
    Quote(text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt"),
    Quote(text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt"),
    Quote(text: "It does not matter how slowly you go as long as you do not stop.", author: "Confucius"),
    Quote(text: "Everything you've ever wanted is on the other side of fear.", author: "George Addair"),
    Quote(text: "The best time to plant a tree was 20 years ago. The second best time is now.", author: "Chinese Proverb"),
    Quote(text: "Your time is limited, don't waste it living someone else's life.", author: "Steve Jobs"),
    Quote(text: "Strive not to be a success, but rather to be of value.", author: "Albert Einstein"),
    Quote(text: "The only impossible journey is the one you never begin.", author: "Tony Robbins"),
    Quote(text: "What lies behind us and what lies before us are tiny matters compared to what lies within us.", author: "Ralph Waldo Emerson"),
    Quote(text: "You miss 100% of the shots you don't take.", author: "Wayne Gretzky"),
    Quote(text: "Whether you think you can or you think you can't, you're right.", author: "Henry Ford"),
    Quote(text: "I have not failed. I've just found 10,000 ways that won't work.", author: "Thomas Edison"),
    Quote(text: "The secret of getting ahead is getting started.", author: "Mark Twain"),
    Quote(text: "Don't watch the clock; do what it does. Keep going.", author: "Sam Levenson"),
    Quote(text: "Quality is not an act, it is a habit.", author: "Aristotle"),
    Quote(text: "The mind is everything. What you think you become.", author: "Buddha"),
    Quote(text: "Happiness is not something ready made. It comes from your own actions.", author: "Dalai Lama"),
    Quote(text: "Do what you can, with what you have, where you are.", author: "Theodore Roosevelt"),
    Quote(text: "Life is what happens when you're busy making other plans.", author: "John Lennon"),
    Quote(text: "The greatest glory in living lies not in never falling, but in rising every time we fall.", author: "Nelson Mandela"),
    Quote(text: "It is during our darkest moments that we must focus to see the light.", author: "Aristotle"),
    Quote(text: "Whoever is happy will make others happy too.", author: "Anne Frank"),
    Quote(text: "Spread love everywhere you go. Let no one ever come to you without leaving happier.", author: "Mother Teresa"),
    Quote(text: "When you reach the end of your rope, tie a knot in it and hang on.", author: "Franklin D. Roosevelt"),
    Quote(text: "Tell me and I forget. Teach me and I remember. Involve me and I learn.", author: "Benjamin Franklin"),
    Quote(text: "The best and most beautiful things in the world cannot be seen or even touched - they must be felt with the heart.", author: "Helen Keller"),
    Quote(text: "It is never too late to be what you might have been.", author: "George Eliot"),
    Quote(text: "You can't use up creativity. The more you use, the more you have.", author: "Maya Angelou"),
    Quote(text: "Imagination is more important than knowledge.", author: "Albert Einstein"),
    Quote(text: "Stay hungry, stay foolish.", author: "Steve Jobs"),
    Quote(text: "The only limit to our realization of tomorrow is our doubts of today.", author: "Franklin D. Roosevelt"),
    Quote(text: "Do not go where the path may lead, go instead where there is no path and leave a trail.", author: "Ralph Waldo Emerson"),
    Quote(text: "What you get by achieving your goals is not as important as what you become by achieving your goals.", author: "Zig Ziglar"),
    Quote(text: "Success usually comes to those who are too busy to be looking for it.", author: "Henry David Thoreau"),
    Quote(text: "Don't be afraid to give up the good to go for the great.", author: "John D. Rockefeller"),
    Quote(text: "If you look at what you have in life, you'll always have more.", author: "Oprah Winfrey"),
    Quote(text: "The way to get started is to quit talking and begin doing.", author: "Walt Disney"),
    Quote(text: "Life shrinks or expands in proportion with one's courage.", author: "Anais Nin"),
    Quote(text: "If you want to lift yourself up, lift up someone else.", author: " Booker T. Washington"),
    Quote(text: "We must accept finite disappointment, but never lose infinite hope.", author: "Martin Luther King Jr."),
    Quote(text: "Optimism is the faith that leads to achievement.", author: "Helen Keller"),
    Quote(text: "Yesterday I was clever, so I changed the world. Today I am wise, so I am changing myself.", author: "Rumi"),
    Quote(text: "Every great dream begins with a dreamer.", author: "Harriet Tubman"),
    Quote(text: "Success is walking from failure to failure with no loss of enthusiasm.", author: "Winston Churchill"),
    Quote(text: "What would life be if we had no courage to attempt anything?", author: "Vincent van Gogh"),
    Quote(text: "You are never too old to set another goal or to dream a new dream.", author: "C.S. Lewis"),
  ];

  int _currentQuoteIndex = 0;
  bool _isInitialized = false;
  List<int> _favorites = [];

  bool get isInitialized => _isInitialized;
  Quote get currentQuote => _quotes[_currentQuoteIndex];
  int get totalQuotes => _quotes.length;
  int get currentIndex => _currentQuoteIndex;
  List<int> get favorites => _favorites;
  bool get isFavorite => _favorites.contains(_currentQuoteIndex);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastQuoteDateKey);
    final today = _getTodayKey();
    
    if (lastDate == today) {
      _currentQuoteIndex = prefs.getInt(_lastQuoteIndexKey) ?? 0;
    } else {
      _currentQuoteIndex = DateTime.now().day % _quotes.length;
      await prefs.setString(_lastQuoteDateKey, today);
      await prefs.setInt(_lastQuoteIndexKey, _currentQuoteIndex);
    }
    
    _favorites = (prefs.getStringList(_favoritesKey) ?? []).map((s) => int.parse(s)).toList();
    _isInitialized = true;
    Global.loggerModel.info("MotivationalQuote initialized", source: "MotivationalQuote");
    notifyListeners();
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  Future<void> refresh() async {
    notifyListeners();
  }

  void getRandomQuote() {
    final newIndex = DateTime.now().millisecondsSinceEpoch % _quotes.length;
    if (newIndex != _currentQuoteIndex) {
      _currentQuoteIndex = newIndex;
      notifyListeners();
    }
  }

  void nextQuote() {
    _currentQuoteIndex = (_currentQuoteIndex + 1) % _quotes.length;
    notifyListeners();
  }

  void previousQuote() {
    _currentQuoteIndex = (_currentQuoteIndex - 1) % _quotes.length;
    notifyListeners();
  }

  Future<void> toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    if (_favorites.contains(_currentQuoteIndex)) {
      _favorites.remove(_currentQuoteIndex);
    } else {
      _favorites.add(_currentQuoteIndex);
    }
    await prefs.setStringList(_favoritesKey, _favorites.map((i) => i.toString()).toList());
    notifyListeners();
  }

  void copyQuote() {
    Clipboard.setData(ClipboardData(text: currentQuote.fullText));
  }

  void setQuoteIndex(int index) {
    if (index >= 0 && index < _quotes.length) {
      _currentQuoteIndex = index;
      notifyListeners();
    }
  }
}

class MotivationalQuoteCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final model = context.watch<MotivationalQuoteModel>();

    if (!model.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.format_quote, size: 24),
              SizedBox(width: 12),
              Text("Motivational Quote: Loading..."),
            ],
          ),
        ),
      );
    }

    final quote = model.currentQuote;

    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_quote, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  "Daily Inspiration",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Icon(
                  model.isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: model.isFavorite ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '"${quote.text}"',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "- ${quote.author}",
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: model.previousQuote,
                  tooltip: "Previous",
                ),
                IconButton(
                  icon: Icon(Icons.shuffle),
                  onPressed: model.getRandomQuote,
                  tooltip: "Random",
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: model.nextQuote,
                  tooltip: "Next",
                ),
                IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: model.copyQuote,
                  tooltip: "Copy",
                ),
              ],
            ),
            if (model.favorites.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.favorite, size: 14, color: Colors.red),
                    SizedBox(width: 4),
                    Text(
                      "${model.favorites.length} favorites",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}