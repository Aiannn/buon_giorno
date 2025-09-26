import 'package:flutter/foundation.dart';

@immutable
class GameConfig {
  // World / camera
  final double gravityY; // гравитация вниз (Forge2D: +Y = вниз)
  final double zoom; // масштаб камеры
  final double cameraOffsetX; // доля ширины экрана: 0.30 = левая треть

  // Player (Bonjorno)
  final double playerSpeed; // м/с по X (поддерживаемая скорость)
  final double playerWidth; // ширина тела (м)
  final double playerHeight; // высота тела (м)
  final double playerStartX; // стартовая позиция
  final double playerStartY;

  // Terrain (MVP — плоско)
  final double groundY; // уровень земли
  final double initialChunkStartX; // первый чанк откуда
  final double initialChunkLength; // длина первого чанка
  final double aheadMargin; // запас вперёд для ensureAhead

  // Stack / balance (плейсхолдеры на будущее)
  final int boxesCount;
  final double maxTiltDeg;
  final double autoCCWRate;
  final double tapCWImpulse;
  final double tiltDamping;
  final double slopeBiasK;
  final double playerKp; // для PD крутящего момента (позже)
  final double playerKd;

  const GameConfig({
    // world
    this.gravityY = 20.0,
    this.zoom = 14.0,
    this.cameraOffsetX = 0.30,
    // player
    this.playerSpeed = 5.0,
    this.playerWidth = 0.6,
    this.playerHeight = 1.2,
    this.playerStartX = -10.0,
    this.playerStartY = -2.0,
    // terrain
    this.groundY = 0.0,
    this.initialChunkStartX = -50.0,
    this.initialChunkLength = 500.0,
    this.aheadMargin = 120.0,
    // stack/balance
    this.boxesCount = 5,
    this.maxTiltDeg = 50.0,
    this.autoCCWRate = 0.7,
    this.tapCWImpulse = 1.1,
    this.tiltDamping = 0.12,
    this.slopeBiasK = 0.85,
    this.playerKp = 30.0,
    this.playerKd = 6.0,
  });
}
