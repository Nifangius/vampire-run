## heart.gd — коллектабл во время трансформации, восстанавливает жизнь
extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	position.x -= GameConfig.COLLECTIBLE_SPEED * delta
	if position.x < GameConfig.SCREEN_LEFT_BOUND:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.collect_health()
		queue_free()
