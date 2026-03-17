## obstacle.gd — препятствие, движется влево со скоростью мира
extends StaticBody2D

func _physics_process(delta):
	position.x -= GameConfig.OBSTACLE_SPEED * delta
	if position.x < GameConfig.SCREEN_LEFT_BOUND:
		queue_free()
