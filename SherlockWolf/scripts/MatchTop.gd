extends Control

onready var test_text = $NameLabel
func set_text_name(value):
	test_text.set_text(value)

######### Labels #########
onready var current_label = $CurrentPhase
onready var next_label = $NextPhase

func set_curent_phase(value):
	current_label.set_text(value)

func set_next_phase(value):
	next_label.set_text(value)

######### Timer #########
onready var timer = $TimeDay/Timer/Timer
onready var timer_label = $TimeDay/Timer/Label

signal phase_ended

var current_time

#Utilizar quando iniciar uma fase, atualiza o tempo total e inicia o timer
func start_timer(value):
	set_timer_label(value)
	current_time = value
	timer.start()

#Atualiza o display do tempo
func set_timer_label(value):
	timer_label.set_text(str(value))

#Roda a cada segundo
func _on_Timer_timeout():
	current_time -= 1
	if current_time >= 0:
		set_timer_label(current_time)
	else:
		timer.stop()
		emit_signal("phase_ended")

#Getter para o tempo atual
func get_time():
	return current_time

#Pausar o timer
func stop_timer():
	timer.stop()

######### Dia #########
onready var day_label = $TimeDay/Day/Label

func set_day():
	day_label.set_text("Dia " + str(LobbyManager.get_current_day()))

######### Botões #########
#Trocar se o jogador está vendo a lista de jogadores vivos ou eliminados
func _on_AliveBtn_pressed():
	LobbyManager.set_showing_alive(true)

func _on_DeadBtn_pressed():
	LobbyManager.set_showing_alive(false)

#Botão de pausar
signal game_paused

func _on_PauseBtn_pressed():
	LobbyManager.set_paused(true)
	emit_signal("game_paused")