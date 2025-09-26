import 'package:flame_forge2d/flame_forge2d.dart'; // Forge2DGame
import 'components/buon_giorno.dart'; // твой BuonGiorno

class BuonGiornoGame extends Forge2DGame {
  BuonGiornoGame()
    : super(
        gravity: Vector2(
          0,
          20,
        ), // для кинематического тела не важно; оставим дефолт
        zoom: 14, // масштаб камеры (приближение)
      );

  late final BuonGiorno player;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1) Добавляем только игрока.
    player = BuonGiorno(
      // spritePath: 'assets/images/bon_giorno.png', // оставь закомментированным, если спрайт не подключил
    );
    await add(player);

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
