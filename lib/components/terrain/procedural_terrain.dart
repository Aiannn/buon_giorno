import 'dart:math' as math;
import 'package:fast_noise/fast_noise.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';

/// Категория "земля" для фильтров/рейкастов/контактов
const int kGroundCat = 0x0002;

/// Процедурный чанк земли в стиле Hill Climb Racing:
/// - базовая длинная волна + 1–2 короткие “приправы”
/// - ограничение уклона (slope clamp) и кривизны (curvature clamp)
/// - редкие «плато» и мягкие впадины
/// - статическое твёрдое тело (ChainShape) + кэш Path для отрисовки
class ProceduralTerrain extends BodyComponent {
  ProceduralTerrain({
    this.startX = -600.0,
    this.length = 5000.0,
    this.stepX = 8.0, // дискретизация (чем меньше — тем плавнее/дороже)
    this.baseY = 660.0,
    this.ampBase = 500.0, // базовая амплитуда холмов
    this.maxSlopeDeg = 75.0, // ≈ комфортный предел для езды
    this.maxCurvDeg = 6.0, // предел изменения угла МЕЖДУ соседними сегментами
    this.friction = 0.95,
    this.color = const Color(0xFFE3D0AF),
    this.seed = 1337, // фиксируй для воспроизводимости
    this.debugRender = true, // показывать белую линию Box2D
  }) {
    renderBody = debugRender;
  }

  final double startX;
  final double length;
  final double stepX;
  final double baseY;
  final double ampBase;
  final double maxSlopeDeg;
  final double maxCurvDeg;
  final double friction;
  final Color color;
  final int seed;
  final bool debugRender;

  late final List<Vector2> _pts;
  Path? _cachedPath;
  late final Paint _paint = Paint()..color = color;

  // Перлин (детерминированно)
  late final PerlinNoise _pLong = PerlinNoise(
    seed: seed,
    frequency: 0.002,
  ); // длинные
  late final PerlinNoise _pMid = PerlinNoise(
    seed: seed ^ 11,
    frequency: 0.006,
  ); // средние
  late final PerlinNoise _pFine = PerlinNoise(
    seed: seed ^ 101,
    frequency: 0.014,
  ); // короткие
  late final PerlinNoise _pEvt = PerlinNoise(
    seed: seed ^ 777,
    frequency: 0.0006,
  ); // “события” (плато/ямы)

  @override
  Body createBody() {
    final b = world.createBody(BodyDef()..type = BodyType.static);

    _pts = _buildProfile();
    final chain = ChainShape()..createChain(_pts);
    b.createFixture(
      FixtureDef(chain)
        ..filter.categoryBits = kGroundCat
        ..filter.maskBits = 0xFFFF
        ..friction = friction
        ..restitution = 0.0,
    );

    _cachedPath = _buildFillPath(_pts);
    return b;
  }

  // === Публичное API ===

  double heightAt(double x) {
    if (_pts.isEmpty) return baseY;
    final i = ((x - startX) / stepX).floor();
    if (i <= 0) return _pts.first.y;
    if (i >= _pts.length - 1) return _pts.last.y;
    final p0 = _pts[i], p1 = _pts[i + 1];
    final t = ((x - p0.x) / (p1.x - p0.x)).clamp(0.0, 1.0);
    return p0.y + (p1.y - p0.y) * t;
  }

  Vector2 normalAt(double x) {
    final i = ((x - startX) / stepX).floor().clamp(1, _pts.length - 2);
    final p0 = _pts[i - 1], p1 = _pts[i + 1];
    final dx = p1.x - p0.x, dy = p1.y - p0.y;
    final n = Vector2(-dy, dx)..normalize();
    return n;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Земля статична — ничего не двигаем.
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas); // белая коллиз. линия, если renderBody=true
    final path = _cachedPath;
    if (path != null) canvas.drawPath(path, _paint);
  }

  // === Генерация профиля ===

  List<Vector2> _buildProfile() {
    final keyStep = 120.0; // шаг ключевых точек Perlin (в пикселях)
    final keyCount = (length / keyStep).ceil();
    final keyPoints = <Vector2>[];

    // 1. Константа максимального перепада (из тригонометрии: дельта Y = X * tg(угол))
    // Мы вычисляем это один раз вне цикла.
    final maxDeltaY = keyStep * math.tan(maxSlopeDeg * math.pi / 180.0);

    for (int i = 0; i <= keyCount; i++) {
      final x = startX + i * keyStep;

      // Генерируем "желаемую" высоту.
      // Frequency 0.001..0.002 дает классические холмы Hill Climb.
      final noiseVal =
          _pLong.getNoise2(x * 0.8, 0.0) +
          (_pMid.getNoise2(x * 1.5, 0.0) *
              0.2); // Добавляем немного мелких деталей

      double targetY = baseY + (ampBase * noiseVal);

      // 2. ПРИМЕНЯЕМ ГУАРДРАЙЛ (Вариант 1)
      if (i > 0) {
        final prevY = keyPoints[i - 1].y;
        // Ограничиваем targetY так, чтобы он не отклонялся от prevY больше чем на maxDeltaY
        targetY = targetY.clamp(prevY - maxDeltaY, prevY + maxDeltaY);
      }

      keyPoints.add(Vector2(x, targetY));
    }

    // 2. Сэмплируем Catmull-Rom сплайн с шагом stepX
    final pts = <Vector2>[];
    for (int i = 0; i < keyPoints.length - 1; i++) {
      final p0 = keyPoints[i > 0 ? i - 1 : i];
      final p1 = keyPoints[i];
      final p2 = keyPoints[i + 1];
      final p3 = keyPoints[i + 2 < keyPoints.length ? i + 2 : i + 1];
      // Уменьши шаг t (например, stepX / keyStep), чтобы точек было больше = выше плавность
      for (double t = 0; t < 1; t += stepX / keyStep) {
        pts.add(_catmullRom(p0, p1, p2, p3, t));
      }
    }
    pts.add(keyPoints.last);
    return pts;
  }

  Vector2 _catmullRom(
    Vector2 p0,
    Vector2 p1,
    Vector2 p2,
    Vector2 p3,
    double t,
  ) {
    // t in [0, 1]
    final t2 = t * t;
    final t3 = t2 * t;
    return Vector2(
      0.5 *
          ((2 * p1.x) +
              (-p0.x + p2.x) * t +
              (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 +
              (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3),
      0.5 *
          ((2 * p1.y) +
              (-p0.y + p2.y) * t +
              (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 +
              (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3),
    );
  }

  Path _buildFillPath(List<Vector2> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.x, pts.first.y);
    for (final p in pts) {
      path.lineTo(p.x, p.y);
    }
    // закрываем вниз для заливки
    final last = pts.last;
    final first = pts.first;
    final bottom = math.max(baseY + ampBase * 2, last.y + 500);
    path
      ..lineTo(last.x, bottom)
      ..lineTo(first.x, bottom)
      ..close();
    return path;
  }
}
