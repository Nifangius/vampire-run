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
│   ├── main_menu.tscn        # начальный экран (стартовая сцена)
│   ├── settings_menu.tscn    # экран настроек (громкость, разрешение, окно)
│   ├── leaderboard.tscn      # таблица рекордов
│   ├── main.tscn             # главная сцена игры
│   ├── player.tscn           # игрок — вампир
│   ├── enemy.tscn            # наземный враг — зомби
│   ├── flying_enemy.tscn     # летающий враг
│   ├── obstacle.tscn         # препятствие (шипы/брёвна)
│   ├── bat.tscn              # снаряд игрока
│   ├── enemy_projectile.tscn # снаряд врага
│   ├── blood_drop.tscn       # коллектабл — капля крови
│   ├── heart.tscn            # коллектабл — сердце (только при трансформации)
│   ├── game_over.tscn        # экран окончания игры (с вводом имени)
│   └── pause.tscn            # экран паузы
├── scripts/
│   ├── game_config.gd        # ВСЕ константы игры (AutoLoad: GameConfig)
│   ├── settings_manager.gd   # настройки звука/дисплея (AutoLoad: SettingsManager)
│   ├── scores_manager.gd     # таблица рекордов (AutoLoad: ScoresManager)
│   ├── main_menu.gd
│   ├── settings_menu.gd
│   ├── leaderboard.gd
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
    ├── sounds/                # звуки и музыка
    └── fonts/                 # пиксельные шрифты (ThaleahFat.ttf)
```

---

## AutoLoad синглтоны

| Имя | Файл | Назначение |
|-----|------|-----------|
| `GameConfig` | `game_config.gd` | Все константы и настройки игры |
| `SettingsManager` | `settings_manager.gd` | Громкость, разрешение, режим окна, сохранение в user://settings.cfg |
| `ScoresManager` | `scores_manager.gd` | Таблица рекордов (топ-10), сохранение в user://scores.cfg |

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

**Важно про спавн коллектаблов:**
- `_nearest_obstacle_type(radius)` — хелпер, возвращает `"dangerous"`, `"safe"` или `"none"`
- `spawn_safe_obstacle()` — **всегда** спавнит каплю крови прямо на платформу; Y определяется через `obstacle.get_platform_top_y() - 50` (реальная геометрия, не константа)
- `spawn_blood_drop()`: рядом с safe_obstacle → пропуск (капля уже есть на платформе); рядом с опасным → elevated Y (200-350); чистая зона → Y у земли
- `spawn_health_drop()`: рядом с опасным → elevated Y
- **Нет `_clear_collectibles_near_spawn()`** — функция удалена. Коллектаблы никогда не удаляются принудительно после спавна; безопасное размещение решается в момент спавна

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
`_toggle_pause()` открывает паузу (только когда НЕ на паузе). Закрытие — исключительно через pause.gd.
Музыка при паузе: `main_music.stream_paused`. Возобновление через сигнал `pause_screen.resumed`.

---

## Архитектура паузы (pause.gd)

- Process Mode: Always
- Навигация: W/S по кнопкам, Escape = продолжить
- Escape поглощается через `_unhandled_input` + `set_input_as_handled()` чтобы main.gd не получил событие
- Кнопки: Продолжить, Настройки, Рекорды, Выйти
- Настройки и Рекорды открываются как оверлей (`add_child`) поверх паузы — игровой прогресс сохраняется
- Сигнал `resumed` эмитируется при продолжении → main.gd возобновляет нужную музыку

**Важно:** `Input.is_action_just_pressed()` — polling, игнорирует `set_input_as_handled()`. Для перехвата событий с приоритетом использовать `_unhandled_input`.

---

## Архитектура Game Over (game_over.gd)

1. При первой смерти в сессии — показывается панель `NameInput` с LineEdit
2. Пробел/Enter/ОК подтверждают имя → `ScoresManager.session_name` сохраняется на всю сессию
3. При последующих смертях — имя уже известно, сразу сохраняется счёт
4. Кнопки: "Ещё раз" (`reload_current_scene`), "Главное меню"

---

## Архитектура SettingsManager

- Создаёт аудио шины `Music` и `SFX` программно в `_ready()` (не в .tscn — редактор их стирает)
- Назначение шин в скриптах: `main.gd` — MainBG/TransformBG → `"Music"`; `player.gd` — все SFX узлы → `"SFX"`
- Сохраняет: master/music/sfx volume (0.0–1.0), windowed bool, resolution_idx
- `apply_settings()` — применяет всё сразу
- Разрешения: 1280×720, 1920×1080, 2560×1440

---

## Архитектура ScoresManager

- Топ-10 рекордов, отсортированы по убыванию счёта
- Имена уникальны: `add_score()` обновляет запись только если новый счёт **больше** существующего
- `session_name` — имя игрока в текущей сессии, сбрасывается только при выходе из приложения
- Сохраняется в `user://scores.cfg`

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
- `spawn_obstacle()` проверяет группу `safe_obstacle` — не спавнится в радиусе `SPAWN_SAFE_OBSTACLE_MIN_GAP` (300px)
- `spawn_safe_obstacle()` проверяет группу `obstacle` — не спавнится в радиусе `SPAWN_SAFE_OBSTACLE_MIN_GAP` (300px)
- `get_platform_top_y() -> float` — метод в `obstacle.gd`, возвращает мировой Y верхней грани платформы для safe obstacle (obstacle_type 2); читает реальные данные из `$TopCollision.shape`

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
- **Аудио шины назначать в скриптах**, не в .tscn — редактор Godot стирает свойство `bus` при пересохранении сцены
- **Оверлеи из паузы**: настройки и рекорды открываются через `add_child()` на CanvasLayer паузы, используют паттерн `signal closed` + `var from_pause: bool`
- Stretch mode: `canvas_items` + `keep`, viewport 1152×648 — задано в project.godot
