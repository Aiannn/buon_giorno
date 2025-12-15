import 'package:flame_forge2d/flame_forge2d.dart'; // Forge2DGame
import 'components/buon_giorno.dart'; // твой BuonGiorno
import 'components/terrain/procedural_terrain.dart';

class BuonGiornoGame extends Forge2DGame {
  BuonGiornoGame()
    : super(
        gravity: Vector2(
          0,
          20,
        ), // для кинематического тела не важно; оставим дефолт
        zoom: 14, // масштаб камеры (приближение)
      );

  late final ProceduralTerrain terrain;
  late final BuonGiorno player;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // await add(FlatGround());

    terrain = ProceduralTerrain(
      startX: -600,
      length: 5000,
      stepX: 16,
      baseY: 660,
      ampBase: 130,
      maxSlopeDeg: 22,
      maxCurvDeg: 6,
      seed: DateTime.now().millisecondsSinceEpoch, // или фиксируй
      debugRender: true,
    );
    await add(terrain);

    // final y0 = terrain.heightAt(0);
    // final start = Vector2(0, y0 - (kBonHeight / 2) - 6.0);

    player = BuonGiorno(
      spritePath:
          'buongiorno.webp', // оставь закомментированным, если спрайт не подключил
    );
    await add(player);

    // camera.moveTo(player.body.position);

    // 2) Хочешь видеть, как прямоугольник ЕДЕТ вправо через экран — НЕ следуй камерой:
    // (оставь эти две строки закомментированными)
    // camera.follow(
    //   player,
    //   worldBounds: const Rect.fromLTWH(-100000, -1000, 200000, 4000),
    // );
    // camera.setRelativeOffset(Vector2(0.30, 0.5));

    // Если позже захочешь держать героя слева — просто раскомментируй код выше.
  }
}
