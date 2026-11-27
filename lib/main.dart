import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';

final notificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await notificationsPlugin.initialize(
    const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
  );
  runApp(const ItqanApp());
}

class ItqanApp extends StatelessWidget {
  const ItqanApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إتقان — ITQAN',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Tajawal',
        scaffoldBackgroundColor: const Color(0xFFFAF8F2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B3D2E),
          primary: const Color(0xFF0B3D2E),
          secondary: const Color(0xFFC9A227),
          surface: const Color(0xFFFAF8F2),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B3D2E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const SplashLoaderScreen(),
    );
  }
}

class AyahModel {
  final int num;
  final String text;
  final int page;
  final int juz;
  const AyahModel({required this.num, required this.text, required this.page, required this.juz});
}

class SurahModel {
  final int num;
  final String name;
  final String type;
  final int page;
  final List<AyahModel> ayahs;
  const SurahModel({required this.num, required this.name, required this.type, required this.page, required this.ayahs});
}

class SplashLoaderScreen extends StatefulWidget {
  const SplashLoaderScreen({super.key});
  @override
  State<SplashLoaderScreen> createState() => _SplashLoaderScreenState();
}

class _SplashLoaderScreenState extends State<SplashLoaderScreen> {
  List<SurahModel>? _quran;

  @override
  void initState() {
    super.initState();
    _loadFullQuran();
  }

  Future<void> _loadFullQuran() async {
    final raw = await rootBundle.loadString('assets/data/quran_full.json');
    final List<dynamic> decoded = jsonDecode(raw);
    final list = decoded.map((s) {
      final ayahs = (s['ayahs'] as List)
          .map((a) => AyahModel(num: a['n'], text: a['t'], page: a['p'] ?? 1, juz: a['j'] ?? 1))
          .toList();
      return SurahModel(num: s['num'], name: s['name'], type: s['type'] ?? 'مكية', page: s['page'] ?? 1, ayahs: ayahs);
    }).toList();
    if (mounted) setState(() => _quran = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B3D2E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/itqan_bg.png', fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x140B3D2E), Color(0x440B3D2E), Color(0xF007291F), Color(0xFF07291F)],
                stops: [0.0, 0.45, 0.72, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('إتقان', style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 52, fontWeight: FontWeight.bold, color: Color(0xFFE8D595), height: 1.2)),
                  const Text('ITQAN', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, letterSpacing: 4, fontWeight: FontWeight.bold, color: Color(0xFFC9A227))),
                  const SizedBox(height: 12),
                  const Text(
                    'المصحف كاملًا (١١٤ سورة • ٦٢٣٦ آية) — تسمّع من حفظك فتظهر الآيات كلمة بكلمة مع صوتك.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  if (_quran == null)
                    const CircularProgressIndicator(color: Color(0xFFC9A227))
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC9A227),
                          foregroundColor: const Color(0xFF07291F),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => MainShell(surahs: _quran!)),
                        ),
                        child: const Text('ابدأ التسميع الآن', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Text('مصحف المدينة المنورة • رواية حفص عن عاصم • بدون نت وإعلانات', style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChallengeSlot {
  String name;
  bool joined;
  bool done;
  int score;
  bool isUser;
  ChallengeSlot({required this.name, required this.joined, this.done = false, this.score = 0, this.isUser = false});
}

class MainShell extends StatefulWidget {
  final List<SurahModel> surahs;
  const MainShell({super.key, required this.surahs});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final FlutterTts _tts = FlutterTts();
  int _tab = 0;
  String _search = '';
  final Set<int> _mastered = {1};
  final List<String> _mistakes = [];
  bool _hasCompleted = false;
  int _lastScore = 0;
  int _lastErrors = 0;
  String _lastSurahName = '';
  late String _roomCode;
  late SurahModel _challengeSurah;
  late List<ChallengeSlot> _slots;

  @override
  void initState() {
    super.initState();
    _roomCode = 'ITQAN-${1000 + Random().nextInt(8999)}';
    _challengeSurah = widget.surahs[81];
    _slots = [
      ChallengeSlot(name: 'أنت (منشئ الغرفة)', joined: true, isUser: true),
      ChallengeSlot(name: '', joined: false),
      ChallengeSlot(name: '', joined: false),
      ChallengeSlot(name: '', joined: false),
      ChallengeSlot(name: '', joined: false),
    ];
    _tts.setLanguage('ar-SA');
    _loadMastered();
  }

  Future<void> _loadMastered() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getStringList('mastered_surahs');
    if (saved != null) {
      setState(() {
        _mastered
          ..clear()
          ..addAll(saved.map((e) => int.tryParse(e) ?? 1));
      });
    }
  }

  Future<void> _saveMastered() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('mastered_surahs', _mastered.map((e) => '$e').toList());
  }

  Future<void> _openStudio(SurahModel s, {bool mushafMode = false}) async {
    final res = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => ReciteStudioScreen(surah: s, startInMushaf: mushafMode, tts: _tts)),
    );
    if (res != null && mounted) {
      final int score = res['score'] ?? 95;
      final int errs = res['errors'] ?? 0;
      final List<String> errsList = List<String>.from(res['mistakes'] ?? []);
      setState(() {
        _hasCompleted = true;
        _lastScore = score;
        _lastErrors = errs;
        _lastSurahName = s.name;
        for (final m in errsList) {
          if (!_mistakes.contains(m)) _mistakes.insert(0, m);
        }
        if (score >= 85) _mastered.add(s.num);
        if (_challengeSurah.num == s.num) {
          _slots[0].done = true;
          _slots[0].score = score;
        }
        _tab = 1;
      });
      _saveMastered();
    }
  }

  void _showAboutDeveloper() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFAF8F2),
        title: const Text('إتقان — ITQAN', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Color(0xFF0B3D2E))),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('م. عبدالرحمن المهدلي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0B3D2E))),
            SizedBox(height: 6),
            Directionality(textDirection: TextDirection.ltr, child: Text('+967 776768126', style: TextStyle(color: Color(0xFFC9A227), fontWeight: FontWeight.bold))),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
      ),
    );
  }

  Widget _buildHome() {
    final pct = ((_mastered.length / 114) * 100).round();
    final filtered = _search.trim().isEmpty
        ? widget.surahs
        : widget.surahs.where((s) => s.name.contains(_search.trim()) || '${s.num}' == _search.trim()).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFF0B3D2E), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0x66C9A227))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ايش بتسمّع اليوم؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('$pct% (${_mastered.length}/114)', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Color(0xFFC9A227), fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن أي سورة من الـ ١١٤ سورة...',
                    hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF07291F),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC9A227), foregroundColor: const Color(0xFF07291F)),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FajrModeScreen(surah: widget.surahs[66], tts: _tts))),
                        child: const Text('وضع الفجر', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE8D595), side: const BorderSide(color: Color(0x88C9A227))),
                        onPressed: () => setState(() => _tab = 2),
                        child: const Text('تحدي ٥ أشخاص', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            itemCount: filtered.length + 1,
            itemBuilder: (_, i) {
              if (i == filtered.length) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _showAboutDeveloper,
                    child: const Text('م. عبدالرحمن المهدلي • +967 776768126', style: TextStyle(fontSize: 10, color: Color(0x775C6963))),
                  ),
                );
              }
              final s = filtered[i];
              final mastered = _mastered.contains(s.num);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: mastered ? const Color(0xFFC9A227) : const Color(0xFFE7E0CE)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: mastered ? const Color(0xFF0B3D2E) : const Color(0xFFFAF8F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${s.num}', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12, color: mastered ? const Color(0xFFE8D595) : const Color(0xFF0B3D2E))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0B3D2E))),
                          Text('${s.type} • ${s.ayahs.length} آية • ص ${s.page}', style: const TextStyle(fontSize: 11, color: Color(0xFF5C6963))),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openStudio(s, mushafMode: true),
                      child: const Text('المصحف', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF5C6963))),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B3D2E), foregroundColor: const Color(0xFFE8D595), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                      onPressed: () => _openStudio(s, mushafMode: false),
                      child: const Text('سمّع', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_hasCompleted)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: const Color(0xFF0B3D2E), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFC9A227))),
            child: Column(
              children: [
                Text(_lastSurahName, style: const TextStyle(color: Color(0xFFC9A227), fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('أداؤك اليوم $_lastScore%', style: const TextStyle(fontFamily: 'Cairo', fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFFE8D595))),
                const SizedBox(height: 6),
                Text('عدد الأخطاء: $_lastErrors', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE7E0CE))),
            child: const Text('أنهِ تسميع أي سورة لتظهر نتيجتك وسجل أخطائك هنا.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF5C6963))),
          ),
        const SizedBox(height: 18),
        Text('سجل «أخطائي» (${_mistakes.length})', style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B3D2E))),
        const SizedBox(height: 8),
        for (final m in _mistakes)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE7E0CE))),
            child: Text(m, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 18, color: Color(0xFF0B3D2E))),
          ),
      ],
    );
  }

  Widget _buildChallenge() {
    final completed = _slots.where((s) => s.joined && s.done).toList()..sort((a, b) => b.score.compareTo(a.score));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF0B3D2E), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0x88C9A227))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('رمز الغرفة: $_roomCode', style: const TextStyle(color: Color(0xFFC9A227), fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Text('تحدي ${_challengeSurah.name} (٥ أشخاص)', style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('مقاعد فارغة حقيقية — أرسل الرابط لرفاقك الأربعة، والأعلى إتقانًا ينال تاج «متقن اليوم».', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC9A227), foregroundColor: const Color(0xFF07291F)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: 'أدعوك لتحدي حفظ ${_challengeSurah.name} في تطبيق إتقان! رمز الغرفة: $_roomCode'));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ دعوة التحدي لإرسالها لرفاقك')));
                    },
                    child: const Text('نسخ رابط الدعوة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE8D595), side: const BorderSide(color: Color(0x88C9A227))),
                    onPressed: () => _openStudio(_challengeSurah, mushafMode: false),
                    child: const Text('سمّع الآن', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < _slots.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _slots[i].joined ? Colors.white : const Color(0xFFFAF8F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _slots[i].joined ? const Color(0xFF0B3D2E) : const Color(0x88C9A227)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_slots[i].joined ? _slots[i].name : 'مقعد ${i + 1} فارغ — بانتظار انضمام رفيق', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: _slots[i].joined ? const Color(0xFF0B3D2E) : const Color(0xFF5C6963))),
                Text(_slots[i].done ? '${_slots[i].score}%' : '—', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Color(0xFFC9A227))),
              ],
            ),
          ),
        const SizedBox(height: 10),
        const Text('لوحة النتائج اليومية', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B3D2E))),
        const SizedBox(height: 8),
        if (completed.isEmpty)
          const Text('اللوحة فارغة حتى يُنهي المتسابقون التسميع.', style: TextStyle(fontSize: 12, color: Color(0xFF5C6963)))
        else
          for (var i = 0; i < completed.length; i++)
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: i == 0 ? const Color(0xFFC9A227) : const Color(0xFFE7E0CE))),
              title: Text(completed[i].name, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Color(0xFF0B3D2E))),
              subtitle: i == 0 ? const Text('متقن اليوم', style: TextStyle(color: Color(0xFFC9A227), fontWeight: FontWeight.bold, fontSize: 12)) : null,
              trailing: Text('${completed[i].score}%', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0B3D2E))),
            ),
      ],
    );
  }

  Widget _buildKhatmah() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('ختمتي — ${_mastered.length} / 114 سورة متقنة', style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B3D2E))),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.0),
          itemCount: widget.surahs.length,
          itemBuilder: (_, i) {
            final s = widget.surahs[i];
            final ok = _mastered.contains(s.num);
            return InkWell(
              onTap: () {
                setState(() => ok ? _mastered.remove(s.num) : _mastered.add(s.num));
                _saveMastered();
              },
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: ok ? const Color(0xFF0B3D2E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ok ? const Color(0xFFC9A227) : const Color(0xFFE7E0CE)),
                ),
                child: Text(s.name.replaceFirst('سورة ', ''), overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: ok ? Colors.white : const Color(0xFF0B3D2E))),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_buildHome(), _buildResult(), _buildChallenge(), _buildKhatmah()];
    final titles = ['إتقان — ITQAN', 'النتيجة وأخطائي', 'تحدي ٥ أشخاص', 'ختمتي'];
    return Scaffold(
      appBar: AppBar(title: Text(titles[_tab], style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18))),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0x24C9A227),
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF0B3D2E)), label: 'المصحف'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded, color: Color(0xFF0B3D2E)), label: 'النتيجة'),
          NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded, color: Color(0xFF0B3D2E)), label: 'التحدي'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded, color: Color(0xFF0B3D2E)), label: 'ختمتي'),
        ],
      ),
    );
  }
}

class ReciteStudioScreen extends StatefulWidget {
  final SurahModel surah;
  final bool startInMushaf;
  final FlutterTts tts;
  const ReciteStudioScreen({super.key, required this.surah, required this.startInMushaf, required this.tts});
  @override
  State<ReciteStudioScreen> createState() => _ReciteStudioScreenState();
}

class _ReciteStudioScreenState extends State<ReciteStudioScreen> with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  late AnimationController _orbCtrl;
  late bool _mushafMode;
  bool _peekText = false;
  bool _listening = false;
  bool _paused = false;
  double _fontSize = 30;
  int _ayahIdx = 0;
  int _revealedWords = 0;
  bool _firstLetterHint = false;
  bool _errorWord = false;
  int _errorsCount = 0;
  int _seconds = 0;
  Timer? _clock;
  final Set<int> _doneAyahs = {};
  final List<String> _mistakes = [];

  @override
  void initState() {
    super.initState();
    _mushafMode = widget.startInMushaf;
    _orbCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_listening && !_paused && mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _orbCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  String _fmtTime(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  String _clean(String s) => s
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
      .replaceAll(RegExp(r'[إأآا]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .trim();

  String _firstLetter(String w) {
    if (w.isEmpty) return '';
    int i = 1;
    while (i < w.length && RegExp(r'[\u064B-\u065F\u0670]').hasMatch(w[i])) {
      i++;
    }
    return '${w.substring(0, i)}ـ';
  }

  void _revealWords(int count) {
    final ayah = widget.surah.ayahs[_ayahIdx];
    final words = ayah.text.split(RegExp(r'\s+'));
    HapticFeedback.lightImpact();
    setState(() {
      _errorWord = false;
      _firstLetterHint = false;
      _revealedWords = (_revealedWords + count).clamp(0, words.length);
      if (_revealedWords >= words.length) {
        _doneAyahs.add(_ayahIdx);
        if (_ayahIdx < widget.surah.ayahs.length - 1) {
          _ayahIdx++;
          _revealedWords = 0;
        } else {
          _finishSession();
        }
      }
    });
  }

  void _onLahn() {
    final ayah = widget.surah.ayahs[_ayahIdx];
    HapticFeedback.heavyImpact();
    setState(() {
      _errorWord = true;
      _errorsCount++;
      final rec = '${widget.surah.name} — آية ${ayah.num}: ${ayah.text}';
      if (!_mistakes.contains(rec)) _mistakes.add(rec);
    });
    widget.tts.speak('وقف، أعد النطق الصحيح');
  }

  Future<void> _toggleOrb() async {
    if (_listening) {
      await _speech.stop();
      _orbCtrl.stop();
      setState(() { _listening = false; _paused = false; });
      return;
    }
    final ok = await _speech.initialize();
    setState(() { _listening = true; _paused = false; });
    _orbCtrl.repeat();
    if (!ok) return;
    await _speech.listen(
      localeId: 'ar_SA',
      partialResults: true,
      onResult: (res) {
        if (_paused) return;
        final ayah = widget.surah.ayahs[_ayahIdx];
        final words = ayah.text.split(RegExp(r'\s+'));
        final tokens = _clean(res.recognizedWords).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
        int m = _revealedWords;
        for (final tok in tokens) {
          if (m < words.length) {
            final tgt = _clean(words[m]);
            if (tgt == tok || (tok.length >= 2 && tgt.startsWith(tok))) m++;
          }
        }
        if (m > _revealedWords) {
          _revealWords(m - _revealedWords);
        } else if (res.finalResult && tokens.length >= 2) {
          _onLahn();
        }
      },
    );
  }

  void _finishSession() {
    final score = (100 - _errorsCount * 4).clamp(70, 100);
    Navigator.pop(context, {'score': score, 'errors': _errorsCount, 'mistakes': _mistakes});
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.surah.ayahs.length;
    final dotCount = total > 19 ? 19 : total;
    final activeDot = ((_ayahIdx / total) * dotCount).floor().clamp(0, dotCount - 1);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F2),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF121A17)), onPressed: () => Navigator.pop(context)),
                      Text(widget.surah.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF121A17))),
                      const SizedBox(width: 48),
                    ],
                  ),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: List.generate(dotCount, (i) {
                      final active = i == activeDot;
                      final done = i < activeDot;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: active ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: active ? const Color(0xFFC9A227) : (done ? const Color(0xFF0B3D2E) : const Color(0x260B3D2E)),
                        ),
                      );
                    }),
                  ),
                  if (widget.surah.num != 1 && widget.surah.num != 9)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 24, color: Color(0x880B3D2E))),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                itemCount: (_mushafMode || _peekText) ? total : (_ayahIdx + 1),
                itemBuilder: (_, i) {
                  final a = widget.surah.ayahs[i];
                  if (_mushafMode || _peekText || _doneAyahs.contains(i)) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('${a.text} ﴿${a.num}﴾', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'AmiriQuran', fontSize: _fontSize, height: 2.1, color: const Color(0xFF121A17))),
                    );
                  }
                  final words = a.text.split(RegExp(r'\s+'));
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 8,
                      children: [
                        for (var wi = 0; wi < words.length; wi++)
                          if (wi < _revealedWords)
                            Text(words[wi], style: TextStyle(fontFamily: 'AmiriQuran', fontSize: _fontSize, color: const Color(0xFF121A17)))
                          else if (wi == _revealedWords && _firstLetterHint)
                            Text(_firstLetter(words[wi]), style: TextStyle(fontFamily: 'AmiriQuran', fontSize: _fontSize, color: const Color(0xFFC9A227)))
                          else
                            Container(
                              width: 44,
                              height: 10,
                              margin: const EdgeInsets.only(top: 18),
                              decoration: BoxDecoration(
                                color: (wi == _revealedWords && _errorWord) ? const Color(0x55C9A227) : const Color(0x140B3D2E),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                        Text('﴿${a.num}﴾', style: TextStyle(fontFamily: 'AmiriQuran', fontSize: _fontSize * 0.72, color: const Color(0xFFC9A227))),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Color(0x140B3D2E), blurRadius: 24, offset: Offset(0, -6))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => setState(() => _peekText = !_peekText),
                        child: Row(children: [
                          Icon(_peekText ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: const Color(0xFF0B3D2E)),
                          const SizedBox(width: 4),
                          Text(_peekText ? 'إخفاء النص' : 'أظهر النص', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0B3D2E))),
                        ]),
                      ),
                      IconButton(icon: Icon(Icons.menu_book_outlined, size: 20, color: _mushafMode ? const Color(0xFFC9A227) : const Color(0xFF0B3D2E)), onPressed: () => setState(() => _mushafMode = !_mushafMode)),
                      InkWell(onTap: () => setState(() => _fontSize = _fontSize >= 36 ? 26 : _fontSize + 4), child: const Padding(padding: EdgeInsets.all(6), child: Text('TT', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B3D2E))))),
                      InkWell(
                        onTap: () => setState(() => _paused = !_paused),
                        child: Row(children: [
                          Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 18, color: const Color(0xFF0B3D2E)),
                          const SizedBox(width: 4),
                          Text(_paused ? 'استئناف' : 'إيقاف مؤقت', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0B3D2E))),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_fmtTime(_seconds), style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('${_ayahIdx + 1} من $total', style: const TextStyle(fontSize: 12, color: Color(0xFF5C6963))),
                          InkWell(
                            onTap: () {
                              if (_ayahIdx < total - 1) setState(() { _ayahIdx++; _revealedWords = 0; _firstLetterHint = false; _errorWord = false; });
                              else _finishSession();
                            },
                            child: const Padding(padding: EdgeInsets.only(top: 4), child: Text('تخطّ الآية', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0B3D2E)))),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _toggleOrb,
                        child: RotationTransition(
                          turns: _orbCtrl,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(colors: [Color(0xFF0B3D2E), Color(0xFF167A5C), Color(0xFFC9A227), Color(0xFF136B50), Color(0xFF0B3D2E)]),
                              boxShadow: [BoxShadow(color: Color(0x330B3D2E), blurRadius: 20)],
                            ),
                            child: Center(child: Icon(_listening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 30)),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _firstLetterHint = true),
                        child: const Row(children: [
                          Icon(Icons.lightbulb_outline_rounded, size: 18, color: Color(0xFFC9A227)),
                          SizedBox(width: 4),
                          Text('أول\nحرف', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0B3D2E))),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(onPressed: () => _revealWords(1), child: const Text('كلمة (+1)', style: TextStyle(fontSize: 11))),
                      const SizedBox(width: 6),
                      OutlinedButton(onPressed: () => _revealWords(99), child: const Text('آية كاملة', style: TextStyle(fontSize: 11))),
                      const SizedBox(width: 6),
                      OutlinedButton(onPressed: _onLahn, child: const Text('لحن', style: TextStyle(fontSize: 11))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('ينتهي وحده عند آخر آية، أو المس الدائرة', style: TextStyle(fontSize: 11, color: Color(0xFF5C6963))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FajrModeScreen extends StatefulWidget {
  final SurahModel surah;
  final FlutterTts tts;
  const FajrModeScreen({super.key, required this.surah, required this.tts});
  @override
  State<FajrModeScreen> createState() => _FajrModeScreenState();
}

class _FajrModeScreenState extends State<FajrModeScreen> {
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    widget.tts.speak('أهلًا بك في وضع الفجر. أغمض عينيك وابدأ تسميع ${widget.surah.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('وضع الفجر • صوت فقط', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('خروج', style: TextStyle(color: Colors.white54))),
                ],
              ),
              Column(
                children: [
                  Text('${widget.surah.name} • آية ${_idx + 1}', style: const TextStyle(color: Colors.white38, fontSize: 13)),
                  const SizedBox(height: 24),
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x66C9A227), width: 2)),
                    child: const Icon(Icons.mic_rounded, size: 46, color: Color(0x88C9A227)),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFC9A227), side: const BorderSide(color: Colors.white24)),
                        onPressed: () { setState(() => _idx = (_idx + 1) % widget.surah.ayahs.length); widget.tts.speak('أحسنت، كمّل'); },
                        child: const Text('صحيح (كمّل)'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white60, side: const BorderSide(color: Colors.white24)),
                        onPressed: () => widget.tts.speak('وقف، عيد الآية. ${widget.surah.ayahs[_idx].text}'),
                        child: const Text('خطأ (عيد الآية)'),
                      ),
                    ],
                  ),
                ],
              ),
              const Text('شاشة سوداء بالكامل لراحة العين وقت الفجر', style: TextStyle(color: Colors.white24, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
