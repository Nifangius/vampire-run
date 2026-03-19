# Vampire Run — контекст проекта

## Описание игры

2D пиксельный раннер в котором игрок управляет вампиром бегущим справа налево.
Вдохновлён Monster Dash. Движок: **Godot 4**, язык: **GDScript**.

Иллюзия движения создаётся параллакс фоном — сам игрок статичен по X.
Управление: прыжок (пробел), стрельба (Z), трансформация (F), пауза (Escape).

---

## Структура проекта

```
res://
├── scenes/
│   ├── main.tscn             # главная сцена игры
│   ├── player.tscn           # игрок — вампир
│   ├── enemy.tscn            # наземный враг — зомби
│   ├── flying_enemy.tscn     # летающий враг
│   ├── obstacle.tscn         # препятствие (шипы/брёвна)
│   ├── bat.tscn              # снаряд игрока
│   ├── enemy_projectile.tscn # снаряд врага
│   ├── blood_drop.tscn       # коллектабл — капля крови
│   ├── heart.tscn            # коллектабл — сердце (только при трансформации)
│   ├── game_over.tscn        # экран окончания игры
│   └── pause.tscn            # экран паузы
├── scripts/
│   ├── game_config.gd        # ВСЕ константы игры (AutoLoad: GameConfig)
│   ├── main.gd
│   ├── player.gd
│   ├── enemy.gd
│   ├── flying_enemy.gd
│   ├── obstacle.gd
│   ├── bat.gd
│   ├── enemy_projectile.gd
│   ├── blood_drop.gd
│   ├── heart.gd
│   ├── game_over.gd
│   └── pause.gd
└── assets/
    ├── backgrounds/           # параллакс фоны (3 слоя)
    ├── sprites/               # спрайты персонажей
    └── fonts/                 # пиксельные шрифты
```

---

## AutoLoad синглтоны

| Имя | Файл | Назначение |
|-----|------|-----------|
| `GameConfig` | `game_config.gd` | Все константы и настройки игры |

**Важно:** все магические числа должны быть в `game_config.gd`. При добавлении новых механик сначала добавляй константы туда.

---

## Система коллизий (Collision Layers)

| Слой | Bitmask | Кто использует | Описание |
|------|---------|---------------|----------|
| 1 | 1 | Пол | Физика пола |
| 2 | 2 | Игрок | CharacterBody2D игрока |
| 3 | 4 | Препятствия, Враги, снаряды врагов | Коллизии с миром |
| 4 | 8 | Снаряды игрока, HitBox | Урон по врагам |

**Маски (фактические значения из сцен):**
- Игрок (CharacterBody2D): Layer 2, Mask 5 (слои 1+3 — пол и препятствия/враги)
- HitBox игрока (Area2D): Layer 0, Mask 8 (слой 4 — снаряды врагов)
- Наземный враг: Layer 3, Mask 1
- Летающий враг: Layer 3, Mask 1
- Снаряд игрока (bat): Layer 4, Mask 3
- Снаряд врага: Layer 3, Mask → группа `player_hitbox`
- Препятствие (StaticBody2D): Layer 3, Mask 0
- DamageArea препятствия: Layer 0, Mask 2 (видит игрока на Layer 2)

---

## Группы объектов

| Группа | Кто состоит | Для чего |
|--------|------------|---------|
| `enemy` | enemy.tscn, flying_enemy.tscn | Определение врагов для стомпа и урона |
| `flying_enemy` | flying_enemy.tscn | Различие наземных и летающих для очков |
| `obstacle` | obstacle.tscn, obstacle_2.tscn, obstacle_safe.tscn | Проверка при спавне капель крови и safe obstacle |
| `safe_obstacle` | obstacle_safe.tscn | Отличие безопасного препятствия от опасных при спавне |
| `player` | Player узел | Получение урона от DamageArea препятствий |
| `player_hitbox` | HitBox узел игрока | Урон от снарядов врага (узкий хитбокс) |
| `blood_drop` | blood_drop.tscn | Очистка при трансформации |
| `health_drop` | heart.tscn | Очистка при окончании трансформации |
| `enemy_projectile` | enemy_projectile.tscn | Near miss система очков |

---

## Архитектура игрока (player.gd)

### Режимы
- **Обычный режим** — бег, прыжок, стрельба одиночным снарядом
- **Режим трансформации** — полёт зажатием пробела, тройной выстрел, длится 13 сек

### Механики прыжка
- Переменная высота: короткое нажатие = низкий прыжок, долгое = высокий
- Двойной прыжок: пробел в воздухе = второй прыжок (`PLAYER_DOUBLE_JUMP_VELOCITY`)
- Coyote time: прыжок работает ещё `PLAYER_COYOTE_TIME` сек после потери опоры
- Асимметричная гравитация: при падении `PLAYER_FALL_GRAVITY` > `PLAYER_GRAVITY` — приземление снаппи
- Стомп: приземление на врага сверху → враг умирает, игрок отскакивает

### Сигналы игрока
```gdscript
signal hit(lives_remaining: int)   # получен урон
signal died                         # жизни закончились
signal blood_collected(count: int)  # собрана капля крови
signal transformed                  # трансформация активирована
signal transform_ready              # накоплено 13 капель
signal transform_ended              # трансформация завершена
```

### Методы которые вызываются извне
```gdscript
take_damage()                        # нанести урон игроку
activate_invincibility(duration)     # временная неуязвимость
collect_blood()                      # собрать каплю крови
collect_health()                     # собрать сердце
```

---

## Архитектура main.gd

### Спавн объектов
Все объекты спавнятся на X = `GameConfig.SPAWN_X` (1300) и движутся влево.
Интервалы спавна рандомизированы и делятся на `difficulty` — со временем враги появляются чаще.

### Система очков
```gdscript
add_score(points: int, position: Vector2)  # начислить очки и показать попап
```
- Время: `SCORE_RATE * difficulty` очков/сек
- Убийство наземного врага: `SCORE_KILL_GROUND` (10)
- Убийство летающего врага: `SCORE_KILL_FLYING` (20)
- Near miss снаряда: `SCORE_NEAR_MISS` (10)

### Трансформация
При трансформации и её окончании вызывается `flash_and_pause()` — белая вспышка + пауза 0.5 сек + неуязвимость 1.5 сек.

### Пауза
`_toggle_pause()` — вызывается по Escape. Показывает/скрывает `pause.tscn` и передаёт текущий счёт.

---

## Архитектура препятствий (obstacle.gd)

Три вида препятствий:
- `obstacle.tscn` — obstacle_type 0, статичный спрайт (шипы)
- `obstacle_2.tscn` — obstacle_type 1, анимированный спрайт
- `obstacle_safe.tscn` — obstacle_type 2, безопасное препятствие-платформа (без DamageArea)

Все три в группе `obstacle`. Только `obstacle_safe.tscn` дополнительно в группе `safe_obstacle`.

- **TopCollision** (CollisionShape2D) — тонкая горизонтальная полоска на верхней грани, `one_way_collision = true`. Игрок может запрыгнуть на препятствие как на платформу.
- **DamageArea** (Area2D) — тонкая вертикальная полоска на левой грани (только у опасных). При касании вызывает `take_damage()` на игроке. Не отталкивает.

### Логика спавна препятствий
- `spawn_obstacle()` проверяет группу `safe_obstacle` — не спавнится в радиусе `SPAWN_SAFE_OBSTACLE_MIN_GAP` (500px)
- `spawn_safe_obstacle()` проверяет группу `obstacle` — не спавнится в радиусе `SPAWN_SAFE_OBSTACLE_MIN_GAP` (500px)
- Капли крови (`spawn_blood_drop()`): рядом с опасным (300px) — поднимаются выше DamageArea; рядом с `safe_obstacle` — не спавнятся совсем

---

## Архитектура врагов

### Наземный враг (enemy.gd)
- Движется влево с `ENEMY_SPEED`
- `die(speed: float = 1.0)` — анимация смерти, `speed` ускоряет анимацию при slam stomp

### Летающий враг (flying_enemy.gd)
- Волнообразное движение через `sin()`
- Стреляет в направлении игрока с небольшим разбросом `PROJECTILE_SPREAD`
- Стреляет только если игрок **слева** от врага
- `die()` — падает вниз с ускорением

---

## Параллакс фон

Три слоя: Sky, Mid, Fore — каждый дублирован (Sky1/Sky2 и т.д.) для бесшовного скролла.
Скорости из GameConfig: `SKY_SPEED`, `MID_SPEED`, `FORE_SPEED` × `WORLD_SPEED`.

```gdscript
scroll_two_layers(layer1, layer2, speed)  # вызывается каждый кадр
```

---

## UI структура (main.tscn)

```
Main
├── Background/         # параллакс слои
├── Floor               # StaticBody2D — пол
├── Player
├── GameOver            # CanvasLayer, Process Mode: Always
├── Pause               # CanvasLayer, Process Mode: Always
└── UI (CanvasLayer)
    ├── Health/         # HBoxContainer с иконками жизней (Hrt1-Hrt5)
    ├── BloodCounter/   # HBoxContainer: иконка + BloodLabel "0/13"
    ├── TransformLabel  # Label "F - Трансформация!", скрыт по умолчанию
    ├── FlashOverlay    # ColorRect белый, для вспышки трансформации
    └── ScoreLabel      # текущий счёт
```

---

## Соглашения по именованию

- Сцены: `snake_case.tscn`
- Скрипты: `snake_case.gd`
- Константы: `UPPER_SNAKE_CASE` в `game_config.gd`
- Переменные: `snake_case`
- Методы: `snake_case`, приватные начинаются с `_`
- Все комментарии на **русском языке**

---

## Важные заметки

- **Никаких магических чисел в скриптах** — только через `GameConfig.*`
- `get_tree().paused = true` останавливает всё кроме узлов с `Process Mode: Always`
- `HitBox` игрока меньше спрайта (~65%) для честного геймплея
- При добавлении новых врагов: добавить в группу `enemy`, установить Layer 3
- При добавлении новых коллектаблов: добавить группу для очистки при трансформации
- Препятствия наносят урон через `DamageArea` (левая грань), не через физический толчок
- При добавлении нового вида препятствия: добавить в группу `obstacle`, если безопасное — также в `safe_obstacle`; спавнеры в `main.gd` учтут его автоматически
