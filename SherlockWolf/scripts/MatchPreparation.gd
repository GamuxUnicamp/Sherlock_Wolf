extends Control

#Tempo de preparação em segundos
const PREPARE_TIMER = 5#10
const NIGHT_PATH = "res://scenes/MatchNight.tscn"

onready var name_label = $Class/ClassName
onready var description_label = $Class/ClassDescription
onready var top = $Top
onready var popup_quit = $PopupQuit

func _ready():
	top.connect("phase_ended", self, "_on_phase_ended")
	top.connect("game_paused", self, "_on_game_paused")
	
	#Mostra a classe e informações para o jogador 
	var info = LobbyManager.get_my_info()
	var classes = LobbyManager.get_classes()
	
	var c = info["class"]
	var c_name = classes[c]["name"]
	var c_description = classes[c]["skill"]
	var c_alignment = classes[c]["alignment"]
	name_label.set_text(c_name + " (" + c_alignment + ")")
	description_label.set_text(c_description)
	
	#Troca as labels do topo da tela
	top.set_day()
	top.set_curent_phase("Descubra sua classe")
	top.set_next_phase("Noite")
	
	#Começa o timer para trocar de tela
	top.start_timer(PREPARE_TIMER)

#Troca para a noite
func _on_phase_ended():
	# warning-ignore:return_value_discarded
	get_tree().change_scene(NIGHT_PATH)

#Abrir menu de sair
func _on_game_paused():
	popup_quit.set_visible(true)

#Desconectar o jogador
func OkBtn_pressed():
	LobbyManager.disconnect_player()