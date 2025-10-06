import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: BarebonesSpooky()));

class BarebonesSpooky extends StatefulWidget {
  const BarebonesSpooky({super.key});
  @override
  State<BarebonesSpooky> createState() => _BarebonesSpookyState();
}

class _BarebonesSpookyState extends State<BarebonesSpooky> {
  final _rng = Random();
  late List<_Item> items;
  Timer? _timer;
  bool _flash = false;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    items = [
      _Item('🎃', isGoal: true, size: 56),
      _Item('👻', isGoal: false, size: 50),
      _Item('🦇', isGoal: false, size: 46),
      _Item('🕷️', isGoal: false, size: 42),
    ];
    for (final it in items) {
      it.next = _randPos();
      it.durMs = 900 + _rng.nextInt(900);
    }
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        for (final it in items) {
          it.next = _randPos();
          it.durMs = 800 + _rng.nextInt(1200);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
        it.durMs = 900 + _rng.nextInt(900);
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
          top: 16, left: 0, right: 0,
          child: Column(
            children: [
              Text('Find the 🎃',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, color: Colors.orangeAccent, fontWeight: FontWeight.w800)),
              SizedBox(height: 6),
              Text('Tap carefully—some are traps!',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),


        ...items.map((it) {
          final left = it.next.dx * w;
          final top  = it.next.dy * h;
          return AnimatedPositioned(
            duration: Duration(milliseconds: it.durMs),
            curve: Curves.easeInOut,
            left: left, top: top,
            child: GestureDetector(
              onTap: () => _tap(it),
              child: Text(it.emoji, style: TextStyle(
                fontSize: it.size,
                shadows: const [Shadow(blurRadius: 8, color: Colors.deepOrange)],
              )),
            ),
          );
        }),


        if (_flash)
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: 0.55,
              duration: const Duration(milliseconds: 100),
              child: Container(color: Colors.redAccent.withOpacity(0.6)),
            ),
          ),


        if (_won)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('You Found It!',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.orange)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.replay),
                    label: const Text('Play Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
                  )
                ]),
              ),
            ),
          ),
      ]);
    });
  }
}

class _Item {
  _Item(this.emoji, {required this.isGoal, required this.size});
  final String emoji;
  final bool isGoal;
  final double size;
  Offset next = const Offset(0.5, 0.5);
  int durMs = 1000;
}
