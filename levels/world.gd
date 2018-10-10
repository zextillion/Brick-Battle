extends Node2D

var _main_menu = load("res://main_menu/MainMenu.tscn")

var _player = preload("res://characters/player/Player.tscn")
var _ball = preload("res://objects/Ball.tscn")

var num_players = 4
var players = []
var lives = []

var start_countdown = 3

var balls = 0
var max_balls = 1

var current_level = 0

enum STATES { NORMAL, GAME_OVER }
var state = NORMAL

func _ready():
	OS.set_window_fullscreen(true)
	max_balls = GameManager.num_balls
	num_players = GameManager.num_players
	for i in range(num_players, $Interface/UI/Lives.get_child_count()):
		$Interface/UI/Lives.get_child(i).visible = false
	
	Utils.camera = $Camera
	$StartCountdownTimer.connect("timeout", self, "_on_StartCountdownTimer_timeout")
	$GameOverTimer.connect("timeout", self, "_on_GameOverTimer_timeout")
	$BallRespawnTimer.connect("timeout", self, "_on_BallRespawnTimer_timeout")
	$NextLevelTimer.connect("timeout", self, "_on_NextLevelTimer_timeout")
	$Interface/UI/GameOverHUD/VBoxContainer/RestartButton.connect("button_down", get_tree(), "reload_current_scene")
	$Interface/UI/GameOverHUD/VBoxContainer/QuitButton.connect("button_down", self, "quit_to_main_menu")
	
	for level in $Levels.get_children():
		level.connect("level_win", self, "level_win")
	
	for i in range(num_players):
		$Goals.get_child(i).connect("goal", self, "goal")
		players.push_back(_player.instance())
		players[i].position = $StartPositions.get_child(i).position
		players[i].rotation_degrees = $StartPositions.get_child(i).rotation_degrees
		players[i].show()
		players[i].player = i
		match i:
			0:
				players[i].modulate = Color(0.3,0.5,1, 1)
			1:
				players[i].modulate = Color(1, 0.2, 0.2, 1)
			2:
				players[i].modulate = Color(0.2, 1, 0.2, 1)
			3:
				players[i].modulate = Color(1, 1, 0.3, 1)
		add_child(players[i])
		lives.push_back(10)
	
	new_game()


func new_game():
	current_level = 0
	new_level()


func new_level():
	var new_level = $Levels.get_child(current_level)
	new_level.spawn_bricks()
	
	$Background/Background.modulate.r = (sin((current_level * 30) * (PI / 180) + 0) * 30 + 100) / 255
	$Background/Background.modulate.g = (sin((current_level * 30) * (PI / 180) + 2) * 30 + 80) / 255
	$Background/Background.modulate.b = (sin((current_level * 30) * (PI / 180) + 4) * 30 + 128) / 255
	
	$Interface/UI/GameOverHUD.hide()
	
	start_StartCountdownTimer()


func start_StartCountdownTimer():
	start_countdown = 3
	$Interface/UI/MessageLabel.text = str(start_countdown)
	$StartCountdownTimer.start()


func _on_StartCountdownTimer_timeout():
	start_countdown -= 1
	$Interface/UI/MessageLabel.text = str(start_countdown)
	
	if start_countdown <= 0:
		for i in range(max_balls - balls):
			spawn_ball(i)
		$StartCountdownTimer.stop()
		$Interface/UI/MessageLabel.hide()


func _on_BallRespawnTimer_timeout():
	for i in range(max_balls - balls):
		var rnd_spawn = randi() % num_players
		spawn_ball(rnd_spawn)


func spawn_ball(index):
	# Spawn ball
	var ball = _ball.instance()
	ball.position = $BallSpawnPositions.get_child(index).position
	ball.direction = -ball.position.normalized() # Assumes the game is centered around Vector2(0, 0)
	add_child(ball)
	balls += 1


func goal(player):
	$BallRespawnTimer.start()
	balls -= 1
	
	lives[player] -= 1
	$Interface/UI/Lives.get_child(player).get_child(1).text = "p%s lives\n%s" % [player + 1, lives[player]]
	if lives[player] <= 0:
		if num_players == 1:
			game_over()
		else:
			$Interface/UI/Lives.get_child(player).get_child(1).text = "p%s\nhas no lives" % [player + 1]
			
			var alive_player = null
			for i in range(lives.size()):
				if lives[i] > 0:
					if alive_player: # Found more than one alive player, keep going
						return
					alive_player = i
			game_over()


func game_over():
	if state == GAME_OVER:
		return
	
	state = GAME_OVER
	if num_players == 1:
		$Interface/UI/MessageLabel.text = "Game over!"
	else:
		var alive_player = 0
		for i in range(lives.size()):
			if lives[i] > 0:
				alive_player = i
				break
		$Interface/UI/MessageLabel.text = "p%s won!" % [alive_player + 1]
	$Interface/UI/MessageLabel.show()
	$Interface/UI/GameOverHUD.show()
	$Interface/UI/Lives.visible = false
	$Interface/UI/GameOverHUD/VBoxContainer/QuitButton.grab_focus()


func quit_to_main_menu():
	$GameOverTimer.start()


func _on_GameOverTimer_timeout():
	var main_menu = _main_menu.instance()
	get_parent().add_child(main_menu)
	queue_free()


func pause():
	get_tree().paused = true
	$Interface/UI/MessageLabel.text = "Paused"
	$Interface/UI/MessageLabel.show()


func unpause():
	get_tree().paused = false
	$Interface/UI/MessageLabel.hide()


func level_win():
	if state == GAME_OVER:
		return
	
	$Interface/UI/MessageLabel.text = "Spawning new bricks"
	$Interface/UI/MessageLabel.show()
	
	current_level += 1
	if current_level >= $Levels.get_child_count():
		current_level = 0
	print(current_level)
	$NextLevelTimer.start()


func _on_NextLevelTimer_timeout():
	new_level()