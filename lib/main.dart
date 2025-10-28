// main.dart
// Single-file Flutter app: Fitness Workout Planner
// Note: Add required dependencies to pubspec.yaml (listed below) then replace lib/main.dart with this file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lottie/lottie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(FitnessApp(prefs: prefs));
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class FitnessApp extends StatefulWidget {
  final SharedPreferences prefs;
  const FitnessApp({super.key, required this.prefs});

  @override
  State<FitnessApp> createState() => _FitnessAppState();
}

class _FitnessAppState extends State<FitnessApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _initNotifications();
  }

  void _loadTheme() {
    final t = widget.prefs.getString('theme') ?? 'system';
    setState(() {
      _themeMode = (t == 'light')
          ? ThemeMode.light
          : (t == 'dark')
          ? ThemeMode.dark
          : ThemeMode.system;
    });
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: const DarwinInitializationSettings(),
          macOS: const DarwinInitializationSettings(),
        );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _toggleTheme(ThemeMode mode) {
    widget.prefs.setString(
      'theme',
      mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
          ? 'dark'
          : 'system',
    );
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitLife — Workout Planner',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        textTheme: GoogleFonts.poppinsTextTheme(),
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: SplashScreen(
        onFinish: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                AuthScreen(prefs: widget.prefs, onThemeChanged: _toggleTheme),
          ),
        ),
      ),
    );
  }
}

// ------------------ Splash Screen ------------------
class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const SplashScreen({super.key, required this.onFinish});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: Duration(seconds: 2));
    _ctrl.forward();
    Timer(Duration(seconds: 3), widget.onFinish);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade400, Colors.pink.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Lottie.network(
                    'https://assets6.lottiefiles.com/packages/lf20_t24tpvcu.json',
                    repeat: true,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'FitLife',
                  style: GoogleFonts.poppins(
                    fontSize: 34,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Plan. Train. Grow.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------ Auth Screen ------------------
class AuthScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final Function(ThemeMode) onThemeChanged;
  const AuthScreen({
    super.key,
    required this.prefs,
    required this.onThemeChanged,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _loading = false;

  void _login({bool demo = false}) async {
    if (!demo && !_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
    });
    await Future.delayed(Duration(seconds: 1));
    widget.prefs.setString('user_email', demo ? 'demo@fitlife.app' : _email);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          prefs: widget.prefs,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome back',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Sign in or try demo mode to explore',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Enter valid email'
                          : null,
                      onChanged: (v) => _email = v,
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'Min 6 chars' : null,
                      onChanged: (v) => _password = v,
                    ),
                    SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 400),
                      child: _loading
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              key: ValueKey('login-btn'),
                              onPressed: () => _login(),
                              style: ElevatedButton.styleFrom(
                                shape: StadiumBorder(),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                  horizontal: 20,
                                ),
                                child: Text('Login'),
                              ),
                            ),
                    ),
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _login(demo: true),
                      child: Text('Try Demo Mode'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------ Home Screen with tabs ------------------
class HomeScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final Function(ThemeMode) onThemeChanged;
  const HomeScreen({
    super.key,
    required this.prefs,
    required this.onThemeChanged,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FitLife'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  prefs: widget.prefs,
                  onThemeChanged: widget.onThemeChanged,
                ),
              ),
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _index = i),
        children: [
          DashboardScreen(prefs: widget.prefs),
          CategoriesScreen(prefs: widget.prefs),
          PlannerScreen(prefs: widget.prefs),
          ProgressScreen(prefs: widget.prefs),
          ProfileScreen(prefs: widget.prefs),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          setState(() => _index = i);
          _pageController.animateToPage(
            i,
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Planner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => ExercisePlayer())),
        label: Text('Start Workout'),
        icon: Icon(Icons.play_arrow),
      ),
    );
  }
}

// ------------------ Dashboard ------------------
class DashboardScreen extends StatelessWidget {
  final SharedPreferences prefs;
  DashboardScreen({super.key, required this.prefs});

  final List<String> quotes = [
    'Progress, not perfection.',
    'Stronger every day.',
    'Small steps. Big changes.',
  ];

  @override
  Widget build(BuildContext context) {
    final user = prefs.getString('user_email') ?? 'Guest';
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${user.split('@').first}',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCard(
                  context,
                  title: 'Quick Start',
                  subtitle: 'Begin a 15-min full-body',
                  icon: Icons.flash_on,
                  colors: [Colors.orange, Colors.pink],
                ),
                _buildCard(
                  context,
                  title: 'My Plans',
                  subtitle: 'View scheduled workouts',
                  icon: Icons.calendar_view_day,
                  colors: [Colors.blue, Colors.indigo],
                ),
                _buildCard(
                  context,
                  title: 'Music',
                  subtitle: 'Toggle background music',
                  icon: Icons.music_note,
                  colors: [Colors.green, Colors.teal],
                ),
              ],
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Daily motivation',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: PageView.builder(
              itemCount: quotes.length,
              controller: PageController(viewportFraction: 0.9),
              itemBuilder: (context, i) => Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(quotes[i], style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Recommended for you',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _tinyTile('Cardio Blast', Icons.directions_run),
              _tinyTile('Strength', Icons.fitness_center),
              _tinyTile('Yoga', Icons.self_improvement),
              _tinyTile('HIIT', Icons.whatshot),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tinyTile(String title, IconData icon) =>
      Chip(avatar: Icon(icon, size: 18), label: Text(title));

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
  }) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$title tapped'))),
      child: Container(
        width: 240,
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              color: Colors.black26,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------ Categories ------------------
class CategoriesScreen extends StatelessWidget {
  final SharedPreferences prefs;
  CategoriesScreen({super.key, required this.prefs});

  final categories = [
    {'name': 'Cardio', 'icon': Icons.directions_run},
    {'name': 'Strength', 'icon': Icons.fitness_center},
    {'name': 'Yoga', 'icon': Icons.self_improvement},
    {'name': 'Pilates', 'icon': Icons.accessibility},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: EdgeInsets.all(16),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: categories
          .map(
            (c) => _tile(context, c['name'] as String, c['icon'] as IconData),
          )
          .toList(),
    );
  }

  Widget _tile(BuildContext context, String title, IconData icon) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WorkoutDetailScreen(category: title)),
      ),
      child: Hero(
        tag: title,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 350),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade300, Colors.blue.shade300],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 6,
                color: Colors.black12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 44, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------ Workout Detail ------------------
class WorkoutDetailScreen extends StatelessWidget {
  final String category;
  WorkoutDetailScreen({super.key, required this.category});

  final exercises = [
    {'name': 'Jumping Jacks', 'desc': 'Warm up your body', 'reps': '30 sec'},
    {'name': 'Push Ups', 'desc': 'Upper body', 'reps': '3 x 12'},
    {'name': 'Squats', 'desc': 'Legs', 'reps': '3 x 15'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: exercises
            .map(
              (e) => _exerciseTile(context, e['name']!, e['desc']!, e['reps']!),
            )
            .toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => ExercisePlayer())),
        label: Text('Start'),
        icon: Icon(Icons.play_arrow),
      ),
    );
  }

  Widget _exerciseTile(
    BuildContext context,
    String name,
    String desc,
    String reps,
  ) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(child: Text(name[0])),
        title: Text(name),
        subtitle: Text(desc),
        children: [
          ListTile(title: Text('Reps: $reps')),
          OverflowBar(
            children: [
              TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => ExercisePlayer())),
                child: Text('Start'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------ Planner (Calendar) ------------------
class PlannerScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const PlannerScreen({super.key, required this.prefs});
  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focused = DateTime.now();
  DateTime? _selected;
  Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    // load from prefs (simple JSON string list) -- for demo we keep simple
    setState(() {
      _events = {};
    });
  }

  List<String> _getEvents(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _addEvent(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    _events.putIfAbsent(dateKey, () => []);
    _events[dateKey]!.add('Workout at ${TimeOfDay.now().format(context)}');
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Added workout')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focused,
          calendarFormat: _format,
          selectedDayPredicate: (d) => isSameDay(_selected, d),
          onDaySelected: (s, f) {
            setState(() => _selected = s);
          },
          onFormatChanged: (f) {
            setState(() => _format = f);
          },
          onPageChanged: (f) => _focused = f,
          eventLoader: _getEvents,
        ),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _addEvent(_selected ?? DateTime.now()),
          icon: Icon(Icons.add),
          label: Text('Add Workout'),
        ),
        SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(12),
            children: _getEvents(_selected ?? DateTime.now())
                .map(
                  (e) => ListTile(
                    title: Text(e),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {},
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ------------------ Progress (Charts) ------------------
class ProgressScreen extends StatelessWidget {
  final SharedPreferences prefs;
  const ProgressScreen({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final data = [3.0, 4.5, 5.0, 6.0, 5.5, 7.0]; // sample weekly progress
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Weekly Minutes', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          SizedBox(height: 180, child: LineChartWidget(data: data)),
          SizedBox(height: 18),
          Text('Milestones', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _badge('10 workouts')),
              SizedBox(width: 12),
              Expanded(child: _badge('50 km')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label) => Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: Text(label)),
    ),
  );
}

class LineChartWidget extends StatelessWidget {
  final List<double> data;
  const LineChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
            isCurved: true,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

// ------------------ Exercise Player ------------------
class ExercisePlayer extends StatefulWidget {
  const ExercisePlayer({super.key});

  @override
  State<ExercisePlayer> createState() => _ExercisePlayerState();
}

class _ExercisePlayerState extends State<ExercisePlayer> {
  int _seconds = 30;
  Timer? _timer;
  bool _running = false;
  bool _music = false;

  void _start() {
    setState(() => _running = true);
    _timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (_seconds <= 1) {
        t.cancel();
        setState(() => _running = false);
      }
      setState(() => _seconds = (_seconds > 0) ? _seconds - 1 : 0);
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Exercise Player')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Jumping Jacks',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: _seconds / 30,
                    strokeWidth: 12,
                  ),
                ),
                Text('$_seconds', style: TextStyle(fontSize: 34)),
              ],
            ),
            SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _running ? _stop : _start,
                  child: Text(_running ? 'Stop' : 'Start'),
                ),
                SizedBox(width: 12),
                IconButton(
                  icon: Icon(_music ? Icons.music_note : Icons.music_off),
                  onPressed: () => setState(() => _music = !_music),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------ Settings ------------------
class SettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final Function(ThemeMode) onThemeChanged;
  const SettingsScreen({
    super.key,
    required this.prefs,
    required this.onThemeChanged,
  });
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifs = true;
  ThemeMode _selected = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _notifs = widget.prefs.getBool('notifs') ?? true;
    final t = widget.prefs.getString('theme') ?? 'system';
    _selected = (t == 'light')
        ? ThemeMode.light
        : (t == 'dark')
        ? ThemeMode.dark
        : ThemeMode.system;
  }

  void _save() {
    widget.prefs.setBool('notifs', _notifs);
    widget.prefs.setString(
      'theme',
      _selected == ThemeMode.light
          ? 'light'
          : _selected == ThemeMode.dark
          ? 'dark'
          : 'system',
    );
    widget.onThemeChanged(_selected);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Settings saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              value: _notifs,
              onChanged: (v) => setState(() => _notifs = v),
              title: Text('Enable reminders'),
            ),
            ListTile(
              title: Text('Theme'),
              trailing: DropdownButton<ThemeMode>(
                value: _selected,
                items: [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                ],
                onChanged: (v) => setState(() => _selected = v!),
              ),
            ),
            Spacer(),
            ElevatedButton(onPressed: _save, child: Text('Save')),
          ],
        ),
      ),
    );
  }
}

// ------------------ Profile ------------------
class ProfileScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const ProfileScreen({super.key, required this.prefs});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _goal = 'Lose weight';

  @override
  void initState() {
    super.initState();
    _name = widget.prefs.getString('profile_name') ?? '';
    _goal = widget.prefs.getString('profile_goal') ?? 'Lose weight';
  }

  void _save() {
    widget.prefs.setString('profile_name', _name);
    widget.prefs.setString('profile_goal', _goal);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Profile saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            child: Text((_name.isEmpty) ? 'U' : _name[0]),
          ),
          SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(labelText: 'Name'),
            onChanged: (v) => _name = v,
            controller: TextEditingController(text: _name),
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _goal,
            items: [
              'Lose weight',
              'Build muscle',
              'Maintain',
            ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (v) => setState(() => _goal = v ?? _goal),
          ),
          SizedBox(height: 18),
          ElevatedButton(onPressed: _save, child: Text('Save')),
        ],
      ),
    );
  }
}

/*
  ------------------ Notes ------------------
  * This is a demo single-file app showing many features requested.
  * For production split into multiple files, handle lifecycle & background notifications properly.
*/
