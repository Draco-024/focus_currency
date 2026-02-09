import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:device_apps/device_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'questions.dart'; 

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const CapitalApp());
}

class CapitalApp extends StatelessWidget {
  const CapitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Focus Currency',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000), 
        primaryColor: const Color(0xFF00E676), 
        textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  int _capital = 0;
  List<Application> _apps = [];
  List<String> _lockedPackages = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  Timer? _monitorTimer;
  bool _isLockScreenVisible = false;
  final Map<String, DateTime> _unlockedSession = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSystem());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _monitorTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermsAndLoad();
    }
  }

  Future<void> _initSystem() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      
      setState(() {
        _capital = prefs.getInt('capital_balance') ?? 0;
        _lockedPackages = prefs.getStringList('locked_apps') ?? [];
      });

      List<Application> apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: false,
        onlyAppsWithLaunchIntent: true,
      );
      
      apps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));

      if (mounted) {
        setState(() {
          _apps = apps;
          _isLoading = false;
        });
      }

      await _checkPermsAndLoad();
      _startMonitoring();

    } catch (e) {
      debugPrint("Init Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkPermsAndLoad() async {
    bool isGranted = await UsageStats.checkUsagePermission() ?? false;
    if (mounted) {
      setState(() => _hasPermission = isGranted);
      final prefs = await SharedPreferences.getInstance();
      setState(() => _capital = prefs.getInt('capital_balance') ?? 0);
    }
  }

  void _startMonitoring() {
    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      if (!_hasPermission) return;
      if (_isLockScreenVisible) return; 

      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(seconds: 2));
      
      try {
        List<UsageInfo> events = await UsageStats.queryUsageStats(startDate, endDate);
        events.sort((a, b) => int.parse(b.lastTimeUsed!).compareTo(int.parse(a.lastTimeUsed!)));

        if (events.isEmpty) return;

        var topEvent = events.first;
        if (topEvent.packageName == null) return;

        if (_lockedPackages.contains(topEvent.packageName!)) {
          if (_unlockedSession.containsKey(topEvent.packageName!)) {
            if (DateTime.now().isBefore(_unlockedSession[topEvent.packageName!]!)) {
              return; 
            } else {
              _unlockedSession.remove(topEvent.packageName!); 
            }
          }
          if (mounted) _showBlockScreen(topEvent.packageName!);
        }
      } catch (e) {
        // Ignore background permission hiccups
      }
    });
  }

  void _showBlockScreen(String lockedPackage) {
    setState(() => _isLockScreenVisible = true);

    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => LockScreen(
        packageName: lockedPackage, 
        onUnlock: () {
          _unlockedSession[lockedPackage] = DateTime.now().add(const Duration(minutes: 5));
          DeviceApps.openApp(lockedPackage);
        }
      )), 
    ).then((_) {
      if (mounted) setState(() => _isLockScreenVisible = false);
    });
  }

  Future<void> _toggleLock(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_lockedPackages.contains(packageName)) {
        _lockedPackages.remove(packageName);
      } else {
        _lockedPackages.add(packageName);
      }
    });
    await prefs.setStringList('locked_apps', _lockedPackages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FOCUS CURRENCY", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Text("$_capital CAP", style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
        : Column(
        children: [
          if (!_hasPermission)
            GestureDetector(
              onTap: () => UsageStats.grantUsagePermission(),
              child: Container(
                margin: const EdgeInsets.all(15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.redAccent)),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Expanded(child: Text("Tap here to enable Usage Access.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.grey),
                  SizedBox(width: 10),
                  Expanded(child: Text("Lock distracting apps. Pay Focus Currency to open them.", style: TextStyle(color: Colors.grey, fontSize: 12))),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              itemCount: _apps.length,
              itemBuilder: (context, index) {
                ApplicationWithIcon app = _apps[index] as ApplicationWithIcon;
                bool isLocked = _lockedPackages.contains(app.packageName);
                return SwitchListTile(
                  activeColor: const Color(0xFF00E676),
                  secondary: Image.memory(app.icon, width: 32),
                  title: Text(app.appName, style: const TextStyle(color: Colors.white)),
                  value: isLocked,
                  onChanged: (val) => _toggleLock(app.packageName),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00E676),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => ExchangeScreen(onEarn: (amt) async {
            final prefs = await SharedPreferences.getInstance();
            int bal = prefs.getInt('capital_balance') ?? 0;
            await prefs.setInt('capital_balance', bal + amt);
          })));
          _checkPermsAndLoad();
        },
      ),
    );
  }
}

class LockScreen extends StatefulWidget {
  final String packageName;
  final VoidCallback onUnlock;

  const LockScreen({super.key, required this.packageName, required this.onUnlock});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  int _capital = 0;

  @override
  void initState() {
    super.initState();
    _loadBal();
  }

  Future<void> _loadBal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _capital = prefs.getInt('capital_balance') ?? 0);
  }

  Future<void> _pay() async {
    if (_capital >= 10) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('capital_balance', _capital - 10);
      widget.onUnlock(); 
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, 
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 60, color: Colors.redAccent),
              const SizedBox(height: 20),
              const Text("APP LOCKED", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 10),
              Text("Pay 10 Currency to access for 5 mins.", style: TextStyle(color: Colors.grey[500])),
              const SizedBox(height: 40),
              
              Text("BALANCE: $_capital CAP", style: const TextStyle(fontSize: 18, color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              if (_capital >= 10)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
                    onPressed: _pay,
                    child: const Text("PAY & UNLOCK", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(10)),
                  child: const Text("INSUFFICIENT FUNDS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => ExchangeScreen(onEarn: (amt) async {
                    final prefs = await SharedPreferences.getInstance();
                    int bal = prefs.getInt('capital_balance') ?? 0;
                    await prefs.setInt('capital_balance', bal + amt);
                  })));
                  _loadBal();
                },
                child: const Text("EARN CURRENCY ->", style: TextStyle(color: Colors.white, letterSpacing: 1)),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                   Navigator.pop(context); 
                   SystemNavigator.pop(); 
                },
                child: const Text("EXIT", style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ExchangeScreen extends StatefulWidget {
  final Function(int) onEarn;
  const ExchangeScreen({super.key, required this.onEarn});

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  late Question _currentQ;
  bool _answered = false;
  bool _correct = false;
  int _sessionEarned = 0;

  @override
  void initState() {
    super.initState();
    _loadQ();
  }

  void _loadQ() {
    setState(() {
      _answered = false;
      _currentQ = QuestionGenerator.next();
    });
  }

  void _handleAnswer(int index) {
    if (_answered) return;
    bool isCorrect = index == _currentQ.correctIndex;
    if(isCorrect) {
      widget.onEarn(_currentQ.reward);
      _sessionEarned += _currentQ.reward;
    }
    setState(() {
      _answered = true;
      _correct = isCorrect;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Session: +$_sessionEarned"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("DONE", style: TextStyle(color: Color(0xFF00E676))))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF00E676).withOpacity(0.1), borderRadius: BorderRadius.circular(5)), child: Text(_currentQ.subject, style: const TextStyle(color: Color(0xFF00E676)))),
              const Spacer(),
              Text("+${_currentQ.reward}", style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold))
            ]),
            const Spacer(),
            Text(_currentQ.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Spacer(),
            ...List.generate(_currentQ.options.length, (i) {
               Color c = Colors.white10;
               if(_answered) {
                 if(i==_currentQ.correctIndex) c=Colors.green.withOpacity(0.3);
                 else if(i!=_currentQ.correctIndex) c=Colors.white10;
               }
               return Padding(padding: const EdgeInsets.only(bottom: 10), child: GestureDetector(onTap: ()=>_handleAnswer(i), child: Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(15)), child: Text(_currentQ.options[i]))));
            }),
            const SizedBox(height: 20),
            if(_answered) SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _correct?const Color(0xFF00E676):Colors.redAccent, foregroundColor: Colors.black), onPressed: _loadQ, child: const Text("NEXT QUESTION")))
          ],
        ),
      ),
    );
  }
}