import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: BarebonesSpooky()));

class BarebonesSpooky extends StatefulWidget {
  const BarebonesSpooky({super.key});
  @override
  State<BarebonesSpooky> createState() => _BarebonesSpookyState();
}

class _BarebonesSpookyState extends State<BarebonesSpooky> {
  final AudioPlayer _bgPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();

  final List<_LevelConfig> _levels = const [
    _LevelConfig(name: 'Level 1', traps: 5, retargetSec: 2.0, minMs: 900, maxMs: 1800),
    _LevelConfig(name: 'Level 2', traps: 15, retargetSec: 1.3, minMs: 600, maxMs: 1200),
    _LevelConfig(name: 'Level 3', traps: 100, retargetSec: 1.0, minMs: 400, maxMs: 900),
  ];

  @override
  void initState() {
    super.initState();
    _playBackgroundMusic();
  }

  @override
  void dispose() {
    _bgPlayer.dispose();
    _effectPlayer.dispose();
    super.dispose();
  }

  Future<void> _playBackgroundMusic() async {
    await _bgPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgPlayer.play(AssetSource('WGH.mp3'));
  }

  Future<void> _playScarySound() async {
    await _effectPlayer.play(AssetSource('bbc_screaming-_07034117.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      itemCount: _levels.length,
      itemBuilder: (_, i) => _LevelPage(
        config: _levels[i],
        onHelpPressed: _playScarySound, 
      ),
    );
  }
}

class _LevelPage extends StatefulWidget {
  const _LevelPage({required this.config, required this.onHelpPressed});
  final _LevelConfig config;
  final Future<void> Function() onHelpPressed;

  @override
  State<_LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<_LevelPage> {
  final _rng = Random();
  late List<_Item> items;
  Timer? _timer;
  bool _flash = false;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _buildItems();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _LevelPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _timer?.cancel();
      _won = false;
      _flash = false;
      _buildItems();
      _startTimer();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _buildItems() {
    final ghosts = ['👻','🦇','🕷️','☠️','🧙‍♀️','🧟‍♂️','🧛‍♀️','🧌','🪦'];
    items = [
      _Item('🎃', isGoal: true, size: 25.0),
      for (int i = 0; i < widget.config.traps; i++)
        _Item(ghosts[i % ghosts.length], isGoal: false, size: 42.0 + _rng.nextInt(12).toDouble()),
    ];
    for (final it in items) {
      it.next = _randPos();
      it.durMs = _randMs();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(
      Duration(milliseconds: (widget.config.retargetSec * 1000).round()),
      (_) {
        if (!mounted) return;
        setState(() {
          for (final it in items) {
            it.next = _randPos();
            it.durMs = _randMs();
          }
        });
      },
    );
  }

  int _randMs() => widget.config.minMs + _rng.nextInt(widget.config.maxMs - widget.config.minMs + 1);

  Offset _randPos() => Offset(
        0.08 + _rng.nextDouble() * 0.84,
        0.20 + _rng.nextDouble() * 0.70,
      );

  void _tap(_Item it) {
    if (_won) return;
    if (it.isGoal) {
      setState(() => _won = true);
    } else {
      setState(() => _flash = true);
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted) setState(() => _flash = false);
      });
    }
  }

  void _reset() {
    setState(() {
      _won = false;
      _flash = false;
      for (final it in items) {
        it.next = _randPos();
        it.durMs = _randMs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      return Stack(children: [
        Container(color: const Color(0xFF0E0E12)),

        const Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text(
                'Find the 🎃 — Swipe for more levels',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Tap carefully—some are traps!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),

        // moving items
        ...items.map((it) {
          final left = it.next.dx * w;
          final top = it.next.dy * h;
          return AnimatedPositioned(
            duration: Duration(milliseconds: it.durMs),
            curve: Curves.easeInOut,
            left: left,
            top: top,
            child: GestureDetector(
              onTap: () => _tap(it),
              child: Text(
                it.emoji,
                style: TextStyle(
                  fontSize: it.size,
                  shadows: const [Shadow(blurRadius: 8, color: Colors.deepOrange)],
                ),
              ),
            ),
          );
        }),

        // red flash 
        if (_flash)
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: 0.55,
              duration: const Duration(milliseconds: 100),
              child: Container(color: Colors.redAccent.withOpacity(0.6)),
            ),
          ),

        // win screen
        if (_won)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text(
                    'You Found It!',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.orange),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.replay),
                    label: const Text('Play Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                    ),
                  )
                ]),
              ),
            ),
          ),

        // Help button
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            backgroundColor: Colors.redAccent,
            icon: const Icon(Icons.help_outline, color: Colors.white),
            label: const Text('Help', style: TextStyle(color: Colors.white)),
            onPressed: widget.onHelpPressed,
          ),
        ),
      ]);
    });
  }
}

class _LevelConfig {
  const _LevelConfig({
    required this.name,
    required this.traps,
    required this.retargetSec,
    required this.minMs,
    required this.maxMs,
  });
  final String name;
  final int traps;
  final double retargetSec; 
  final int minMs, maxMs;   
}

class _Item {
  _Item(this.emoji, {required this.isGoal, required this.size});
  final String emoji;
  final bool isGoal;
  final double size;
  Offset next = const Offset(0.5, 0.5);
  int durMs = 1000;
}
