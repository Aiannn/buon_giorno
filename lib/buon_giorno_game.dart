import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
// import 'core/game_config.dart';
// import 'components/bonjorno.dart';
// import 'components/box_stack.dart';
// import 'components/terrain/terrain_manager.dart';

class BuonGiornoGame extends Forge2DGame with TapDetector {
  // BuonGiornoGame() : super(gravity: Vector2(0, 20.0), zoom: 12.0);

  // final config = const GameConfig();
  // late final Bonjorno bonjorno;
  // late final BoxStack boxStack;
  // late final TerrainManager terrain;

  // @override
  // Future<void> onLoad() async {
  //   await super.onLoad();

  //   bonjorno = Bonjorno(config: config);
  //   await add(bonjorno);

  //   boxStack = BoxStack(
  //     config: config,
  //     anchorBodyProvider: () => bonjorno.body,
  //   );
  //   await add(boxStack);

  //   terrain = TerrainManager(config: config);
  //   await add(terrain);

  //   camera.follow(bonjorno, worldBounds: Rect.fromLTWH(-1000, -200, 1e9, 1000));
  //   camera.setRelativeOffset(Vector2(config.cameraOffsetX, 0.5));
  // }

  // @override
  // void update(double dt) {
  //   super.update(dt);
  //   // авто-движение вправо (поддержка скорости)
  //   final v = bonjorno.body.linearVelocity;
  //   bonjorno.body.linearVelocity = Vector2(config.playerSpeed, v.y);

  //   // уклон под игроком (оценка из TerrainManager)
  //   final slope = terrain.slopeAtX(bonjorno.body.position.x); // тангенс угла
  //   boxStack.applyBalance(dt, slope: slope); // мотор/импульсы к шарниру
  // }

  // @override
  // void onTapDown(TapDownInfo info) {
  //   boxStack.onTap();
  // }
}
