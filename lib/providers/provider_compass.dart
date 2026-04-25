import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

CompassModel compassModel = CompassModel();

MyProvider providerCompass = MyProvider(
    name: "Compass",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Compass Direction',
      keywords: 'compass direction north south east west heading orientation navigate',
      action: () => compassModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  compassModel.init();
  Global.infoModel.addInfoWidget(
      "Compass",
      ChangeNotifierProvider.value(
          value: compassModel,
          child: const CompassCard()),
      title: "Compass");
}

Future<void> _update() async {
  compassModel.refresh();
}

class CompassModel extends ChangeNotifier {
  double _heading = 0.0;
  bool _initialized = false;
  Timer? _simulationTimer;

  static const Map<String, String> directionNames = {
    'N': 'North',
    'NE': 'North East',
    'E': 'East',
    'SE': 'South East',
    'S': 'South',
    'SW': 'South West',
    'W': 'West',
    'NW': 'North West',
  };

  double get heading => _heading;
  bool get initialized => _initialized;

  String get directionAbbreviation {
    if (_heading >= 337.5 || _heading < 22.5) return 'N';
    if (_heading >= 22.5 && _heading < 67.5) return 'NE';
    if (_heading >= 67.5 && _heading < 112.5) return 'E';
    if (_heading >= 112.5 && _heading < 157.5) return 'SE';
    if (_heading >= 157.5 && _heading < 202.5) return 'S';
    if (_heading >= 202.5 && _heading < 247.5) return 'SW';
    if (_heading >= 247.5 && _heading < 292.5) return 'W';
    if (_heading >= 292.5 && _heading < 337.5) return 'NW';
    return 'N';
  }

  String get directionName {
    return directionNames[directionAbbreviation] ?? 'North';
  }

  void init() {
    if (_initialized) return;
    _initialized = true;
    notifyListeners();
  }

  void setHeading(double heading) {
    while (heading < 0) heading += 360;
    while (heading >= 360) heading -= 360;
    _heading = heading;
    notifyListeners();
  }

  void adjustHeading(double delta) {
    setHeading(_heading + delta);
  }

  void setToNorth() {
    setHeading(0);
    Global.loggerModel.info('Compass set to North');
  }

  void setToEast() {
    setHeading(90);
    Global.loggerModel.info('Compass set to East');
  }

  void setToSouth() {
    setHeading(180);
    Global.loggerModel.info('Compass set to South');
  }

  void setToWest() {
    setHeading(270);
    Global.loggerModel.info('Compass set to West');
  }

  void refresh() {
    Global.loggerModel.info('Compass refreshed');
    notifyListeners();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}

class CompassCard extends StatelessWidget {
  const CompassCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CompassModel>(builder: (context, model, child) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.explore,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Compass',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (!model.initialized)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CustomPaint(
                        painter: CompassPainter(
                          heading: model.heading,
                          primaryColor: Theme.of(context).colorScheme.primary,
                          secondaryColor:
                              Theme.of(context).colorScheme.secondary,
                          textColor: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${model.heading.toStringAsFixed(1)}°',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${model.directionAbbreviation} - ${model.directionName}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.rotate_left),
                          tooltip: 'Rotate -15°',
                          onPressed: () => model.adjustHeading(-15),
                        ),
                        IconButton(
                          icon: const Icon(Icons.north),
                          tooltip: 'Set to North',
                          onPressed: () => model.setToNorth(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.rotate_right),
                          tooltip: 'Rotate +15°',
                          onPressed: () => model.adjustHeading(15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ActionChip(
                          label: const Text('N'),
                          onPressed: () => model.setToNorth(),
                        ),
                        ActionChip(
                          label: const Text('E'),
                          onPressed: () => model.setToEast(),
                        ),
                        ActionChip(
                          label: const Text('S'),
                          onPressed: () => model.setToSouth(),
                        ),
                        ActionChip(
                          label: const Text('W'),
                          onPressed: () => model.setToWest(),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    });
  }
}

class CompassPainter extends CustomPainter {
  final double heading;
  final Color primaryColor;
  final Color secondaryColor;
  final Color textColor;

  CompassPainter({
    required this.heading,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final circlePaint = Paint();
    circlePaint.color = secondaryColor.withValues(alpha: 0.3);
    circlePaint.style = PaintingStyle.stroke;
    circlePaint.strokeWidth = 2;

    canvas.drawCircle(center, radius, circlePaint);

    final innerCirclePaint = Paint();
    innerCirclePaint.color = secondaryColor.withValues(alpha: 0.1);
    innerCirclePaint.style = PaintingStyle.fill;

    canvas.drawCircle(center, radius - 20, innerCirclePaint);

    final directions = ['N', 'E', 'S', 'W'];
    final angles = [0.0, 90.0, 180.0, 270.0];

    for (int i = 0; i < directions.length; i++) {
      final angleRad = (angles[i] - 90) * math.pi / 180;
      final x = center.dx + (radius - 30) * math.cos(angleRad);
      final y = center.dy + (radius - 30) * math.sin(angleRad);

      final textPainter = TextPainter(
        text: TextSpan(
          text: directions[i],
          style: TextStyle(
            color: directions[i] == 'N' ? primaryColor : textColor,
            fontSize: 18,
            fontWeight: directions[i] == 'N' ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }

    for (int i = 0; i < 36; i++) {
      final angleRad = (i * 10 - 90) * math.pi / 180;
      final innerRadius = radius - 40;
      final outerRadius = radius - (i % 9 == 0 ? 35 : 38);
      
      final tickPaint = Paint();
      tickPaint.color = i % 9 == 0 ? primaryColor.withValues(alpha: 0.5) : textColor.withValues(alpha: 0.3);
      tickPaint.strokeWidth = i % 9 == 0 ? 2 : 1;

      canvas.drawLine(
        Offset(center.dx + innerRadius * math.cos(angleRad), center.dy + innerRadius * math.sin(angleRad)),
        Offset(center.dx + outerRadius * math.cos(angleRad), center.dy + outerRadius * math.sin(angleRad)),
        tickPaint,
      );
    }

    final needleRotation = -heading + 90;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(needleRotation * math.pi / 180);

    final northNeedlePaint = Paint();
    northNeedlePaint.color = primaryColor;
    northNeedlePaint.style = PaintingStyle.fill;

    final northPath = Path();
    northPath.moveTo(0, -radius + 50);
    northPath.lineTo(-10, 0);
    northPath.lineTo(10, 0);
    northPath.close();
    canvas.drawPath(northPath, northNeedlePaint);

    final southNeedlePaint = Paint();
    southNeedlePaint.color = secondaryColor;
    southNeedlePaint.style = PaintingStyle.fill;

    final southPath = Path();
    southPath.moveTo(0, radius - 50);
    southPath.lineTo(-10, 0);
    southPath.lineTo(10, 0);
    southPath.close();
    canvas.drawPath(southPath, southNeedlePaint);

    canvas.restore();

    final centerDotPaint = Paint();
    centerDotPaint.color = primaryColor;
    centerDotPaint.style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, centerDotPaint);

    final centerDotInnerPaint = Paint();
    centerDotInnerPaint.color = Colors.white;
    centerDotInnerPaint.style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, centerDotInnerPaint);
  }

  @override
  bool shouldRepaint(covariant CompassPainter oldDelegate) {
    return oldDelegate.heading != heading ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.textColor != textColor;
  }
}