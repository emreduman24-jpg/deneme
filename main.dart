import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const UnderworldOrderApp());
}

class UnderworldOrderApp extends StatelessWidget {
  const UnderworldOrderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Underworld & Order',
      home: const GameScreen(),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Montserrat', // Google Fonts hissi için modern görünüm
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Random _rng = Random();

  bool _isDay = true;

  int _cash = 120;
  int _health = 100;
  int _respect = 15;

  final List<String> _logs = <String>[
    'Yeni hayatına hoş geldin! Gündüz patron, gece gölge kralı...'
  ];

  List<_GameAction> get _dayActions => <_GameAction>[
        _GameAction(
          title: 'Fabrikada Çalış',
          subtitle: 'Güvenli gelir',
          icon: Icons.factory,
          onExecute: _workAtFactory,
        ),
        _GameAction(
          title: 'Kitap Oku (Zeka)',
          subtitle: 'Akla yatırım',
          icon: Icons.menu_book_rounded,
          onExecute: _readBook,
        ),
        _GameAction(
          title: 'Spor Yap (Güç)',
          subtitle: 'Canını kuvvetlendir',
          icon: Icons.fitness_center,
          onExecute: _workout,
        ),
        _GameAction(
          title: 'Borsa Takip',
          subtitle: 'Risk/Ödül',
          icon: Icons.candlestick_chart,
          onExecute: _followMarket,
        ),
      ];

  List<_GameAction> get _nightActions => <_GameAction>[
        _GameAction(
          title: 'Sokak Soygunu',
          subtitle: 'Düşük risk',
          icon: Icons.mask,
          onExecute: _streetRobbery,
        ),
        _GameAction(
          title: 'Banka Soygunu',
          subtitle: 'Yüksek risk',
          icon: Icons.account_balance,
          onExecute: _bankRobbery,
        ),
        _GameAction(
          title: 'Yeraltı Kumarı',
          subtitle: 'Şansına güven',
          icon: Icons.casino,
          onExecute: _undergroundGamble,
        ),
        _GameAction(
          title: 'Haraç Topla',
          subtitle: 'Tehlikeli itibar',
          icon: Icons.local_police_outlined,
          onExecute: _collectTribute,
        ),
      ];

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, message);
      if (_logs.length > 40) {
        _logs.removeLast();
      }
    });
  }

  void _changeStats({
    int cashDelta = 0,
    int healthDelta = 0,
    int respectDelta = 0,
  }) {
    setState(() {
      _cash = max(0, _cash + cashDelta);
      _health = (_health + healthDelta).clamp(-999, 100);
      _respect = max(0, _respect + respectDelta);
    });
    _checkGameOver();
  }

  Future<void> _checkGameOver() async {
    if (_health > 0 || !mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hastanelik oldun!'),
          content: const Text(
            'Acil serviste uyandın. Doktor dedi ki: "Bir süre suçtan uzak dur!"\n\nOyun sıfırlanıyor...',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tekrar Başla'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    setState(() {
      _isDay = true;
      _cash = 120;
      _health = 100;
      _respect = 15;
      _logs
        ..clear()
        ..add('Yeni tur başladı. Bu sefer biraz daha dikkatli ol!');
    });
  }

  void _workAtFactory() {
    final int earned = 18 + _rng.nextInt(23);
    _changeStats(cashDelta: earned, respectDelta: 1);
    _addLog('Mesai bitti. Patron senden memnun! +\$$earned Nakit, +1 Saygınlık');
  }

  void _readBook() {
    final int boost = 2 + _rng.nextInt(4);
    _changeStats(respectDelta: boost);
    _addLog('Kahveni alıp kitap gömdün. Beyin kasların +$boost Saygınlık kazandı.');
  }

  void _workout() {
    final int heal = 8 + _rng.nextInt(8);
    _changeStats(healthDelta: heal, respectDelta: 1);
    _addLog('Spor yaptın, aynaya bakınca özgüven geldi. +$heal Can, +1 Saygınlık');
  }

  void _followMarket() {
    final bool gain = _rng.nextBool();
    if (gain) {
      final int earned = 15 + _rng.nextInt(35);
      _changeStats(cashDelta: earned, respectDelta: 2);
      _addLog('Borsada doğru hamle! +\$$earned Nakit, +2 Saygınlık');
    } else {
      final int lost = 10 + _rng.nextInt(25);
      _changeStats(cashDelta: -lost, respectDelta: -1);
      _addLog('Grafiğe fazla güvendin, kırmızı mumlar can sıktı. -\$$lost Nakit, -1 Saygınlık');
    }
  }

  void _streetRobbery() {
    final int roll = _rng.nextInt(100);
    if (roll < 20) {
      final int damage = 8 + _rng.nextInt(10);
      _changeStats(healthDelta: -damage, respectDelta: -1);
      _addLog('Palyaçoyu soymaya çalıştın ama sana pastayla vurdu. -$damage Can');
    } else {
      final int earned = 20 + _rng.nextInt(35);
      _changeStats(cashDelta: earned, respectDelta: 2);
      _addLog('Sokak turu verimli geçti. +\$$earned Nakit, +2 Saygınlık');
    }
  }

  void _bankRobbery() {
    final bool caught = _rng.nextInt(100) < 40; // %40 yakalanma
    if (caught) {
      final int cashLoss = 25 + _rng.nextInt(40);
      final int damage = 18 + _rng.nextInt(18);
      _changeStats(cashDelta: -cashLoss, healthDelta: -damage, respectDelta: -3);
      _addLog(
        'Alarm çaldı! Kaçarken turnikeye takıldın. -\$$cashLoss Nakit, -$damage Can, -3 Saygınlık',
      );
    } else {
      final int earned = 120 + _rng.nextInt(120);
      _changeStats(cashDelta: earned, respectDelta: 5);
      _addLog('Kasa açıldı, gece senin gecen! +\$$earned Nakit, +5 Saygınlık');
    }
  }

  void _undergroundGamble() {
    final int roll = _rng.nextInt(100);
    if (roll < 45) {
      final int lost = 12 + _rng.nextInt(30);
      _changeStats(cashDelta: -lost);
      _addLog('Rulette top sıfıra kaçtı. -\$$lost Nakit');
    } else {
      final int won = 20 + _rng.nextInt(45);
      _changeStats(cashDelta: won, respectDelta: 1);
      _addLog('Kartlar bu gece senden yana! +\$$won Nakit, +1 Saygınlık');
    }
  }

  void _collectTribute() {
    final int roll = _rng.nextInt(100);
    if (roll < 30) {
      final int damage = 10 + _rng.nextInt(12);
      _changeStats(healthDelta: -damage, cashDelta: 8, respectDelta: -1);
      _addLog('Esnaf "bugün yok" dedi, tartışma büyüdü. +\$8 Nakit, -$damage Can');
    } else {
      final int earned = 35 + _rng.nextInt(35);
      _changeStats(cashDelta: earned, respectDelta: 3);
      _addLog('Mahalle sessizce payını ödedi. +\$$earned Nakit, +3 Saygınlık');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = _isDay ? const Color(0xFFF3F5F9) : const Color(0xFF0A0E1A);
    final Color cardColor = _isDay ? Colors.white : const Color(0xFF141A2B);
    final Color textColor = _isDay ? const Color(0xFF1D2433) : const Color(0xFFE8ECFF);
    final Color accent = _isDay ? const Color(0xFF0C8BA8) : const Color(0xFFE61E6E);
    final Color secondaryAccent = _isDay ? const Color(0xFF1976D2) : const Color(0xFF8B5CF6);

    final List<_GameAction> actions = _isDay ? _dayActions : _nightActions;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          color: bgColor,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            children: <Widget>[
              _buildHeader(textColor, accent, secondaryAccent),
              const SizedBox(height: 10),
              _buildStats(textColor, cardColor, accent),
              const SizedBox(height: 10),
              Expanded(
                flex: 4,
                child: GridView.builder(
                  itemCount: actions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.25,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final _GameAction action = actions[index];
                    return _buildActionCard(
                      action: action,
                      cardColor: cardColor,
                      textColor: textColor,
                      accent: accent,
                      secondaryAccent: secondaryAccent,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              _buildLogPanel(textColor, cardColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color accent, Color secondaryAccent) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Underworld & Order',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Icon(
          _isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round,
          color: _isDay ? secondaryAccent : accent,
        ),
        Switch(
          value: _isDay,
          activeColor: secondaryAccent,
          inactiveThumbColor: accent,
          onChanged: (bool value) {
            setState(() {
              _isDay = value;
            });
            _addLog(value
                ? 'Kravatı taktın, gündüz mesaisi başladı.'
                : 'Kravat çıktı, yeraltı mesaisi aktif.');
          },
        ),
      ],
    );
  }

  Widget _buildStats(Color textColor, Color cardColor, Color accent) {
    return Card(
      color: cardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _statItem('💵 Nakit', '\$$_cash', textColor, accent),
            _statItem('❤️ Sağlık', '$_health', textColor, accent),
            _statItem('⭐ Saygınlık', '$_respect', textColor, accent),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color textColor, Color accent) {
    return Column(
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: textColor.withOpacity(0.85),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: accent,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required _GameAction action,
    required Color cardColor,
    required Color textColor,
    required Color accent,
    required Color secondaryAccent,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: action.onExecute,
      child: Card(
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                accent.withOpacity(0.16),
                secondaryAccent.withOpacity(0.11),
              ],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(action.icon, size: 34, color: accent),
              const SizedBox(height: 10),
              Text(
                action.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                action.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogPanel(Color textColor, Color cardColor) {
    return Expanded(
      flex: 3,
      child: Card(
        color: cardColor,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Olay Günlüğü',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.separated(
                    itemCount: _logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (BuildContext context, int index) {
                      return Text(
                        '• ${_logs[index]}',
                        style: TextStyle(
                          color: textColor.withOpacity(0.88),
                          height: 1.3,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameAction {
  const _GameAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onExecute,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onExecute;
}
