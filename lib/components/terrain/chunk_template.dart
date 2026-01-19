import 'package:flame/extensions.dart';

class ChunkTemplate {
  final String id;
  final int difficulty; // 1: Easy, 2: Medium, 3: Hard
  final List<Vector2> nodes;

  ChunkTemplate({
    required this.id,
    required this.difficulty,
    required this.nodes,
  });
}

class ChunkLibrary {
  static List<ChunkTemplate> getByDiff(int diff) =>
      _all.where((c) => c.difficulty == diff).toList();

  static final List<ChunkTemplate> _all = [
    // === EASY: Плавное вхождение ===
    ChunkTemplate(
      id: 'E_Flat',
      difficulty: 1,
      nodes: [Vector2(0, 0), Vector2(400, 0)],
    ),
    ChunkTemplate(
      id: 'E_Hill',
      difficulty: 1,
      nodes: [Vector2(0, 0), Vector2(200, -80), Vector2(400, 0)],
    ),
    ChunkTemplate(
      id: 'E_Slope',
      difficulty: 1,
      nodes: [Vector2(0, 0), Vector2(300, -120), Vector2(500, -150)],
    ),
    ChunkTemplate(
      id: 'E_Dip',
      difficulty: 1,
      nodes: [Vector2(0, 0), Vector2(200, 80), Vector2(400, 0)],
    ),
    ChunkTemplate(
      id: 'E_Waves',
      difficulty: 1,
      nodes: [
        Vector2(0, 0),
        Vector2(150, -40),
        Vector2(300, 40),
        Vector2(450, 0),
      ],
    ),

    // === MEDIUM: Проверка реакции на наклон ===
    ChunkTemplate(
      id: 'M_Bumps',
      difficulty: 2,
      nodes: [
        Vector2(0, 0),
        Vector2(100, -60),
        Vector2(200, 0),
        Vector2(300, -60),
        Vector2(400, 0),
      ],
    ),
    ChunkTemplate(
      id: 'M_Valley',
      difficulty: 2,
      nodes: [Vector2(0, 0), Vector2(250, 250), Vector2(500, 0)],
    ),
    ChunkTemplate(
      id: 'M_Wall',
      difficulty: 2,
      nodes: [Vector2(0, 0), Vector2(200, -300), Vector2(400, -350)],
    ),
    ChunkTemplate(
      id: 'M_Platform',
      difficulty: 2,
      nodes: [
        Vector2(0, 0),
        Vector2(100, -150),
        Vector2(300, -150),
        Vector2(400, 0),
      ],
    ),
    ChunkTemplate(
      id: 'M_Sway',
      difficulty: 2,
      nodes: [
        Vector2(0, 0),
        Vector2(150, 100),
        Vector2(350, -100),
        Vector2(500, 0),
      ],
    ),

    // === HARD: Экстремальный баланс (резкая смена вектора) ===
    // Острая как игла гора (было -500, стало -1500)
    ChunkTemplate(
      id: 'H_Peak',
      difficulty: 3,
      nodes: [Vector2(0, 0), Vector2(250, -1500), Vector2(500, 0)],
    ),

    // Зигзаг с глубокими провалами (амплитуда прыгает на 600-800 пикселей)
    ChunkTemplate(
      id: 'H_ZigZag',
      difficulty: 3,
      nodes: [
        Vector2(0, 0),
        Vector2(150, -600),
        Vector2(300, 400),
        Vector2(450, -600),
      ],
    ),

    // Гигантская лестница (каждая ступенька теперь ощутимая)
    ChunkTemplate(
      id: 'H_Stairs',
      difficulty: 3,
      nodes: [
        Vector2(0, 0),
        Vector2(100, -300),
        Vector2(200, -600),
        Vector2(300, -900),
        Vector2(400, -1200),
      ],
    ),

    // Глубочайший обрыв (падение на 1000 пикселей вниз)
    ChunkTemplate(
      id: 'H_Cliff',
      difficulty: 3,
      nodes: [
        Vector2(0, 0),
        Vector2(150, 0),
        Vector2(170, 1000),
        Vector2(450, 1000),
      ],
    ),

    // Эверест (вертикальный подъем на 2000 пикселей)
    ChunkTemplate(
      id: 'H_Mountain',
      difficulty: 3,
      nodes: [Vector2(0, 0), Vector2(500, -2000), Vector2(1000, 0)],
    ),
  ];
}
