import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

CatAgeModel catAgeModel = CatAgeModel();

MyProvider providerCatAge = MyProvider(
  name: "CatAge",
  provideActions: _provideActions,
  initActions: _initActions,
  update: _update,
);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Cat Age Calculator',
      keywords: 'cat age pet kitten feline human years convert',
      action: () {
        Global.infoModel.addInfo("CatAge", "Cat Age Calculator",
            subtitle: "Convert cat age to human years",
            icon: Icon(Icons.pets),
            onTap: () => catAgeModel.requestFocus());
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  Global.infoModel.addInfoWidget(
    "CatAge",
    ChangeNotifierProvider.value(
      value: catAgeModel,
      builder: (context, child) => CatAgeCard(),
    ),
    title: "Cat Age Calculator",
  );
}

Future<void> _update() async {
  catAgeModel.refresh();
}

class CatAgeModel extends ChangeNotifier {
  double _catYears = 0;
  bool _focusInput = false;

  double get catYears => _catYears;
  bool get shouldFocus => _focusInput;
  bool get hasValue => _catYears > 0;

  void refresh() {
    notifyListeners();
  }

  double calculateHumanYears(double catYears) {
    if (catYears <= 0) return 0;
    if (catYears < 1) return catYears * 15;
    if (catYears < 2) return 15 + (catYears - 1) * 10;
    return 15 + 10 + (catYears - 2) * 4;
  }

  String getHumanAgeDescription(double humanYears) {
    if (humanYears <= 0) return "Newborn";
    if (humanYears < 3) return "Infant";
    if (humanYears < 13) return "Child";
    if (humanYears < 20) return "Teenager";
    if (humanYears < 40) return "Young Adult";
    if (humanYears < 60) return "Adult";
    if (humanYears < 75) return "Middle-aged";
    return "Senior";
  }

  String getLifeStage(double catYears) {
    if (catYears <= 0) return "Newborn";
    if (catYears < 1) return "Kitten";
    if (catYears < 2) return "Junior";
    if (catYears < 7) return "Adult";
    if (catYears < 11) return "Mature";
    if (catYears < 15) return "Senior";
    return "Geriatric";
  }

  void setCatYears(double years) {
    _catYears = years;
    Global.loggerModel.info("Cat age set: $years years", source: "CatAge");
    notifyListeners();
  }

  void clear() {
    _catYears = 0;
    Global.loggerModel.info("Cat age cleared", source: "CatAge");
    notifyListeners();
  }

  void requestFocus() {
    _focusInput = true;
    notifyListeners();
    Future.delayed(Duration(milliseconds: 100), () {
      _focusInput = false;
      notifyListeners();
    });
  }
}

class CatAgeCard extends StatefulWidget {
  @override
  State<CatAgeCard> createState() => _CatAgeCardState();
}

class _CatAgeCardState extends State<CatAgeCard> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final model = context.read<CatAgeModel>();
    if (model.catYears > 0) {
      _controller.text = model.catYears.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateAge(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed >= 0) {
      context.read<CatAgeModel>().setCatYears(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<CatAgeModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (model.shouldFocus && !_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_focusNode.canRequestFocus) {
          _focusNode.requestFocus();
        }
      });
    }

    final humanYears = model.calculateHumanYears(model.catYears);

    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.pets, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Cat Age Calculator",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (model.hasValue)
                  IconButton(
                    icon: Icon(Icons.clear, size: 18),
                    onPressed: () {
                      model.clear();
                      _controller.clear();
                    },
                    tooltip: "Clear",
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                labelText: "Cat's Age (years)",
                hintText: "Enter cat's age in years",
                prefixIcon: Icon(Icons.pets, size: 18),
                suffixText: "years",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: _updateAge,
            ),
            if (model.hasValue) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person, size: 24, color: colorScheme.primary),
                        SizedBox(width: 8),
                        Text(
                          "~${humanYears.round()}",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "human years",
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      model.getHumanAgeDescription(humanYears),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoItem(context, "Cat Age", "${model.catYears} years"),
                  _buildInfoItem(context, "Cat Stage", model.getLifeStage(model.catYears)),
                ],
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Conversion Formula",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "1st year = 15 human years\n"
                      "2nd year = +10 human years\n"
                      "Each year after = +4 human years",
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}