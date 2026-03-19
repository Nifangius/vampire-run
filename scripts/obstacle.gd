## obstacle.gd — препятствие с шипами
## Верх является твёрдой платформой, левая грань дамажит игрока при касании
extends StaticBody2D

@export var obstacle_type: int = 0  # 0 = статичный (obstacle-1), 1 = анимированный (obstacle-2)

@onready var damage_area = $DamageArea

func _ready():
	_apply_variant()
	damage_area.body_entered.connect(_on_damage_area_body_entered)

func _apply_variant():
	# Тип определяется сценой через Inspector — не перезаписываем
	if obstacle_type == 1:
		$AnimatedSprite2D.play()

func _physics_process(delta):
	position.x -= GameConfig.OBSTACLE_SPEED * delta
	if position.x < GameConfig.SCREEN_LEFT_BOUND:
		queue_free()

func _on_damage_area_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage()
