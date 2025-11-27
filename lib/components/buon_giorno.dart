import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'terrain/flat_ground.dart' show kGroundCat;

// ====== Топ-левел "конфиг" для BuonGiorno ======
const double kBonWidth = 80; // м
const double kBonHeight = 100; // м
const double kBonSpeedX = 40.0; // м/с вправо
final Vector2 kBonStart = Vector2(
  0,
  (kBonHeight / 2 + 0.05),
); // стартовая позиция (центр тела на 0.05м выше поверхности)
const Color kBonColor = Color(0xFF4FC3F7); // цвет заглушки

// Категория игрока (для фильтров)
const int kPlayerCat = 0x0004;

/// MVP: кинематический BuonGiorno, едет вправо с постоянной скоростью.
/// Никаких зависимостей от Terrain/Config — один файл, один класс.
class BuonGiorno extends BodyComponent with ContactCallbacks {
  BuonGiorno({this.spritePath});

  /// Путь к ассету (например, 'assets/images/bon_giorno.png').
  final String? spritePath;

  // Визуальный ребёнок (спрайт или прямоугольник).
  late final PositionComponent _visual;

  // ===== Raycast: переиспользуемые буферы =====
  // луч: from -> to
  final Vector2 _from = Vector2.zero();
  final Vector2 _to = Vector2.zero();

  // частота опроса и сглаживание
  static const double _probeEvery = 0.05; // 50мс
  static const double _probeLen = 400.0; // «вниз» под твой масштаб
  static const double _angleLerp = 0.15; // плавность поворота визуала
  double _timeAcc = 0.0;
  double _targetAngle = 0.0;

  // ===== Grounded через сенсор-«ступню» =====
  int _groundContacts = 0;
  bool get isGrounded => _groundContacts > 0;
  static const double _downForce = 50.0; // сила прижатия к земле

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
        ..restitution = 0.0
        ..filter.categoryBits = kPlayerCat
        ..filter.maskBits = 0xFFFF, // видим всех (в т.ч. kGroundCat)
    );

    // Сенсор-ступня (тонкая полоска под телом)
    final foot =
        PolygonShape()..setAsBox(
          kBonWidth * 0.45, // почти во всю ширину
          2.0, // тонкая
          Vector2(0, kBonHeight / 2 + 1.0), // смещена чуть ниже низа корпуса
          0,
        );

    body.createFixture(
      FixtureDef(foot)
        ..isSensor = true
        ..userData = 'foot'
        ..filter.categoryBits = kPlayerCat
        ..filter.maskBits = 0xFFFF,
    );

    return body;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Постоянная скорость вправо в метрах/сек
    final v = body.linearVelocity;
    body.linearVelocity = Vector2(kBonSpeedX, v.y);
    // НИЧЕГО не синхронизируем для _visual здесь!

    // Небольшая прижимка к земле, чтобы сгладить стыки
    body.applyLinearImpulse(
      Vector2(0, _downForce * dt),
      point: body.worldCenter,
      wake: true,
    );

    // Периодический рейкаст вниз, чтобы узнать угол поверхности
    _timeAcc += dt;
    if (_timeAcc >= _probeEvery) {
      _timeAcc = 0;
      _sampleGroundAngle();
    }

    // Плавно тянем визуал к целевому углу
    _visual.angle = _lerpAngle(_visual.angle, _targetAngle, _angleLerp);
  }

  @override
  void render(Canvas canvas) {
    // НИЧЕГО не синхронизируем для _visual здесь тоже!
    super.render(
      canvas,
    ); // белая форма + затем дети (уже с обновлёнными позицией/углом)
  }

  // ===== Контакты ступни =====
  @override
  void beginContact(Object other, Contact contact) {
    final a = contact.fixtureA;
    final b = contact.fixtureB;
    final isFoot = (a.userData == 'foot') || (b.userData == 'foot');

    // считаем «земля», если другая фикстура имеет категорию kGroundCat
    final otherCat =
        (a.userData == 'foot')
            ? b.filterData.categoryBits
            : a.filterData.categoryBits;
    if (isFoot && (otherCat & kGroundCat) != 0) {
      _groundContacts++;
    }
  }

  @override
  void endContact(Object other, Contact contact) {
    final a = contact.fixtureA;
    final b = contact.fixtureB;
    final isFoot = (a.userData == 'foot') || (b.userData == 'foot');

    final otherCat =
        (a.userData == 'foot')
            ? b.filterData.categoryBits
            : a.filterData.categoryBits;
    if (isFoot && (otherCat & kGroundCat) != 0) {
      _groundContacts--;
    }
  }

  void _sampleGroundAngle() {
    // Луч — от чуть ниже центра вниз
    _from
      ..setFrom(body.worldCenter)
      ..y += kBonHeight * 0.30;
    _to
      ..setFrom(_from)
      ..y += _probeLen;

    final cb = _FirstGroundHit(groundCategory: kGroundCat);
    world.raycast(cb, _from, _to);

    if (cb.gotHit) {
      final n = cb.normal;
      final slopeAngle = math.atan2(n.x, -n.y); // перпендикуляр к нормали
      _targetAngle = slopeAngle;
    } else {
      _targetAngle = 0.0;
    }
  }

  double _lerpAngle(double a, double b, double t) {
    final diff = (b - a + math.pi) % (2 * math.pi) - math.pi;
    return a + diff * t;
  }
}

/// Берёт первый валидный хит по «земле».
class _FirstGroundHit implements RayCastCallback {
  _FirstGroundHit({required this.groundCategory});

  final int groundCategory;
  final Vector2 normal = Vector2.zero();
  bool gotHit = false;

  @override
  double reportFixture(
    Fixture fixture,
    Vector2 point,
    Vector2 n,
    double fraction,
  ) {
    // игнорируем сенсоры
    if (fixture.isSensor) return -1.0;

    // фильтрация по категории «земля»
    final cat = fixture.filterData.categoryBits;
    if ((cat & groundCategory) == 0) return -1.0;

    // сохраняем нормаль первого попадания и останавливаемся
    normal.setFrom(n);
    gotHit = true;
    return fraction; // клипнуть луч и завершить
  }
}
