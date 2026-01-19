import 'dart:math' as math;
import 'package:flame_forge2d/flame_forge2d.dart';

const int kGroundCat = 0x0002;

/// Очень простой "пол" — статическая линия от startX до startX+length на высоте groundY.
class FlatGround extends BodyComponent {
  FlatGround({
    this.startX = 50.0,
    this.flatLength = 500.0,
    this.rampLength = 300.0,
    this.groundY = 660.0,
    this.thickness = 12.0,
    this.rampAngleDeg = 30.0,
    this.friction = 0.95,
  }) {
    renderBody = true;
  }

  final double startX;
  final double flatLength;
  final double rampLength;
  final double rampAngleDeg;
  final double groundY;
  final double thickness;
  final double friction;

  @override
  Body createBody() {
    final def = BodyDef()..type = BodyType.static;
    final body = world.createBody(def);

    // 1) Ровная полка (ось Y вниз!)
    final flatCenter = Vector2(
      startX + flatLength / 2,
      groundY + thickness / 2,
    );
    final flat =
        PolygonShape()..setAsBox(flatLength / 2, thickness / 2, flatCenter, 0);
    body.createFixture(
      FixtureDef(flat)
        ..filter.categoryBits = kGroundCat
        ..filter.maskBits = 0xFFFF
        ..friction = friction
        ..restitution = 0.0,
    );

    // 2) Наклон как выпуклый многоугольник, верхняя грань без зазора
    final theta = rampAngleDeg * math.pi / 180.0;

    // Верхняя грань наклона: начинается ровно в конце полки
    final x0 = startX + flatLength; // стык по X
    final y0 = groundY; // верх полки
    final x1 = x0 + rampLength * math.cos(theta);
    final y1 = y0 - rampLength * math.sin(theta); // вверх = уменьшение Y

    // Вектор "вниз" от верхней грани на толщину (нормаль к поверхности)
    final nx = math.sin(theta);
    final ny = math.cos(theta);

    // Четыре вершины параллелограмма (CCW):
    final p0 = Vector2(x0, y0); // верх-начало (стык)
    final p1 = Vector2(x1, y1); // верх-конец
    final p2 = Vector2(x1 + nx * thickness, y1 + ny * thickness); // низ-конец
    final p3 = Vector2(x0 + nx * thickness, y0 + ny * thickness); // низ-начало

    final rampPoly = PolygonShape()..set([p0, p1, p2, p3]);
    body.createFixture(
      FixtureDef(rampPoly)
        ..filter.categoryBits = kGroundCat
        ..filter.maskBits = 0xFFFF
        ..friction = friction
        ..restitution = 0.0,
    );

    return body;
  }
}
