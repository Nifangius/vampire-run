## bat.gd — снаряд игрока (летучая мышь)
extends Area2D

var direction = Vector2(1, 0)  # по умолчанию летит вправо

var volume_db = -20  # громкость задаётся снаружи при тройном выстреле

func _ready():
	$AnimatedSprite2D.play("shoot")
	$BatSound.volume_db = volume_db  # применяем перед воспроизведением
	$BatSound.play()
	body_entered.connect(_on_body_entered)

func _process(delta):
	position += direction * GameConfig.BAT_SPEED * delta
	
	# Удаляем если вышел за границы экрана
	if position.x > GameConfig.SCREEN_RIGHT_BOUND or \
	   position.x < GameConfig.SCREEN_LEFT_BOUND or \
	   position.y < GameConfig.SCREEN_TOP_BOUND or \
	   position.y > GameConfig.SCREEN_BOTTOM_BOUND:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		body.die()
		# Отключаем коллизию чтобы не срабатывало повторно
		$CollisionShape2D.set_deferred("disabled", true)
		
		# Плавно затухаем и удаляем
		var tween = create_tween()
		tween.tween_property($BatSound, "volume_db", -80.0, 0.4)
		await tween.finished
		queue_free()
