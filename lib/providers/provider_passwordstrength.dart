import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

PasswordStrengthModel passwordStrengthModel = PasswordStrengthModel();

MyProvider providerPasswordStrength = MyProvider(
    name: "PasswordStrength",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Check Password',
      keywords: 'password strength check security weak strong',
      action: () {
        Global.infoModel.addInfo(
            "PasswordStrength",
            "Password Strength",
            subtitle: "Check password security",
            icon: Icon(Icons.security),
            onTap: () {});
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  passwordStrengthModel.init();
  Global.infoModel.addInfoWidget(
      "PasswordStrength",
      ChangeNotifierProvider.value(
          value: passwordStrengthModel,
          builder: (context, child) => PasswordStrengthCard()),
      title: "Password Strength");
}

Future<void> _update() async {
  passwordStrengthModel.refresh();
}

class PasswordStrengthModel extends ChangeNotifier {
  bool _isInitialized = false;
  String _password = "";
  String _strengthLevel = "";
  int _strengthScore = 0;
  String _strengthLabel = "";
  Color _strengthColor = Colors.grey;
  String _feedback = "";
  List<String> _history = [];
  static const int _maxHistoryLength = 10;

  bool get isInitialized => _isInitialized;
  String get password => _password;
  String get strengthLevel => _strengthLevel;
  int get strengthScore => _strengthScore;
  String get strengthLabel => _strengthLabel;
  Color get strengthColor => _strengthColor;
  String get feedback => _feedback;
  List<String> get history => _history;

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("PasswordStrength initialized", source: "PasswordStrength");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void checkPassword(String password) {
    _password = password;
    _analyzePassword(password);
    if (password.isNotEmpty) {
      addToHistory(password);
    }
    notifyListeners();
    Global.loggerModel.info("Password analyzed: score $strengthScore", source: "PasswordStrength");
  }

  void addToHistory(String password) {
    if (password.isEmpty) return;
    _history.remove(password);
    _history.insert(0, password);
    if (_history.length > _maxHistoryLength) {
      _history.removeRange(_maxHistoryLength, _history.length);
    }
  }

  void removeFromHistory(String password) {
    _history.remove(password);
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
    Global.loggerModel.info("Password history cleared", source: "PasswordStrength");
  }

  void clearPassword() {
    _password = "";
    _strengthLevel = "";
    _strengthScore = 0;
    _strengthLabel = "";
    _strengthColor = Colors.grey;
    _feedback = "";
    notifyListeners();
  }

  void _analyzePassword(String password) {
    if (password.isEmpty) {
      _strengthLevel = "";
      _strengthScore = 0;
      _strengthLabel = "";
      _strengthColor = Colors.grey;
      _feedback = "";
      return;
    }

    int score = 0;
    List<String> feedbackList = [];

    int length = password.length;

    if (length < 6) {
      score += length * 2;
      feedbackList.add("Too short (min 8 chars recommended)");
    } else if (length < 8) {
      score += 12 + (length - 6) * 4;
      feedbackList.add("Short password");
    } else if (length < 12) {
      score += 24 + (length - 8) * 4;
    } else if (length < 16) {
      score += 40 + (length - 12) * 3;
    } else {
      score += 52 + min(length - 16, 20);
    }

    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    bool hasSymbol = password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"|,.<>?]'));
    bool hasSpace = password.contains(RegExp(r'\s'));

    int charTypeCount = [hasLower, hasUpper, hasNumber, hasSymbol, hasSpace].where((e) => e).length;

    score += charTypeCount * 8;

    if (!hasLower) feedbackList.add("Add lowercase letters");
    if (!hasUpper) feedbackList.add("Add uppercase letters");
    if (!hasNumber) feedbackList.add("Add numbers");
    if (!hasSymbol) feedbackList.add("Add special characters");

    if (hasSpace) {
      score += 5;
    }

    if (_hasRepeatedChars(password)) {
      score -= 10;
      feedbackList.add("Avoid repeated characters");
    }

    if (_hasSequentialChars(password)) {
      score -= 10;
      feedbackList.add("Avoid sequential characters");
    }

    if (_hasCommonPatterns(password)) {
      score -= 15;
      feedbackList.add("Avoid common patterns (123, abc, password)");
    }

    score = score.clamp(0, 100);

    _strengthScore = score;
    _feedback = feedbackList.isEmpty ? "Good password!" : feedbackList.join("; ");

    if (score < 20) {
      _strengthLevel = "Very Weak";
      _strengthLabel = "Very Weak";
      _strengthColor = Colors.red;
    } else if (score < 40) {
      _strengthLevel = "Weak";
      _strengthLabel = "Weak";
      _strengthColor = Colors.orange;
    } else if (score < 60) {
      _strengthLevel = "Medium";
      _strengthLabel = "Medium";
      _strengthColor = Colors.yellow.shade700;
    } else if (score < 80) {
      _strengthLevel = "Strong";
      _strengthLabel = "Strong";
      _strengthColor = Colors.lightGreen;
    } else {
      _strengthLevel = "Very Strong";
      _strengthLabel = "Very Strong";
      _strengthColor = Colors.green;
    }
  }

  bool _hasRepeatedChars(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      if (password[i] == password[i + 1] && password[i + 1] == password[i + 2]) {
        return true;
      }
    }
    return false;
  }

  bool _hasSequentialChars(String password) {
    const sequences = [
      'abc', 'bcd', 'cde', 'def', 'efg', 'fgh', 'ghi', 'hij', 'ijk', 'jkl', 'klm', 'lmn', 'mno', 'nop', 'opq', 'pqr', 'qrs', 'rst', 'stu', 'tuv', 'uvw', 'vwx', 'wxy', 'xyz',
      '012', '123', '234', '345', '456', '567', '678', '789', '890',
      'qwe', 'wer', 'ert', 'rty', 'tyu', 'yui', 'uio', 'iop',
      'asd', 'sdf', 'dfg', 'fgh', 'ghj', 'hjk', 'jkl',
    ];

    final lower = password.toLowerCase();
    for (final seq in sequences) {
      if (lower.contains(seq) || lower.contains(seq.split('').reversed.join())) {
        return true;
      }
    }
    return false;
  }

  bool _hasCommonPatterns(String password) {
    final commonPatterns = [
      'password', 'passwd', 'pass', '123456', '12345678', 'qwerty', 'admin', 'login', 'welcome', 'monkey', 'dragon', 'master', 'letmein', 'abc123', '111111', 'password1', 'iloveyou', 'trustno1', 'sunshine', 'princess', 'football', 'baseball', 'soccer', 'hockey', 'batman', 'superman'
    ];

    final lower = password.toLowerCase();
    for (final pattern in commonPatterns) {
      if (lower.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  void copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class PasswordStrengthCard extends StatefulWidget {
  @override
  State<PasswordStrengthCard> createState() => _PasswordStrengthCardState();
}

class _PasswordStrengthCardState extends State<PasswordStrengthCard> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<PasswordStrengthModel>();

    if (!model.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.security, size: 24),
              SizedBox(width: 12),
              Text("Password Strength: Loading..."),
            ],
          ),
        ),
      );
    }

    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, size: 20),
                SizedBox(width: 8),
                Text(
                  "Password Strength Checker",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildPasswordInput(context, model),
            if (model.password.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildStrengthIndicator(context, model),
              SizedBox(height: 8),
              _buildStrengthDetails(context, model),
            ],
            SizedBox(height: 12),
            _buildHistorySection(context, model),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordInput(BuildContext context, PasswordStrengthModel model) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.password, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text("Enter Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      hintText: "Type password to check...",
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off, size: 18),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                            tooltip: _obscureText ? "Show password" : "Hide password",
                            style: IconButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    style: TextStyle(fontSize: 12),
                    onChanged: (value) {
                      model.checkPassword(value);
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _passwordController.clear();
                    model.clearPassword();
                  },
                  tooltip: "Clear password",
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthIndicator(BuildContext context, PasswordStrengthModel model) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, size: 20, color: model.strengthColor),
                SizedBox(width: 8),
                Text(
                  model.strengthLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: model.strengthColor,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  "${model.strengthScore}%",
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: model.strengthScore / 100,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(model.strengthColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthDetails(BuildContext context, PasswordStrengthModel model) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    model.feedback,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, PasswordStrengthModel model) {
    if (model.history.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text("History", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.delete_sweep, size: 16),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Clear History"),
                        content: Text("Clear all password history?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              model.clearHistory();
                              Navigator.pop(context);
                            },
                            child: Text("Clear"),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: "Clear history",
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 80),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: model.history.length,
                itemBuilder: (context, index) {
                  final password = model.history[index];
                  final obscured = password.length > 4 
                      ? '${password.substring(0, 2)}...${password.substring(password.length - 2)}'
                      : password;
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text(
                      obscured,
                      style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                    subtitle: Text(
                      "${password.length} chars",
                      style: TextStyle(fontSize: 10),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.copy, size: 14),
                          onPressed: () => model.copyToClipboard(password, context),
                          tooltip: "Copy",
                          style: IconButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, size: 14),
                          onPressed: () => model.removeFromHistory(password),
                          tooltip: "Remove",
                          style: IconButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _passwordController.text = password;
                      model.checkPassword(password);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}