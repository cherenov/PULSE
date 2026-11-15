import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:pulse/theme/sizes.dart';

class OrbitalRunScreen extends StatefulWidget {
  const OrbitalRunScreen({super.key});

  @override
  State<OrbitalRunScreen> createState() => _OrbitalRunScreenState();
}

enum _RunPhase { ready, playing, paused, over }

class _OrbitalRunScreenState extends State<OrbitalRunScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static int _bestScore = 0;

  final math.Random _random = math.Random();
  final List<_Star> _stars = [];
  final List<_Enemy> _enemies = [];
  final List<_Laser> _lasers = [];
  final List<_Particle> _particles = [];

  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  Size _arenaSize = Size.zero;

  _RunPhase _phase = _RunPhase.ready;
  double _playerX = 0.5;
  final double _playerY = 0.84;
  double _fireCooldown = 0;
  double _spawnCooldown = 0.5;
  double _elapsed = 0;
  double _invulnerable = 0;
  double _shake = 0;
  int _score = 0;
  int _kills = 0;
  int _lives = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    for (var i = 0; i < 90; i++) {
      _stars.add(_Star.random(_random));
    }
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused) &&
        _phase == _RunPhase.playing) {
      setState(() => _phase = _RunPhase.paused);
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    final step = dt.clamp(0.0, 0.05);
    if (_phase == _RunPhase.playing) {
      _update(step);
      if (mounted) setState(() {});
    } else if (_phase == _RunPhase.ready || _phase == _RunPhase.over) {
      if (_shake > 0) _shake = math.max(0, _shake - step * 3);
      _updateStars(step * 0.35);
      if (mounted) setState(() {});
    }
  }

  void _startGame() {
    HapticFeedback.lightImpact();
    setState(() {
      _phase = _RunPhase.playing;
      _enemies.clear();
      _lasers.clear();
      _particles.clear();
      _playerX = 0.5;
      _fireCooldown = 0;
      _spawnCooldown = 0.5;
      _elapsed = 0;
      _invulnerable = 0;
      _shake = 0;
      _score = 0;
      _kills = 0;
      _lives = 3;
    });
  }

  void _togglePause() {
    if (_phase == _RunPhase.playing) {
      setState(() => _phase = _RunPhase.paused);
    } else if (_phase == _RunPhase.paused) {
      setState(() => _phase = _RunPhase.playing);
    }
  }

  void _steerTo(double x) {
    if (_phase != _RunPhase.playing) return;
    setState(() => _playerX = x.clamp(0.08, 0.92).toDouble());
  }

  void _steerBy(double dx, double width) {
    if (_phase != _RunPhase.playing || width <= 0) return;
    setState(
      () => _playerX = (_playerX + dx / width).clamp(0.08, 0.92).toDouble(),
    );
  }

  void _update(double dt) {
    _elapsed += dt;
    if (_invulnerable > 0) _invulnerable -= dt;
    if (_shake > 0) _shake = math.max(0, _shake - dt * 3);
    if (_phase != _RunPhase.playing) return;

    _updateStars(dt);
    _updateFire(dt);
    _updateSpawning(dt);
    _updateLasers(dt);
    _updateEnemies(dt);
    _updateParticles(dt);
    _checkCollisions(_arenaSize);
  }

  void _updateStars(double dt) {
    final speedFactor = 1 + _elapsed / 55;
    for (final star in _stars) {
      star.y += dt * star.speed * speedFactor;
      if (star.y > 1.02) {
        star.y = -0.02;
        star.x = _random.nextDouble();
      }
    }
  }

  void _updateFire(double dt) {
    _fireCooldown -= dt;
    if (_fireCooldown > 0) return;

    _fireCooldown = 0.24;
    _lasers.add(
      _Laser(
        x: _playerX - 0.018,
        y: _playerY - 0.04,
        speed: -1.15,
        isEnemy: false,
      ),
    );
    _lasers.add(
      _Laser(
        x: _playerX + 0.018,
        y: _playerY - 0.04,
        speed: -1.15,
        isEnemy: false,
      ),
    );
  }

  void _updateSpawning(double dt) {
    _spawnCooldown -= dt;
    if (_spawnCooldown > 0) return;

    if (_enemies.length < 8) {
      _spawnEnemy();
      final difficulty = (_elapsed / 45).clamp(0.0, 2.0);
      _spawnCooldown =
          (1.05 - difficulty * 0.22).clamp(0.38, 1.05) *
          (0.75 + _random.nextDouble() * 0.5);
    } else {
      _spawnCooldown = 0.45;
    }
  }

  void _spawnEnemy() {
    final heavy = _score >= 80 && _random.nextDouble() < 0.16;
    final difficulty = (_elapsed / 50).clamp(0.0, 1.8);
    final baseX = 0.12 + _random.nextDouble() * 0.76;

    _enemies.add(
      _Enemy(
        baseX: baseX,
        x: baseX,
        y: -0.08,
        speed:
            (heavy ? 0.12 : 0.16) +
            _random.nextDouble() * 0.07 +
            difficulty * 0.03,
        sway: heavy ? 0.015 : 0.025 + _random.nextDouble() * 0.04,
        swayPhase: _random.nextDouble() * math.pi * 2,
        fireCooldown: 1.2 + _random.nextDouble() * 2.2,
        hp: heavy ? 3 : 1,
        heavy: heavy,
      ),
    );
  }

  void _updateLasers(double dt) {
    for (var i = _lasers.length - 1; i >= 0; i--) {
      final laser = _lasers[i];
      laser.y += laser.speed * dt;
      if (laser.y < -0.12 || laser.y > 1.12) {
        _lasers.removeAt(i);
      }
    }
  }

  void _updateEnemies(double dt) {
    var enemyLaserCount = _lasers.where((l) => l.isEnemy).length;

    for (var i = _enemies.length - 1; i >= 0; i--) {
      final enemy = _enemies[i];
      enemy.y += enemy.speed * dt;
      enemy.swayPhase += dt * (enemy.heavy ? 1.3 : 1.8);
      enemy.x = (enemy.baseX + math.sin(enemy.swayPhase) * enemy.sway)
          .clamp(0.08, 0.92)
          .toDouble();
      enemy.fireCooldown -= dt;

      if (enemy.fireCooldown <= 0 &&
          enemy.y > 0.12 &&
          enemy.y < 0.68 &&
          enemyLaserCount < 10) {
        enemy.fireCooldown = 1.6 + _random.nextDouble() * 2.0;
        _lasers.add(
          _Laser(x: enemy.x, y: enemy.y + 0.02, speed: 0.46, isEnemy: true),
        );
        enemyLaserCount++;
      }

      if (enemy.y > 1.1) {
        _enemies.removeAt(i);
      }
    }
  }

  void _updateParticles(double dt) {
    for (var i = _particles.length - 1; i >= 0; i--) {
      final particle = _particles[i];
      particle.life -= dt;
      if (particle.life <= 0) {
        _particles.removeAt(i);
        continue;
      }
      particle.x += particle.vx * dt;
      particle.y += particle.vy * dt;
      particle.vy += dt * 0.12;
    }
  }

  void _checkCollisions(Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final scale = _scaleFor(size);

    for (var laserIndex = _lasers.length - 1; laserIndex >= 0; laserIndex--) {
      final laser = _lasers[laserIndex];
      if (laser.isEnemy) continue;

      for (
        var enemyIndex = _enemies.length - 1;
        enemyIndex >= 0;
        enemyIndex--
      ) {
        final enemy = _enemies[enemyIndex];
        final deltaX = (laser.x - enemy.x) * size.width;
        final deltaY = (laser.y - enemy.y) * size.height;
        final hitRadius = (enemy.heavy ? 26 : 18) * scale;

        if (deltaX * deltaX + deltaY * deltaY <= hitRadius * hitRadius) {
          _lasers.removeAt(laserIndex);
          enemy.hp--;

          if (enemy.hp <= 0) {
            _enemies.removeAt(enemyIndex);
            _score += enemy.heavy ? 30 : 10;
            _bestScore = math.max(_bestScore, _score);
            _kills++;
            _spawnExplosion(
              enemy.x,
              enemy.y,
              enemy.heavy ? 18 : 11,
              _GameColors.critical,
            );
            HapticFeedback.selectionClick();
          } else {
            _spawnExplosion(laser.x, laser.y, 4, _GameColors.caution);
          }
          break;
        }
      }
    }

    for (var i = _lasers.length - 1; i >= 0; i--) {
      final laser = _lasers[i];
      if (!laser.isEnemy) continue;

      final deltaX = (laser.x - _playerX) * size.width;
      final deltaY = (laser.y - _playerY) * size.height;
      final hitRadius = 17 * scale;

      if (deltaX * deltaX + deltaY * deltaY <= hitRadius * hitRadius) {
        _lasers.removeAt(i);
        if (_invulnerable <= 0) _damagePlayer();
        break;
      }
    }

    if (_invulnerable > 0 || _phase != _RunPhase.playing) return;

    for (var i = _enemies.length - 1; i >= 0; i--) {
      final enemy = _enemies[i];
      final deltaX = (enemy.x - _playerX) * size.width;
      final deltaY = (enemy.y - _playerY) * size.height;
      final combinedRadius = (18 + (enemy.heavy ? 26 : 18)) * scale;

      if (deltaX * deltaX + deltaY * deltaY <=
          combinedRadius * combinedRadius) {
        _enemies.removeAt(i);
        _spawnExplosion(enemy.x, enemy.y, 16, _GameColors.critical);
        _damagePlayer();
        break;
      }
    }
  }

  void _damagePlayer() {
    _lives--;
    _invulnerable = 1.35;
    _shake = 1;
    _spawnExplosion(_playerX, _playerY, 24, _GameColors.info);

    if (_lives <= 0) {
      _phase = _RunPhase.over;
      _bestScore = math.max(_bestScore, _score);
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  void _spawnExplosion(double x, double y, int count, Color color) {
    for (var i = 0; i < count; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 0.06 + _random.nextDouble() * 0.3;
      final life = 0.35 + _random.nextDouble() * 0.5;
      _particles.add(
        _Particle(
          x: x,
          y: y,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          life: life,
          maxLife: life,
          size: 1.2 + _random.nextDouble() * 2.8,
          color: color,
        ),
      );
    }
  }

  double _scaleFor(Size size) => (size.width / 390).clamp(0.85, 1.6).toDouble();

  @override
  Widget build(BuildContext context) {
    final best = math.max(_bestScore, _score);

    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _arenaSize = Size(constraints.maxWidth, constraints.maxHeight);

            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) => _steerTo(
                      details.localPosition.dx / constraints.maxWidth,
                    ),
                    onHorizontalDragUpdate: (details) =>
                        _steerBy(details.delta.dx, constraints.maxWidth),
                    child: CustomPaint(
                      painter: _RunPainter(
                        stars: _stars,
                        enemies: _enemies,
                        lasers: _lasers,
                        particles: _particles,
                        playerX: _playerX,
                        playerY: _playerY,
                        invulnerable: _invulnerable,
                        shake: _shake,
                        elapsed: _elapsed,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
                Positioned(
                  top: AppSizes.md,
                  left: AppSizes.md,
                  right: AppSizes.md,
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    child: _Hud(
                      score: _score,
                      best: best,
                      lives: _lives,
                      phase: _phase,
                      onBack: () => Navigator.of(context).pop(),
                      onPause: _togglePause,
                    ),
                  ),
                ),
                if (_phase == _RunPhase.ready)
                  _StartOverlay(
                    best: best,
                    onStart: _startGame,
                    onExit: () => Navigator.of(context).pop(),
                  ),
                if (_phase == _RunPhase.paused)
                  _PauseOverlay(
                    onResume: _togglePause,
                    onExit: () => Navigator.of(context).pop(),
                  ),
                if (_phase == _RunPhase.over)
                  _GameOverOverlay(
                    score: _score,
                    best: best,
                    kills: _kills,
                    onRestart: _startGame,
                    onExit: () => Navigator.of(context).pop(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Star {
  _Star.random(math.Random random)
    : x = random.nextDouble(),
      y = random.nextDouble(),
      speed = 0.02 + random.nextDouble() * 0.09,
      size = 0.6 + random.nextDouble() * 1.5,
      opacity = 0.25 + random.nextDouble() * 0.7;

  double x;
  double y;
  final double speed;
  final double size;
  final double opacity;
}

class _Enemy {
  _Enemy({
    required this.baseX,
    required this.x,
    required this.y,
    required this.speed,
    required this.sway,
    required this.swayPhase,
    required this.fireCooldown,
    required this.hp,
    required this.heavy,
  });

  final double baseX;
  double x;
  double y;
  final double speed;
  final double sway;
  double swayPhase;
  double fireCooldown;
  int hp;
  final bool heavy;
}

class _Laser {
  _Laser({
    required this.x,
    required this.y,
    required this.speed,
    required this.isEnemy,
  });

  final double x;
  double y;
  final double speed;
  final bool isEnemy;
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.maxLife,
    required this.size,
    required this.color,
  });

  double x;
  double y;
  double vx;
  double vy;
  double life;
  final double maxLife;
  final double size;
  final Color color;
}

class _RunPainter extends CustomPainter {
  _RunPainter({
    required this.stars,
    required this.enemies,
    required this.lasers,
    required this.particles,
    required this.playerX,
    required this.playerY,
    required this.invulnerable,
    required this.shake,
    required this.elapsed,
  });

  final List<_Star> stars;
  final List<_Enemy> enemies;
  final List<_Laser> lasers;
  final List<_Particle> particles;
  final double playerX;
  final double playerY;
  final double invulnerable;
  final double shake;
  final double elapsed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.35),
          radius: 1.15,
          colors: [Color(0xFF16233B), Color(0xFF080A12), Color(0xFF030407)],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );

    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.2),
      size.width * 0.3,
      Paint()
        ..color = _GameColors.sleep.withValues(alpha: 0.035)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45),
    );

    final shakeOffset = shake > 0 ? math.sin(elapsed * 75) * shake * 5 : 0.0;
    canvas.save();
    canvas.translate(shakeOffset, shakeOffset * 0.5);

    _drawStars(canvas, size);
    _drawLasers(canvas, size);
    for (final enemy in enemies) {
      _drawEnemy(canvas, size, enemy);
    }
    _drawPlayer(canvas, size);
    _drawParticles(canvas, size);

    canvas.restore();
  }

  void _drawStars(Canvas canvas, Size size) {
    final starPaint = Paint()..isAntiAlias = true;
    final streakPaint = Paint()
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round;

    for (final star in stars) {
      final center = Offset(star.x * size.width, star.y * size.height);
      starPaint.color = Colors.white.withValues(alpha: star.opacity);
      canvas.drawCircle(center, star.size, starPaint);

      if (star.speed > 0.075) {
        streakPaint
          ..color = Colors.white.withValues(alpha: star.opacity * 0.22)
          ..strokeWidth = star.size * 0.8;
        canvas.drawLine(
          center,
          center.translate(0, star.size * 3),
          streakPaint,
        );
      }
    }
  }

  void _drawLasers(Canvas canvas, Size size) {
    final scale = _scaleFor(size);

    for (final laser in lasers) {
      final x = laser.x * size.width;
      final y = laser.y * size.height;
      final color = laser.isEnemy ? _GameColors.critical : _GameColors.accent;
      final length = (laser.isEnemy ? 14.0 : 20.0) * scale;
      final start = Offset(x, y - (laser.isEnemy ? length : 0));
      final end = Offset(x, y + (laser.isEnemy ? 0 : length));

      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = color.withValues(alpha: 0.48)
          ..strokeWidth = 7 * scale
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * scale),
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = color
          ..strokeWidth = 2.5 * scale
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..strokeWidth = 0.9 * scale
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawEnemy(Canvas canvas, Size size, _Enemy enemy) {
    final center = Offset(enemy.x * size.width, enemy.y * size.height);
    final scale = _scaleFor(size) * (enemy.heavy ? 1.35 : 1.0);
    final color = enemy.heavy ? _GameColors.caution : _GameColors.critical;
    final alpha = enemy.heavy ? 0.65 + enemy.hp * 0.1 : 1.0;

    canvas.drawCircle(
      center.translate(0, -12 * scale),
      8 * scale,
      Paint()
        ..color = color.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * scale),
    );

    final body = Path()
      ..moveTo(center.dx, center.dy + 17 * scale)
      ..lineTo(center.dx - 20 * scale, center.dy - 2 * scale)
      ..lineTo(center.dx - 10 * scale, center.dy - 15 * scale)
      ..lineTo(center.dx, center.dy - 9 * scale)
      ..lineTo(center.dx + 10 * scale, center.dy - 15 * scale)
      ..lineTo(center.dx + 20 * scale, center.dy - 2 * scale)
      ..close();

    canvas.drawPath(
      body,
      Paint()
        ..color = _GameColors.surfaceHigh.withValues(alpha: alpha)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      body,
      Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (enemy.heavy ? 2.2 : 1.6) * scale
        ..strokeJoin = StrokeJoin.round,
    );

    final detailPaint = Paint()
      ..color = color.withValues(alpha: 0.65 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center.translate(-16 * scale, 0),
      center.translate(-7 * scale, -8 * scale),
      detailPaint,
    );
    canvas.drawLine(
      center.translate(16 * scale, 0),
      center.translate(7 * scale, -8 * scale),
      detailPaint,
    );

    canvas.drawCircle(
      center.translate(0, -2 * scale),
      3.2 * scale,
      Paint()..color = color.withValues(alpha: 0.9 * alpha),
    );
  }

  void _drawPlayer(Canvas canvas, Size size) {
    final center = Offset(playerX * size.width, playerY * size.height);
    final scale = _scaleFor(size);
    final blink = invulnerable > 0 && (elapsed * 12).floor().isEven;
    final alpha = blink ? 0.35 : 1.0;

    canvas.drawCircle(
      center.translate(0, 20 * scale),
      13 * scale,
      Paint()
        ..color = _GameColors.info.withValues(alpha: 0.26 * alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 13 * scale),
    );

    if (invulnerable > 0) {
      canvas.drawCircle(
        center,
        31 * scale,
        Paint()
          ..color = _GameColors.info.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 * scale,
      );
    }

    final body = Path()
      ..moveTo(center.dx, center.dy - 26 * scale)
      ..lineTo(center.dx - 19 * scale, center.dy + 14 * scale)
      ..lineTo(center.dx - 7 * scale, center.dy + 8 * scale)
      ..lineTo(center.dx, center.dy + 17 * scale)
      ..lineTo(center.dx + 7 * scale, center.dy + 8 * scale)
      ..lineTo(center.dx + 19 * scale, center.dy + 14 * scale)
      ..close();

    canvas.drawPath(
      body,
      Paint()
        ..color = _GameColors.surfaceHigh.withValues(alpha: alpha)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      body,
      Paint()
        ..color = _GameColors.info.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7 * scale
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      body,
      Paint()
        ..color = _GameColors.textPrimary.withValues(alpha: alpha * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * scale
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(
      center.translate(0, -4 * scale),
      3.4 * scale,
      Paint()..color = _GameColors.accent.withValues(alpha: alpha),
    );
  }

  void _drawParticles(Canvas canvas, Size size) {
    for (final particle in particles) {
      final alpha = (particle.life / particle.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size * (0.5 + alpha * 0.8),
        Paint()..color = particle.color.withValues(alpha: alpha * 0.9),
      );
    }
  }

  double _scaleFor(Size size) => (size.width / 390).clamp(0.85, 1.6).toDouble();

  @override
  bool shouldRepaint(covariant _RunPainter oldDelegate) => true;
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.score,
    required this.best,
    required this.lives,
    required this.phase,
    required this.onBack,
    required this.onPause,
  });

  final int score;
  final int best;
  final int lives;
  final _RunPhase phase;
  final VoidCallback onBack;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: AppSizes.sm,
          ),
          decoration: BoxDecoration(
            color: _GameColors.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _GameColors.border.withValues(alpha: 0.8),
            ),
          ),
          child: Row(
            children: [
              _HudIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
              const SizedBox(width: AppSizes.sm),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OFF-DUTY FLIGHT',
                      style: TextStyle(
                        color: _GameColors.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'ORBITAL RUN',
                      style: TextStyle(
                        color: _GameColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              if (phase == _RunPhase.playing || phase == _RunPhase.paused)
                _HudIconButton(
                  icon: phase == _RunPhase.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  onTap: onPause,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            Expanded(
              child: _HudChip(
                label: 'SCORE',
                value: '$score',
                valueColor: _GameColors.accent,
              ),
            ),
            const SizedBox(width: AppSizes.xs),
            Expanded(
              child: _HudChip(label: 'BEST', value: '$best'),
            ),
            const SizedBox(width: AppSizes.xs),
            Expanded(child: _HullChip(lives: lives)),
          ],
        ),
      ],
    );
  }
}

class _HudIconButton extends StatelessWidget {
  const _HudIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _GameColors.surfaceHigh,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: _GameColors.textPrimary),
        ),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.label,
    required this.value,
    this.valueColor = _GameColors.textPrimary,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 7),
      decoration: BoxDecoration(
        color: _GameColors.surface.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _GameColors.border.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _GameColors.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HullChip extends StatelessWidget {
  const _HullChip({required this.lives});

  final int lives;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 7),
      decoration: BoxDecoration(
        color: _GameColors.surface.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _GameColors.border.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HULL',
            style: TextStyle(
              color: _GameColors.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Icon(
                  Icons.shield_rounded,
                  size: 14,
                  color: index < lives
                      ? _GameColors.ok
                      : _GameColors.textDisabled,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StartOverlay extends StatelessWidget {
  const _StartOverlay({
    required this.best,
    required this.onStart,
    required this.onExit,
  });

  final int best;
  final VoidCallback onStart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return _GameOverlay(
      eyebrow: 'DEEP SPACE // SECTOR 7',
      title: 'ORBITAL RUN',
      message:
          'A short break between mission tasks. Thread the enemy patrol, '
          'keep your hull intact and chase a new best score.',
      icon: Icons.rocket_launch_rounded,
      footer: best > 0 ? 'SESSION BEST  $best' : null,
      actions: [
        _PrimaryButton(
          label: 'Launch',
          icon: Icons.play_arrow_rounded,
          onTap: onStart,
        ),
        _SecondaryButton(
          label: 'Back to settings',
          icon: Icons.logout_rounded,
          onTap: onExit,
        ),
      ],
      instructions: const [
        _InstructionRow(
          icon: Icons.swipe_rounded,
          text: 'Drag anywhere to steer · tap to reposition',
        ),
        _InstructionRow(
          icon: Icons.flash_on_rounded,
          text: 'Auto-cannon fires for you',
        ),
        _InstructionRow(
          icon: Icons.warning_amber_rounded,
          text: 'Avoid red bolts and enemy raiders',
        ),
      ],
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume, required this.onExit});

  final VoidCallback onResume;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return _GameOverlay(
      eyebrow: 'FLIGHT PAUSED',
      title: 'Catch your breath',
      message: 'The patrol will wait. Resume when you are ready.',
      icon: Icons.pause_rounded,
      actions: [
        _PrimaryButton(
          label: 'Resume',
          icon: Icons.play_arrow_rounded,
          onTap: onResume,
        ),
        _SecondaryButton(
          label: 'Exit to settings',
          icon: Icons.logout_rounded,
          onTap: onExit,
        ),
      ],
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.score,
    required this.best,
    required this.kills,
    required this.onRestart,
    required this.onExit,
  });

  final int score;
  final int best;
  final int kills;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return _GameOverlay(
      eyebrow: 'MISSION ENDED',
      title: 'Hull breach',
      message:
          'The patrol broke through. Recalibrate, take a breath and fly '
          'again when you are ready.',
      icon: Icons.local_fire_department_outlined,
      footer: 'FINAL SCORE  $score   ·   RAIDERS  $kills   ·   BEST  $best',
      actions: [
        _PrimaryButton(
          label: 'Fly again',
          icon: Icons.replay_rounded,
          onTap: onRestart,
        ),
        _SecondaryButton(
          label: 'Back to settings',
          icon: Icons.logout_rounded,
          onTap: onExit,
        ),
      ],
    );
  }
}

class _GameOverlay extends StatelessWidget {
  const _GameOverlay({
    required this.eyebrow,
    required this.title,
    required this.message,
    required this.icon,
    required this.actions,
    this.footer,
    this.instructions = const [],
  });

  final String eyebrow;
  final String title;
  final String message;
  final IconData icon;
  final List<Widget> actions;
  final String? footer;
  final List<Widget> instructions;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.62),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                padding: const EdgeInsets.all(AppSizes.xxl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_GameColors.surfaceHigh, _GameColors.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _GameColors.accent.withValues(alpha: 0.28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: _GameColors.accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: _GameColors.accent, size: 30),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Text(
                      eyebrow,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _GameColors.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _GameColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _GameColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    if (instructions.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.lg),
                      for (final instruction in instructions) ...[
                        instruction,
                        const SizedBox(height: AppSizes.sm),
                      ],
                    ],
                    if (footer != null) ...[
                      const SizedBox(height: AppSizes.md),
                      Text(
                        footer!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _GameColors.textDisabled,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSizes.xl),
                    for (final action in actions) ...[
                      SizedBox(width: double.infinity, child: action),
                      const SizedBox(height: AppSizes.sm),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  const _InstructionRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _GameColors.info, size: 17),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _GameColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: _GameColors.accent,
        foregroundColor: _GameColors.onAccent,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _GameColors.textSecondary,
        side: const BorderSide(color: _GameColors.border),
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// The mini-game keeps its original colorful palette, independent of the
/// app-wide monochrome AMOLED theme.
abstract final class _GameColors {
  static const surface = Color(0xFF17171C);
  static const surfaceHigh = Color(0xFF22222A);
  static const border = Color(0xFF2A2A33);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9A9AA8);
  static const textDisabled = Color(0xFF5C5C68);

  static const accent = Color(0xFFA9DB7A);
  static const onAccent = Color(0xFF111111);

  static const ok = Color(0xFFA9DB7A);
  static const caution = Color(0xFFF6CB55);
  static const critical = Color(0xFFE5646E);
  static const info = Color(0xFF7AB8F5);
  static const sleep = Color(0xFFA78BFA);
}
