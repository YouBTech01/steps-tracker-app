import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'dart:math';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => StepCounterProvider(prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(prefs),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Step Counter',
          theme: settings.currentTheme,
          home: const StepCounterScreen(),
        );
      },
    );
  }
}

class StepCounterScreen extends StatefulWidget {
  const StepCounterScreen({super.key});

  @override
  State<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final provider = Provider.of<StepCounterProvider>(context, listen: false);
    await provider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final useAnimations = settings.useAnimations;

    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        child: Consumer<StepCounterProvider>(
          builder: (context, provider, child) {
            Widget content = SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    _buildTopBar(),
                    const SizedBox(height: 30),
                    _buildStepCounter(provider, settings),
                    const SizedBox(height: 30),
                    _buildStats(provider),
                    const SizedBox(height: 30),
                    _buildWeeklyProgress(provider),
                    const SizedBox(height: 30),
                    _buildWaterTracker(provider),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );

            if (useAnimations) {
              content = content.animate().fadeIn(
                    duration: const Duration(milliseconds: 600),
                  );
            }

            return content;
          },
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white, size: 28),
          onPressed: () => _showHelpDialog(),
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white, size: 28),
          onPressed: () => _showSettingsDialog(),
        ),
      ],
    );
  }

  Widget _buildStepCounter(StepCounterProvider provider, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Text(
            provider.steps.toString(),
            style: GoogleFonts.poppins(
              fontSize: 80,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Total Steps / ${settings.stepGoal}',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: provider.steps / settings.stepGoal,
                backgroundColor: Colors.white.withAlpha(51),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.greenAccent.shade400,
                ),
                minHeight: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(StepCounterProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            Icons.location_on,
            '${provider.distance.toStringAsFixed(2)}\nKm',
            Colors.amber,
          ),
          _buildStat(
            Icons.local_fire_department,
            '${provider.calories.toStringAsFixed(2)}\nCalories',
            Colors.redAccent,
          ),
          _buildStat(
            Icons.timer,
            '${provider.duration.inHours}h ${provider.duration.inMinutes.remainder(60)}m',
            Colors.cyanAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String text, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyProgress(StepCounterProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Text(
            'Weekly Progress',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: provider.weeklyProgress[index]
                          ? Colors.greenAccent.shade400
                          : Colors.white.withAlpha(26),
                    ),
                    child: Icon(
                      Icons.check,
                      color: provider.weeklyProgress[index]
                          ? Colors.white
                          : Colors.transparent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTracker(StepCounterProvider provider) {
    final settings = Provider.of<SettingsProvider>(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Text(
            'Water Intake',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            '${provider.waterIntake}/${settings.waterGoal}ml',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              3,
              (index) => GestureDetector(
                onTap: () => provider.addWater(),
                child: Container(
                  width: 70,
                  height: 90,
                  decoration: BoxDecoration(
                    color: index == 0
                        ? Colors.blue.withAlpha(77)
                        : Colors.blue.withAlpha(51),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withAlpha(26),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (index == 0)
                        const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      const SizedBox(height: 5),
                      Text(
                        '200ml',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Help',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(
              Icons.directions_walk,
              'Steps are counted automatically as you walk',
            ),
            const SizedBox(height: 10),
            _buildHelpItem(
              Icons.local_drink,
              'Tap on water glasses to track your water intake',
            ),
            const SizedBox(height: 10),
            _buildHelpItem(
              Icons.calendar_today,
              'Weekly progress shows your daily achievements',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade800,
            borderRadius: BorderRadius.circular(25),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Settings',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Consumer<SettingsProvider>(
                  builder: (context, settings, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            'Step Goal',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${settings.stepGoal} steps',
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () => _showStepGoalDialog(settings),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            'Water Goal',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${settings.waterGoal}ml',
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () => _showWaterGoalDialog(settings),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            'Reminder Interval',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${settings.reminderInterval} minutes',
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () => _showReminderDialog(settings),
                          ),
                        ),
                        const Divider(color: Colors.white24),
                        SwitchListTile(
                          title: Text(
                            'Animations',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          value: settings.useAnimations,
                          onChanged: (value) => settings.toggleAnimations(),
                          activeColor: Colors.white,
                        ),
                        SwitchListTile(
                          title: Text(
                            'Sound Effects',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          value: settings.useSound,
                          onChanged: (value) => settings.toggleSound(),
                          activeColor: Colors.white,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showStepGoalDialog(SettingsProvider settings) async {
    int value = settings.stepGoal;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Set Step Goal',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.toString(),
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildValueButton(
                  Icons.remove,
                  () {
                    if (value - 1000 >= 1000) {
                      value -= 1000;
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
                const SizedBox(width: 20),
                _buildValueButton(
                  Icons.add,
                  () {
                    if (value + 1000 <= 20000) {
                      value += 1000;
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              settings.setStepGoal(value);
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showWaterGoalDialog(SettingsProvider settings) async {
    int value = settings.waterGoal;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Set Water Goal',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.toString(),
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildValueButton(
                  Icons.remove,
                  () {
                    if (value - 500 >= 500) {
                      value -= 500;
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
                const SizedBox(width: 20),
                _buildValueButton(
                  Icons.add,
                  () {
                    if (value + 500 <= 5000) {
                      value += 500;
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              settings.setWaterGoal(value);
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReminderDialog(SettingsProvider settings) async {
    int value = settings.reminderInterval;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Set Reminder Interval',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.toString(),
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildValueButton(
                  Icons.remove,
                  () {
                    if (value - 15 >= 15) {
                      value -= 15;
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
                const SizedBox(width: 20),
                _buildValueButton(
                  Icons.add,
                  () {
                    if (value + 15 <= 180) {
                      value += 15;
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              settings.setReminderInterval(value);
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.blue,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class StepCounterProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  int _steps = 0;
  double _distance = 0.0;
  double _calories = 0.0;
  Duration _duration = Duration.zero;
  int _waterIntake = 0;
  Timer? _timer;
  DateTime? _startTime;
  DateTime? _lastResetDate;
  List<bool> weeklyProgress = List.generate(7, (index) => false);
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isInitialized = false;

  // Step detection parameters
  final double _stepThreshold = 12.0; // Minimum acceleration to count as a step
  final int _stepCooldown = 300; // Milliseconds between steps
  DateTime? _lastStepTime;
  final List<double> _accelerometerValues = [];
  static const int _windowSize = 10; // Size of moving average window

  StepCounterProvider(this._prefs);

  int get steps => _steps;
  double get distance => _distance;
  double get calories => _calories;
  Duration get duration => _duration;
  int get waterIntake => _waterIntake;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    await _loadSavedData();
    await _initializeStepDetector();
    _startTimer();
    _checkAndResetDaily();
  }

  Future<void> _loadSavedData() async {
    _steps = _prefs.getInt('steps') ?? 0;
    _waterIntake = _prefs.getInt('water') ?? 0;
    
    final lastResetMillis = _prefs.getInt('last_reset_date');
    _lastResetDate = lastResetMillis != null 
        ? DateTime.fromMillisecondsSinceEpoch(lastResetMillis)
        : DateTime.now();

    final startTimeMillis = _prefs.getInt('startTime');
    _startTime = startTimeMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(startTimeMillis)
        : DateTime.now();
    
    // Load weekly progress
    for (int i = 0; i < 7; i++) {
      weeklyProgress[i] = _prefs.getBool('progress_$i') ?? false;
    }
    
    _calculateStats();
    notifyListeners();
  }

  Future<void> _saveData() async {
    await _prefs.setInt('steps', _steps);
    await _prefs.setInt('water', _waterIntake);
    await _prefs.setInt('startTime', _startTime!.millisecondsSinceEpoch);
    await _prefs.setInt('last_reset_date', _lastResetDate!.millisecondsSinceEpoch);
    
    // Save weekly progress
    for (int i = 0; i < 7; i++) {
      await _prefs.setBool('progress_$i', weeklyProgress[i]);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startTime != null) {
        _duration = DateTime.now().difference(_startTime!);
        _checkAndResetDaily();
        notifyListeners();
      }
    });
  }

  Future<void> _initializeStepDetector() async {
    try {
      if (await Permission.activityRecognition.request().isGranted) {
        await _accelerometerSubscription?.cancel();
        
        // Set up accelerometer stream with higher frequency
        _accelerometerSubscription = accelerometerEvents.listen(
          (AccelerometerEvent event) {
            _processAccelerometerData(event);
          },
          onError: (error) {
            debugPrint('Accelerometer error: $error');
            Future.delayed(
              const Duration(seconds: 5),
              _initializeStepDetector,
            );
          },
          cancelOnError: false,
        );
      } else {
        debugPrint('Activity recognition permission denied');
      }
    } catch (e) {
      debugPrint('Failed to initialize step detector: $e');
      Future.delayed(
        const Duration(seconds: 5),
        _initializeStepDetector,
      );
    }
  }

  void _processAccelerometerData(AccelerometerEvent event) {
    // Calculate the magnitude of acceleration
    double magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    // Add to moving average window
    _accelerometerValues.add(magnitude);
    if (_accelerometerValues.length > _windowSize) {
      _accelerometerValues.removeAt(0);
    }

    // Calculate moving average
    double avgMagnitude = _accelerometerValues.reduce((a, b) => a + b) / 
                         _accelerometerValues.length;

    // Check if this is a step
    if (avgMagnitude > _stepThreshold) {
      final now = DateTime.now();
      if (_lastStepTime == null || 
          now.difference(_lastStepTime!).inMilliseconds > _stepCooldown) {
        _steps++;
        _lastStepTime = now;
        _calculateStats();
        _checkAndUpdateProgress();
        _saveData();
        notifyListeners();
      }
    }
  }

  void _checkAndResetDaily() {
    final now = DateTime.now();
    final lastReset = _lastResetDate ?? now;
    
    if (now.day != lastReset.day || 
        now.month != lastReset.month || 
        now.year != lastReset.year) {
      _resetDaily();
    }
  }

  Future<void> _resetDaily() async {
    _checkAndUpdateProgress();
    
    _steps = 0;
    _distance = 0.0;
    _calories = 0.0;
    _duration = Duration.zero;
    _waterIntake = 0;
    _startTime = DateTime.now();
    _lastResetDate = DateTime.now();
    _accelerometerValues.clear();
    _lastStepTime = null;
    
    await _saveData();
    notifyListeners();
  }

  void _calculateStats() {
    const double strideLength = 0.762; // Average stride length in meters
    _distance = _steps * strideLength / 1000; // Convert to kilometers
    _calories = _steps * 0.04; // Average calories burned per step
  }

  void _checkAndUpdateProgress() {
    final settings = SettingsProvider(_prefs);
    if (_steps >= settings.stepGoal) {
      final today = DateTime.now().weekday - 1;
      weeklyProgress[today] = true;
      _saveData();
    }
  }

  Future<void> addWater() async {
    final settings = SettingsProvider(_prefs);
    if (_waterIntake < settings.waterGoal) {
      _waterIntake += 200;
      await _saveData();
      notifyListeners();
    }
  }

  Future<void> resetWater() async {
    _waterIntake = 0;
    await _saveData();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }
}

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  int _stepGoal;
  int _waterGoal;
  int _reminderInterval;
  bool _useAnimations;
  bool _useSound;

  SettingsProvider(this._prefs)
      : _stepGoal = _prefs.getInt('stepGoal') ?? 10000,
        _waterGoal = _prefs.getInt('waterGoal') ?? 2000,
        _reminderInterval = _prefs.getInt('reminderInterval') ?? 30,
        _useAnimations = _prefs.getBool('useAnimations') ?? true,
        _useSound = _prefs.getBool('useSound') ?? true;

  int get stepGoal => _stepGoal;
  int get waterGoal => _waterGoal;
  int get reminderInterval => _reminderInterval;
  bool get useAnimations => _useAnimations;
  bool get useSound => _useSound;

  ThemeData get currentTheme => ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );

  Future<void> setStepGoal(int goal) async {
    _stepGoal = goal;
    await _prefs.setInt('stepGoal', goal);
    notifyListeners();
  }

  Future<void> setWaterGoal(int goal) async {
    _waterGoal = goal;
    await _prefs.setInt('waterGoal', goal);
    notifyListeners();
  }

  Future<void> setReminderInterval(int interval) async {
    _reminderInterval = interval;
    await _prefs.setInt('reminderInterval', interval);
    notifyListeners();
  }

  Future<void> toggleAnimations() async {
    _useAnimations = !_useAnimations;
    await _prefs.setBool('useAnimations', _useAnimations);
    notifyListeners();
  }

  Future<void> toggleSound() async {
    _useSound = !_useSound;
    await _prefs.setBool('useSound', _useSound);
    notifyListeners();
  }
}
