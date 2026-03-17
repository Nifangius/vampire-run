## enemy.gd — наземный враг
extends CharacterBody2D

func _ready():
	$AnimatedSprite2D.play("walk")

func _physics_process(delta):
	# Гравитация — враг стоит на полу
	if not is_on_floor():
		velocity.y += GameConfig.ENEMY_GRAVITY * delta
	
	# Движение влево навстречу игроку
	velocity.x = -GameConfig.ENEMY_SPEED
	move_and_slide()
	
	# Удаляем когда ушёл за левый край
	if position.x < GameConfig.SCREEN_LEFT_BOUND:
		queue_free()

func die(speed: float = 1.0):
	set_physics_process(false)
	$AnimatedSprite2D.speed_scale = speed  # slam stomp ускоряет анимацию смерти
	$AnimatedSprite2D.play("die")
	await $AnimatedSprite2D.animation_finished
	queue_free()
