extends Control

#Tempo da noite em segundos
const NIGHT_TIMER = 30#5
const DAY_PATH = "res://scenes/MatchDay.tscn"

onready var top = $Top
onready var node_list = $PlayersList
onready var popup_quit = $PopupQuit

######### Controle do Período #########
func _ready():
	# warning-ignore:return_value_discarded
	LobbyManager.connect("refresh_list", self, "_on_refresh_list")
	# warning-ignore:return_value_discarded
	LobbyManager.connect("night_ended", self, "_on_night_ended")
	top.connect("phase_ended", self, "_on_phase_ended")
	top.connect("game_paused", self, "_on_game_paused")
	LobbyManager.set_current_phase(LobbyManager.NIGHT)
	LobbyManager.clear_skill_queue()
	LobbyManager.set_night(true)
	LobbyManager.set_dead_count(0)
	LobbyManager.reset_skill_info()
	
	#Checando se o jogador tinha pausado
	if LobbyManager.get_paused():
		popup_quit.set_visible(true)
	
	#Coloca os jogadores na tela
	node_list.load_players()
	
	#Muda as informações do topo da tela
	top.set_day()
	top.set_curent_phase("Noite")
	top.set_next_phase("Manhã")
	top.set_text_name(LobbyManager.get_my_info()["name"])
	
	#Começa o timer para trocar de tela
	top.start_timer(NIGHT_TIMER)

#Quando o jogador selecionar o botão para exibir jogadores vivos ou eliminados
func _on_refresh_list():
	node_list.load_players()

#Acabou o tempo da noite
func _on_phase_ended():
	LobbyManager.solve_skills()

#Troca pra dia
func _on_night_ended():
	# warning-ignore:return_value_discarded
	get_tree().change_scene(DAY_PATH)

######### Seleção de Habilidade #########
func select_player(target_id):
	var target_info = LobbyManager.get_player_info(target_id)
	var player_id = LobbyManager.get_my_id()
	var player_info = LobbyManager.get_my_info()
	AbilitiesManager.request_ability(target_id, target_info, player_id, player_info)

######### Botões #########
#Abrir menu de sair
func _on_game_paused():
	popup_quit.set_visible(true)

#Desconectar o jogador
func OkBtn_pressed():
	LobbyManager.disconnect_player()