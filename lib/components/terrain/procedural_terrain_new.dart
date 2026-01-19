import 'dart:math' as math;
import 'package:buon_giorno/components/terrain/chunk_template.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';

const int kGroundCat = 0x0002;

class ProceduralTerrain extends BodyComponent {
  ProceduralTerrain({
    this.startX = 0.0,
    this.baseY = 700.0,
    this.stepX = 10.0, // Плотность точек для плавности сплайна
    this.color = const Color(0xFFE3D0AF),
    this.friction = 0.9,
  });

  final double startX;
  final double baseY;
  final double stepX;
  final Color color;
  final double friction;

  late final List<Vector2> _pts;
  Path? _cachedPath;
  late final Paint _paint = Paint()..color = color;

  @override
  Body createBody() {
    final b = world.createBody(BodyDef()..type = BodyType.static);

    _pts = _buildProfile();

    final chain = ChainShape()..createChain(_pts);
    b.createFixture(
      FixtureDef(chain)
        ..filter.categoryBits = kGroundCat
        ..friction = friction
        ..restitution = 0.0,
    );

    _cachedPath = _buildFillPath(_pts);
    return b;
  }

  List<Vector2> _buildProfile() {
    final List<Vector2> keyPoints = [];
    Vector2 lastCursor = Vector2(startX, baseY);
    final random = math.Random();

    // 1. Начинаем с плоского участка (безопасный старт)
    _appendChunk(keyPoints, ChunkLibrary.getByDiff(1).first, lastCursor);
    lastCursor = keyPoints.last;

    // 2. Генерируем последовательность из 15 испытаний
    for (int i = 0; i < 15; i++) {
      int diff = (i < 5) ? 1 : (i < 10 ? 2 : 3); // Постепенное усложнение
      final pool = ChunkLibrary.getByDiff(diff);
      final chunk = pool[random.nextInt(pool.length)];

      _appendChunk(keyPoints, chunk, lastCursor);
      lastCursor = keyPoints.last;
    }

    // 3. Сглаживаем все стыки чанков через твой Catmull-Rom
    return _applySpline(keyPoints);
  }

  void _appendChunk(List<Vector2> target, ChunkTemplate chunk, Vector2 offset) {
    for (final node in chunk.nodes) {
      final newPoint = offset + node;

      // Если список не пуст, проверяем расстояние до последней точки
      if (target.isNotEmpty) {
        // Если расстояние меньше 0.1 пикселя — игнорируем точку
        if ((target.last - newPoint).length < 0.1) continue;
      }
      target.add(newPoint);
    }
  }

  List<Vector2> _applySpline(List<Vector2> nodes) {
    final pts = <Vector2>[];

    // Вспомогательная функция, чтобы не дублировать логику проверки
    void safeAdd(Vector2 point) {
      if (pts.isEmpty) {
        pts.add(point);
      } else {
        // Проверяем расстояние между текущей и последней точкой
        // 0.1 — безопасный порог для Forge2D
        if ((pts.last - point).length > 0.1) {
          pts.add(point);
        }
      }
    }

    for (int i = 0; i < nodes.length - 1; i++) {
      final p0 = nodes[i > 0 ? i - 1 : i];
      final p1 = nodes[i];
      final p2 = nodes[i + 1];
      final p3 = nodes[i + 2 < nodes.length ? i + 2 : i + 1];

      double segmentWidth = (p2.x - p1.x).abs();

      // 1. Обработка обрывов (вертикальных стен)
      if (segmentWidth < 1.0) {
        safeAdd(p1);
        safeAdd(p2);
        continue;
      }

      // 2. Отрисовка сплайна между p1 и p2
      for (double t = 0; t < 1; t += stepX / segmentWidth) {
        safeAdd(_catmullRom(p0, p1, p2, p3, t));
      }
    }

    // 3. Финальная точка всей трассы
    safeAdd(nodes.last);

    return pts;
  }

  Vector2 _catmullRom(
    Vector2 p0,
    Vector2 p1,
    Vector2 p2,
    Vector2 p3,
    double t,
  ) {
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

  @override
  void render(Canvas canvas) {
    // ВАЖНО: Проверь, чтобы этот метод был внутри класса!
    // Именно здесь используются _cachedPath и _paint
    final path = _cachedPath;
    if (path != null) {
      canvas.drawPath(path, _paint);
    }
    super.render(canvas);
  }

  Path _buildFillPath(List<Vector2> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.x, pts.first.y);
    for (final p in pts) {
      path.lineTo(p.x, p.y);
    }

    // Заливка глубоко вниз для бесконечного эффекта
    final bottomY = baseY + 2000;
    path
      ..lineTo(pts.last.x, bottomY)
      ..lineTo(pts.first.x, bottomY)
      ..close();
    return path;
  }
}
