## enemy_projectile.gd — снаряд летающего врага
extends Area2D

var direction = Vector2.ZERO  # направление задаётся при спавне из flying_enemy.gd

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	position += direction * GameConfig.ENEMY_PROJECTILE_SPEED * delta
	
	# Удаляем если вышел за границы экрана
	if position.x < GameConfig.SCREEN_LEFT_BOUND or \
	   position.y > GameConfig.SCREEN_BOTTOM_BOUND:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player_hitbox"):
		body.take_damage()
		queue_free()
