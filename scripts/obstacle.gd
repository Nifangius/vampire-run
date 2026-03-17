## obstacle.gd — препятствие с шипами
## Верх является твёрдой платформой, левая грань дамажит игрока при касании
extends StaticBody2D

@export var obstacle_type: int = 0  # 0 = колья (красные), 1 = брёвна (коричневые)

@onready var sprite      = $Sprite2D
@onready var damage_area = $DamageArea

func _ready():
	obstacle_type = randi() % 2
	_apply_variant()
	damage_area.body_entered.connect(_on_damage_area_body_entered)

## Визуальное различие типов — TODO: заменить на смену текстуры при появлении спрайтов
func _apply_variant():
	match obstacle_type:
		0: sprite.modulate = Color(0.898, 0.133, 0.0, 1)  # красный — колья
		1: sprite.modulate = Color(0.55, 0.35, 0.1, 1)    # коричневый — брёвна

func _physics_process(delta):
	position.x -= GameConfig.OBSTACLE_SPEED * delta
	if position.x < GameConfig.SCREEN_LEFT_BOUND:
		queue_free()

func _on_damage_area_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage()
