import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

// ====== Топ-левел "конфиг" для BuonGiorno ======
const double kBonWidth = 80; // м
const double kBonHeight = 100; // м
const double kBonSpeedX = 10.0; // м/с вправо
final Vector2 kBonStart = Vector2(
  0,
  (kBonHeight / 2 + 0.05),
); // стартовая позиция (центр тела на 0.05м выше поверхности)
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

    // ВАЖНО: локально к телу, центр в (0,0)
    _visual.position = Vector2.zero();
    // угол ребёнка 0: родитель уже вращает канвас под угол тела
    _visual.angle = 0;

    add(_visual);
  }

  @override
  Body createBody() {
    // КИНЕМАТИЧЕСКОЕ тело: не подчиняется силам/гравитации, двигается как зададим.
    final def =
        BodyDef()
          ..type = BodyType.dynamic
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
    body.linearVelocity = Vector2(kBonSpeedX, body.linearVelocity.y);
    // НИЧЕГО не синхронизируем для _visual здесь!
  }

  @override
  void render(Canvas canvas) {
    // НИЧЕГО не синхронизируем для _visual здесь тоже!
    super.render(
      canvas,
    ); // белая форма + затем дети (уже с обновлёнными позицией/углом)
  }
}
