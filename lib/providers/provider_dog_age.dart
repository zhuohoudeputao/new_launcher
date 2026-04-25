import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

DogAgeModel dogAgeModel = DogAgeModel();

MyProvider providerDogAge = MyProvider(
  name: "DogAge",
  provideActions: _provideActions,
  initActions: _initActions,
  update: _update,
);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Dog Age Calculator',
      keywords: 'dog age pet puppy canine human years convert',
      action: () {
        Global.infoModel.addInfo("DogAge", "Dog Age Calculator",
            subtitle: "Convert dog age to human years",
            icon: Icon(Icons.pets),
            onTap: () => dogAgeModel.requestFocus());
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  Global.infoModel.addInfoWidget(
    "DogAge",
    ChangeNotifierProvider.value(
      value: dogAgeModel,
      builder: (context, child) => DogAgeCard(),
    ),
    title: "Dog Age Calculator",
  );
}

Future<void> _update() async {
  dogAgeModel.refresh();
}

class DogAgeModel extends ChangeNotifier {
  double _dogYears = 0;
  bool _focusInput = false;

  double get dogYears => _dogYears;
  bool get shouldFocus => _focusInput;
  bool get hasValue => _dogYears > 0;

  void refresh() {
    notifyListeners();
  }

  double calculateHumanYears(double dogYears) {
    if (dogYears <= 0) return 0;
    if (dogYears < 1) return dogYears * 15;
    if (dogYears < 2) return 15 + (dogYears - 1) * 9;
    return 15 + 9 + (dogYears - 2) * 4;
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

  String getLifeStage(double dogYears) {
    if (dogYears <= 0) return "Newborn";
    if (dogYears < 0.5) return "Puppy";
    if (dogYears < 1) return "Young Puppy";
    if (dogYears < 3) return "Young Adult";
    if (dogYears < 7) return "Adult";
    if (dogYears < 10) return "Senior";
    return "Geriatric";
  }

  void setDogYears(double years) {
    _dogYears = years;
    Global.loggerModel.info("Dog age set: $years years", source: "DogAge");
    notifyListeners();
  }

  void clear() {
    _dogYears = 0;
    Global.loggerModel.info("Dog age cleared", source: "DogAge");
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

class DogAgeCard extends StatefulWidget {
  @override
  State<DogAgeCard> createState() => _DogAgeCardState();
}

class _DogAgeCardState extends State<DogAgeCard> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final model = context.read<DogAgeModel>();
    if (model.dogYears > 0) {
      _controller.text = model.dogYears.toString();
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
      context.read<DogAgeModel>().setDogYears(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<DogAgeModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (model.shouldFocus && !_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_focusNode.canRequestFocus) {
          _focusNode.requestFocus();
        }
      });
    }

    final humanYears = model.calculateHumanYears(model.dogYears);

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
                      "Dog Age Calculator",
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
                labelText: "Dog's Age (years)",
                hintText: "Enter dog's age in years",
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
                  _buildInfoItem(context, "Dog Age", "${model.dogYears} years"),
                  _buildInfoItem(context, "Dog Stage", model.getLifeStage(model.dogYears)),
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
                      "2nd year = +9 human years\n"
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