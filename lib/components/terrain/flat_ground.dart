import 'package:flame_forge2d/flame_forge2d.dart';

/// Очень простой "пол" — статическая линия от startX до startX+length на высоте groundY.
class FlatGround extends BodyComponent {
  FlatGround({
    this.startX = 50.0,
    this.length = 500.0,
    this.groundY = 660.0,
    this.thickness = 12.0,
    this.friction = 0.95,
  }) {
    renderBody = true;
  }

  final double startX;
  final double length;
  final double groundY;
  final double thickness;
  final double friction;

  @override
  Body createBody() {
    final def = BodyDef()..type = BodyType.static;
    final body = world.createBody(def);

    // Прямоугольная платформа
    final center = Vector2(startX + length / 2, groundY + thickness / 2);
    final shape =
        PolygonShape()..setAsBox(length / 2, thickness / 2, center, 0);

    body.createFixture(
      FixtureDef(shape)
        ..friction = friction
        ..restitution = 0.0,
    );

    return body;
  }
}
