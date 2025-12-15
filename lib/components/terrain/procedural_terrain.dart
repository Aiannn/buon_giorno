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
    this.stepX = 16.0, // дискретизация (чем меньше — тем плавнее/дороже)
    this.baseY = 660.0,
    this.ampBase = 120.0, // базовая амплитуда холмов
    this.maxSlopeDeg = 22.0, // ≈ комфортный предел для езды
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
    final n = (length / stepX).ceil();
    final pts = <Vector2>[];
    final maxDy = math.tan(maxSlopeDeg * math.pi / 180.0) * stepX;
    final maxDTheta =
        maxCurvDeg * math.pi / 180.0; // ограничение изменения угла

    double lastY = baseY;
    double lastTheta = 0.0; // угол между сегментами

    // редкие “события”: плато / расширенные ямы
    // генерим envelope: [-1..1] → [0..1], сглаживающий амплитуду
    double _envelope(double x) {
      final e = 0.5 + 0.5 * _pEvt.getNoise2(x, 0.0);
      // чуть поджимаем края, чтобы реже были экстремумы
      return 0.2 + 0.8 * e;
    }

    for (int i = 0; i <= n; i++) {
      final x = startX + i * stepX;

      // амплитуда варьируется медленно — «участки сложности»
      final amp = ampBase * (0.6 + 0.8 * _envelope(x));

      // базовая форма: длинная волна + мелкая "шероховатость"
      final yLong = amp * _pLong.getNoise2(x, 0.0);
      final yMid = 0.45 * amp * _pMid.getNoise2(x, 1000.0);
      final yFine = 0.18 * amp * _pFine.getNoise2(x, -1000.0);

      // редкие плато: когда envelope низкий — приглушаем производные
      double yRaw = baseY + (yLong + yMid + yFine);

      // slope clamp
      double y = yRaw;
      if (i > 0) {
        double dy = yRaw - lastY;
        if (dy > maxDy) y = lastY + maxDy;
        if (dy < -maxDy) y = lastY - maxDy;

        // curvature clamp: ограничиваем изменение угла между сегментами
        final theta = math.atan2(y - lastY, stepX);
        double dTheta = theta - lastTheta;
        // нормализуем к [-pi, pi]
        dTheta = (dTheta + math.pi) % (2 * math.pi) - math.pi;
        if (dTheta > maxDTheta) {
          // «сгладим» текущую точку по допустимой кривизне
          final limited = lastTheta + maxDTheta;
          final dyAllowed = math.tan(limited) * stepX;
          y = lastY + dyAllowed;
          lastTheta = limited;
        } else if (dTheta < -maxDTheta) {
          final limited = lastTheta - maxDTheta;
          final dyAllowed = math.tan(limited) * stepX;
          y = lastY + dyAllowed;
          lastTheta = limited;
        } else {
          lastTheta = theta;
        }
      }
      lastY = y;

      pts.add(Vector2(x, y));
    }

    // лёгкое упрощение, чтобы уменьшить кол-во рёбер
    return _simplifyByDelta(pts, delta: 0.6);
  }

  List<Vector2> _simplifyByDelta(List<Vector2> src, {required double delta}) {
    if (src.length < 3) return src;
    final out = <Vector2>[src.first];
    for (int i = 1; i < src.length - 1; i++) {
      final prev = out.last;
      final curr = src[i];
      final next = src[i + 1];
      final d = _pointSegmentDistance(curr, prev, next);
      if (d >= delta) out.add(curr);
    }
    out.add(src.last);
    return out;
  }

  double _pointSegmentDistance(Vector2 p, Vector2 a, Vector2 b) {
    final ap = p - a;
    final ab = b - a;
    final t = (ap.dot(ab) / ab.length2).clamp(0.0, 1.0);
    final proj = a + ab * t;
    return (p - proj).length;
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
