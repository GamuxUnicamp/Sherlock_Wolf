extends Control

#Tempo do dia em segundos
const DAY_TIMER = 5#80
const VOTING_PATH = "res://scenes/MatchVoting.tscn"

onready var top = $Top
onready var node_list = $PlayersList
onready var popup_quit = $PopupQuit

######### Controle do Período #########
func _ready():
	# warning-ignore:return_value_discarded
	LobbyManager.connect("refresh_list", self, "_on_refresh_list")
	top.connect("phase_ended", self, "_on_phase_ended")
	top.connect("game_paused", self, "_on_game_paused")
	LobbyManager.set_current_phase(LobbyManager.DAY)
	
	#Checando se o jogador tinha pausado
	if LobbyManager.get_paused():
		popup_quit.set_visible(true)
	
	#Coloca os jogadores na tela
	node_list.load_players()
	
	#Muda as informações do topo da tela
	LobbyManager.next_day()
	top.set_day()
	top.set_curent_phase("Manhã")
	top.set_next_phase("Votação")
	
	#Começa o timer para trocar de tela
	top.start_timer(DAY_TIMER)

#Quando o jogador selecionar o botão para exibir jogadores vivos ou eliminados
func _on_refresh_list():
	node_list.load_players()

#Troca pra dia
func _on_phase_ended():
	# warning-ignore:return_value_discarded
	get_tree().change_scene(VOTING_PATH)

######### Seleção de Mensagem #########
func select_player(player_id):
	print(player_id)

######### Botões #########
#Abrir menu de sair
func _on_game_paused():
	popup_quit.set_visible(true)

#Desconectar o jogador
func OkBtn_pressed():
	LobbyManager.disconnect_player()
