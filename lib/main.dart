import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const TurboRacingApp());
}

class TurboRacingApp extends StatelessWidget {
  const TurboRacingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Turbo Racing',
      theme: ThemeData.dark(useMaterial3: true),
      home: const RacingScreen(),
    );
  }
}

class RoadObject {
  RoadObject({required this.lane, required this.progress, required this.coin});
  int lane;
  double progress;
  bool coin;
}

class RacingScreen extends StatefulWidget {
  const RacingScreen({super.key});

  @override
  State<RacingScreen> createState() => _RacingScreenState();
}

class _RacingScreenState extends State<RacingScreen> {
  final math.Random random = math.Random();
  final List<RoadObject> objects = [];
  Timer? timer;
  double carLane = 0;
  double speed = 0.55;
  double roadScroll = 0;
  double nitro = 1;
  int score = 0;
  int seconds = 90;
  int passed = 0;
  bool running = false;
  bool paused = false;
  bool finished = false;
  bool nitroActive = false;
  DateTime lastTick = DateTime.now();

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startGame() {
    timer?.cancel();
    setState(() {
      carLane = 0;
      speed = 0.55;
      roadScroll = 0;
      nitro = 1;
      score = 0;
      seconds = 90;
      passed = 0;
      objects.clear();
      running = true;
      paused = false;
      finished = false;
      nitroActive = false;
      lastTick = DateTime.now();
    });
    timer = Timer.periodic(const Duration(milliseconds: 40), (_) => tick());
  }

  void tick() {
    if (!mounted || !running || paused || finished) return;
    final now = DateTime.now();
    final dt = (now.difference(lastTick).inMilliseconds / 1000).clamp(0.01, 0.08);
    lastTick = now;
    setState(() {
      roadScroll = (roadScroll + dt * (nitroActive ? 1.6 : speed)) % 1;
      if (nitroActive) {
        nitro = (nitro - dt * 0.22).clamp(0, 1);
        if (nitro <= 0) nitroActive = false;
      } else {
        nitro = (nitro + dt * 0.025).clamp(0, 1);
      }

      if (random.nextDouble() < dt * 1.15) {
        objects.add(RoadObject(
          lane: random.nextInt(3) - 1,
          progress: 0,
          coin: random.nextDouble() < 0.42,
        ));
      }

      for (final obj in objects) {
        obj.progress += dt * (nitroActive ? 0.47 : 0.31 + speed * 0.22);
        if (obj.progress > 0.82 && obj.progress < 0.94 && obj.lane == carLane.round()) {
          if (obj.coin) {
            score += 100;
            obj.progress = 1.2;
          } else {
            score = math.max(0, score - 50);
            speed = math.max(0.25, speed - 0.15);
            obj.progress = 1.2;
          }
        }
      }
      final before = objects.length;
      objects.removeWhere((o) => o.progress > 1.08);
      passed += before - objects.length;
      if (speed < 0.78) speed += dt * 0.012;
      if (now.second != lastTick.second) {
        // The race timer is updated separately by elapsed whole seconds below.
      }
      seconds = 90 - (DateTime.now().difference(startTime).inSeconds);
      if (seconds <= 0 || passed >= 30) {
        seconds = math.max(0, seconds);
        running = false;
        finished = true;
        timer?.cancel();
      }
    });
  }

  DateTime startTime = DateTime.now();

  void beginRace() {
    startTime = DateTime.now();
    startGame();
  }

  void moveCar(double direction) {
    if (!running || paused || finished) return;
    setState(() => carLane = (carLane + direction).clamp(-1, 1));
  }

  void useNitro() {
    if (running && !paused && nitro >= 0.2) {
      setState(() {
        nitroActive = true;
        nitro = (nitro - 0.2).clamp(0, 1);
        speed = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: RacingPainter(
                lane: carLane,
                scroll: roadScroll,
                objects: objects,
                nitro: nitroActive,
              ),
            ),
            Positioned(
              top: 10, left: 14,
              child: _glassPanel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('TURBO RACING', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.cyanAccent)),
                  const SizedBox(height: 4),
                  Text('PUNTOS  $score   •   TIEMPO  ${seconds}s', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  SizedBox(width: 155, child: LinearProgressIndicator(value: nitro, color: Colors.orangeAccent, backgroundColor: Colors.white24)),
                  const Text('NITRO', style: TextStyle(fontSize: 10, color: Colors.orangeAccent)),
                ]),
              ),
            ),
            Positioned(
              top: 10, right: 14,
              child: Row(children: [
                _smallButton('Ⅱ', () => setState(() => paused = !paused), color: Colors.white),
                const SizedBox(width: 8),
                _smallButton('↻', beginRace, color: Colors.cyanAccent),
              ]),
            ),
            Positioned(
              left: 16, bottom: 16,
              child: Row(children: [
                _controlButton('◀', () => moveCar(-1), color: const Color(0xFF0C253D)),
                const SizedBox(width: 12),
                _controlButton('▶', () => moveCar(1), color: const Color(0xFF0C253D)),
              ]),
            ),
            Positioned(
              right: 16, bottom: 16,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _controlButton('NITRO ⚡', useNitro, color: const Color(0xFF8B3100), wide: true),
                const SizedBox(height: 8),
                Row(children: [
                  _smallButton('−', () => setState(() => speed = (speed - 0.1).clamp(0.25, 1)), color: Colors.white),
                  const SizedBox(width: 8),
                  _smallButton('+', () => setState(() => speed = (speed + 0.1).clamp(0.25, 0.9)), color: Colors.white),
                ]),
                const Text('VELOCIDAD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ]),
            ),
            if (!running || paused || finished)
              Container(
                color: Colors.black.withOpacity(0.72),
                child: Center(
                  child: Container(
                    width: math.min(440, constraints.maxWidth * 0.75),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF102A43), Color(0xFF07111F)]),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.7), width: 2),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24)],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        finished ? '¡CARRERA TERMINADA!' : paused ? 'PAUSA' : 'TURBO RACING',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.cyanAccent),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        finished ? 'Puntuación: $score puntos' : 'Pisa el acelerador. Esquiva los obstáculos y recoge monedas.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {
                          if (paused && !finished) {
                            setState(() => paused = false);
                            lastTick = DateTime.now();
                          } else {
                            beginRace();
                          }
                        },
                        icon: const Icon(Icons.flag),
                        label: Text(paused && !finished ? 'CONTINUAR' : finished ? 'VOLVER A CORRER' : 'INICIAR CARRERA'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                      ),
                    ]),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _glassPanel({required Widget child}) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xDD06111E), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white24)),
    child: child,
  );

  Widget _smallButton(String label, VoidCallback action, {required Color color}) => SizedBox(
    height: 42,
    child: FilledButton(
      onPressed: action,
      style: FilledButton.styleFrom(backgroundColor: const Color(0xDD081827), foregroundColor: color, side: const BorderSide(color: Colors.white30), padding: const EdgeInsets.symmetric(horizontal: 14)),
      child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ),
  );

  Widget _controlButton(String label, VoidCallback action, {required Color color, bool wide = false}) => SizedBox(
    height: 54,
    width: wide ? 126 : 62,
    child: FilledButton(
      onPressed: action,
      style: FilledButton.styleFrom(backgroundColor: color.withOpacity(0.94), foregroundColor: Colors.white, side: const BorderSide(color: Colors.cyanAccent, width: 1.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
    ),
  );
}

class RacingPainter extends CustomPainter {
  RacingPainter({required this.lane, required this.scroll, required this.objects, required this.nitro});
  final double lane;
  final double scroll;
  final List<RoadObject> objects;
  final bool nitro;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sky = Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF06142C), Color(0xFF154A70), Color(0xFF6F9F9A)],
    ).createShader(Rect.fromLTWH(0, 0, w, h * 0.7));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sky);

    final sun = Paint()..color = const Color(0xFFFFD28A).withOpacity(0.8);
    canvas.drawCircle(Offset(w * 0.78, h * 0.20), h * 0.075, sun);

    final mountain = Paint()..color = const Color(0xFF142F43);
    final mountain2 = Paint()..color = const Color(0xFF20495A);
    final m1 = Path()..moveTo(0, h * .56)..lineTo(w*.12,h*.25)..lineTo(w*.22,h*.52)..lineTo(w*.36,h*.28)..lineTo(w*.49,h*.55)..lineTo(w*.65,h*.31)..lineTo(w*.79,h*.55)..lineTo(w*.91,h*.27)..lineTo(w,h*.53)..lineTo(w,h*.65)..lineTo(0,h*.65)..close();
    canvas.drawPath(m1, mountain);
    final m2 = Path()..moveTo(0,h*.59)..lineTo(w*.18,h*.39)..lineTo(w*.31,h*.57)..lineTo(w*.47,h*.37)..lineTo(w*.61,h*.59)..lineTo(w*.77,h*.4)..lineTo(w,h*.6)..lineTo(w,h*.7)..lineTo(0,h*.7)..close();
    canvas.drawPath(m2, mountain2);

    canvas.drawRect(Rect.fromLTWH(0, h*.57, w, h*.43), Paint()..color = const Color(0xFF23503D));

    final roadTopY = h * .37;
    final roadBottomY = h * 1.08;
    final topLeft = w * .42;
    final topRight = w * .58;
    final bottomLeft = -w * .08;
    final bottomRight = w * 1.08;
    final road = Path()
      ..moveTo(topLeft, roadTopY)..lineTo(topRight, roadTopY)
      ..lineTo(bottomRight, roadBottomY)..lineTo(bottomLeft, roadBottomY)..close();
    canvas.drawPath(road, Paint()..color = const Color(0xFF292F3A));

    final edgePaint = Paint()..color = const Color(0xFFFFD54F)..strokeWidth = 5..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(topLeft, roadTopY), Offset(bottomLeft, roadBottomY), edgePaint);
    canvas.drawLine(Offset(topRight, roadTopY), Offset(bottomRight, roadBottomY), edgePaint);

    for (int i = 0; i < 2; i++) {
      final xTop = topLeft + (topRight - topLeft) * (i + 1) / 3;
      final xBottom = bottomLeft + (bottomRight - bottomLeft) * (i + 1) / 3;
      for (int j = 0; j < 9; j++) {
        final p = ((j / 9) + scroll) % 1;
        final y = roadTopY + (roadBottomY - roadTopY) * p * p;
        final x = xTop + (xBottom - xTop) * p * p;
        final dashH = 2 + p * 20;
        final dashW = 1 + p * 5;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: dashW, height: dashH), Radius.circular(dashW)),
          Paint()..color = Colors.white.withOpacity(0.85),
        );
      }
    }

    // Carretera con marcas de velocidad al activar el nitro.
    if (nitro) {
      final streak = Paint()..color = Colors.cyanAccent.withOpacity(.55)..strokeWidth = 2;
      for (int i = 0; i < 12; i++) {
        final x = w * ((i * 0.173 + scroll) % 1);
        canvas.drawLine(Offset(x, h*.62), Offset(x - 18, h*.88), streak);
      }
    }

    for (final obj in objects) {
      final p = obj.progress.clamp(0.0, 1.0);
      final y = roadTopY + (roadBottomY - roadTopY) * p * p;
      final left = topLeft + (bottomLeft - topLeft) * p * p;
      final right = topRight + (bottomRight - topRight) * p * p;
      final x = left + (right-left) * ((obj.lane + 1.5) / 3);
      final r = 5 + p * 26;
      if (obj.coin) {
        canvas.drawCircle(Offset(x,y), r, Paint()..color = const Color(0xFFFFC928));
        canvas.drawCircle(Offset(x,y), r*.68, Paint()..color = const Color(0xFFFFF2A3));
        final tp = TextPainter(text: const TextSpan(text: '\$', style: TextStyle(color: Color(0xFF7A4300), fontSize: 16, fontWeight: FontWeight.w900)), textDirection: TextDirection.ltr)..layout();
        tp.paint(canvas, Offset(x-tp.width/2,y-tp.height/2));
      } else {
        final rect = Rect.fromCenter(center: Offset(x,y), width: r*1.5, height: r*1.9);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r*.25)), Paint()..color = const Color(0xFFEA3D49));
        canvas.drawRect(Rect.fromLTWH(rect.left+r*.2, rect.top+r*.3, rect.width-r*.4, rect.height*.25), Paint()..color = const Color(0xFFFFF0C2));
        canvas.drawCircle(Offset(rect.left+r*.3,rect.bottom-r*.15),r*.18,Paint()..color=Colors.black);
        canvas.drawCircle(Offset(rect.right-r*.3,rect.bottom-r*.15),r*.18,Paint()..color=Colors.black);
      }
    }

    // Auto deportivo del jugador, con carrocería, parabrisas, faros y ruedas.
    final carX = w * (0.5 + lane * 0.115);
    final carY = h * .79;
    final carW = h * .22;
    final carH = h * .29;
    final shadow = Paint()..color = Colors.black.withOpacity(.4);
    canvas.drawOval(Rect.fromCenter(center: Offset(carX,carY+carH*.4),width:carW*1.2,height:carH*.25),shadow);
    final body = Path()
      ..moveTo(carX-carW*.48,carY+carH*.42)
      ..lineTo(carX-carW*.38,carY-carH*.15)
      ..lineTo(carX-carW*.22,carY-carH*.48)
      ..quadraticBezierTo(carX,carY-carH*.58,carX+carW*.22,carY-carH*.48)
      ..lineTo(carX+carW*.38,carY-carH*.15)
      ..lineTo(carX+carW*.48,carY+carH*.42)
      ..quadraticBezierTo(carX,carY+carH*.55,carX-carW*.48,carY+carH*.42)
      ..close();
    canvas.drawPath(body, Paint()..shader=const LinearGradient(colors:[Color(0xFF00D9FF),Color(0xFF0066CC),Color(0xFF042C66)]).createShader(Rect.fromCenter(center:Offset(carX,carY),width:carW,height:carH)));
    final glass = Path()
      ..moveTo(carX-carW*.25,carY-carH*.18)
      ..lineTo(carX-carW*.15,carY-carH*.39)
      ..quadraticBezierTo(carX,carY-carH*.46,carX+carW*.15,carY-carH*.39)
      ..lineTo(carX+carW*.25,carY-carH*.18)
      ..close();
    canvas.drawPath(glass, Paint()..color=const Color(0xFFB9F6FF));
    final wheel = Paint()..color=const Color(0xFF090D14);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(carX-carW*.43,carY+carH*.18),width:carW*.19,height:carH*.43),const Radius.circular(5)),wheel);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(carX+carW*.43,carY+carH*.18),width:carW*.19,height:carH*.43),const Radius.circular(5)),wheel);
    final lights = Paint()..color=const Color(0xFFFFFFB3)..maskFilter=const MaskFilter.blur(BlurStyle.normal,5);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(carX-carW*.27,carY+carH*.33),width:carW*.18,height:carH*.07),const Radius.circular(3)),lights);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(carX+carW*.27,carY+carH*.33),width:carW*.18,height:carH*.07),const Radius.circular(3)),lights);
  }

  @override
  bool shouldRepaint(covariant RacingPainter oldDelegate) => true;
}
