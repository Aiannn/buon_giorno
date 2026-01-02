import 'package:buon_giorno/components/terrain/chunk_template.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

class TerrainManager {
  final List<Vector2> _allPoints = [];
  Vector2 _lastPoint = Vector2(0, 700); // Стартовая позиция

  void spawnChunk(ChunkTemplate template) {
    for (var node in template.nodes) {
      // Ключевой момент: Складываем глобальный офсет и локальные координаты чанка
      _allPoints.add(_lastPoint + node);
    }
    _lastPoint = _allPoints.last; // Обновляем точку входа для следующего чанка
  }
}
