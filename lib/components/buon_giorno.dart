import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

// ====== Топ-левел "конфиг" для BuonGiorno ======
const double kBonWidth = 0.6; // м
const double kBonHeight = 1.2; // м
const double kBonSpeedX = 5.0; // м/с вправо
final Vector2 kBonStart = Vector2(-10, 0); // стартовая позиция
const Color kBonColor = Color(0xFF4FC3F7); // цвет заглушки

/// MVP: кинематический BuonGiorno, едет вправо с постоянной скоростью.
/// Никаких зависимостей от Terrain/Config — один файл, один класс.
class BuonGiorno extends BodyComponent {
  BuonGiorno({this.spritePath});

  /// Путь к ассету (например, 'assets/images/bon_giorno.png').
  final String? spritePath;

  // Визуальный ребёнок (спрайт или прямоугольник).
  late final PositionComponent _visual;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    if (spritePath != null) {
      final image = await Flame.images.load(spritePath!); // без gameRef
      _visual = SpriteComponent(
        sprite: Sprite(image),
        size: Vector2(kBonWidth, kBonHeight),
        anchor: Anchor.center,
      );
    } else {
      _visual = RectangleComponent(
        size: Vector2(kBonWidth, kBonHeight),
        anchor: Anchor.center,
        paint: Paint()..color = kBonColor,
      );
    }

    add(_visual);
  }

  @override
  Body createBody() {
    // КИНЕМАТИЧЕСКОЕ тело: не подчиняется силам/гравитации, двигается как зададим.
    final def =
        BodyDef()
          ..type = BodyType.kinematic
          ..position = kBonStart
          ..fixedRotation = true;

    final body = world.createBody(def);

    final shape =
        PolygonShape()
          ..setAsBox(kBonWidth / 2, kBonHeight / 2, Vector2.zero(), 0);
    body.createFixture(
      FixtureDef(shape)
        ..density = 1.0
        ..friction = 0.9
        ..restitution = 0.0,
    );

    return body;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Постоянная скорость вправо в метрах/сек
    body.linearVelocity = Vector2(kBonSpeedX, 0);

    // Синхронизируем визуал с физическим телом
    _visual
      ..position = body.worldCenter
      ..angle = body.angle;
  }
}
