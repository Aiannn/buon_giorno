import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'components/buon_giorno.dart';
import 'components/terrain/procedural_terrain_new.dart';

class BuonGiornoGame extends Forge2DGame {
  BuonGiornoGame() : super(gravity: Vector2(0, 20));

  late final ProceduralTerrain terrain;
  late final BuonGiorno player;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // await add(FlatGround());
    camera.viewfinder.zoom = 0.5;
    camera.viewfinder.anchor = const Anchor(0.2, 0.7);

    terrain = ProceduralTerrain(
      startX: -200,
      baseY: 660, // Твоя базовая линия
      stepX: 10, // Плавность
    );
    await world.add(terrain);

    player = BuonGiorno(spritePath: 'buongiorno.webp');
    await world.add(player);

    camera.follow(player);
  }
}
