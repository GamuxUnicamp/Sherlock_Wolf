extends Control

#Tempo da noite em segundos
const NIGHT_TIMER = 5#30
const DAY_PATH = "res://scenes/MatchDay.tscn"

onready var top = $Top
onready var node_list = $PlayersList
onready var popup_quit = $PopupQuit

######### Controle do Período #########
func _ready():
	# warning-ignore:return_value_discarded
	LobbyManager.connect("refresh_list", self, "_on_refresh_list")
	top.connect("phase_ended", self, "_on_phase_ended")
	top.connect("game_paused", self, "_on_game_paused")
	LobbyManager.set_current_phase(LobbyManager.NIGHT)
	
	#Checando se o jogador tinha pausado
	if LobbyManager.get_paused():
		popup_quit.set_visible(true)
	
	#Coloca os jogadores na tela
	node_list.load_players()
	
	#Muda as informações do topo da tela
	top.set_day()
	top.set_curent_phase("Noite")
	top.set_next_phase("Manhã")
	
	#Começa o timer para trocar de tela
	top.start_timer(NIGHT_TIMER)

#Quando o jogador selecionar o botão para exibir jogadores vivos ou eliminados
func _on_refresh_list():
	node_list.load_players()

#Troca pra dia
func _on_phase_ended():
	# warning-ignore:return_value_discarded
	get_tree().change_scene(DAY_PATH)

######### Seleção de Habilidade #########
func select_player(player_id):
	print(player_id)

######### Botões #########
#Abrir menu de sair
func _on_game_paused():
	popup_quit.set_visible(true)

#Desconectar o jogador
func OkBtn_pressed():
	LobbyManager.disconnect_player()