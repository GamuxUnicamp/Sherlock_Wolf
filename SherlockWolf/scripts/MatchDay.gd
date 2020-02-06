extends Control

#Tempo do dia em segundos
const DAY_TIMER = 80
const WAIT_TIME = 15 * 1000 #segundos * 1000
const VOTING_PATH = "res://scenes/MatchVoting.tscn"

onready var top = $Top
onready var node_list = $PlayersList
onready var popup_quit = $PopupQuit
onready var popup_night = $PopupNight
onready var popup_info = $PopupNight/Info
onready var popup_timer = $PopupNight/Timer
onready var popup_end = $EndGame
onready var popup_class_info = $InfoBtn

######### Controle do Período #########
func _ready():
	# warning-ignore:return_value_discarded
	LobbyManager.connect("refresh_list", self, "_on_refresh_list")
	LobbyManager.connect("end_game", self, "_on_end_game")
	top.connect("phase_ended", self, "_on_phase_ended")
	top.connect("game_paused", self, "_on_game_paused")
	LobbyManager.set_current_phase(LobbyManager.DAY)
	
	#Checando se o jogador tinha pausado
	if LobbyManager.get_paused():
		popup_quit.set_visible(true)
	
	#Checando se o jogador estava vendo as informações da classe
	if LobbyManager.get_info_showing():
		popup_class_info.set_popup_visibility(true)
	
	#Coloca os jogadores na tela
	node_list.load_players()
	
	#Muda as informações do topo da tela
	LobbyManager.next_day()
	top.set_day()
	top.set_curent_phase("Manhã")
	top.set_next_phase("Votação")
	top.set_text_name(LobbyManager.get_my_info()["name"])
	
	#Mostra quem morreu durante a noite e informações obtidas
	popup_night.set_visible(true)
	popup_info.set_text(LobbyManager.get_skill_info() + "\n" + LobbyManager.get_night_info())
	popup_timer.start()

#Quando o jogador selecionar o botão para exibir jogadores vivos ou eliminados
func _on_refresh_list():
	node_list.load_players()

#Some com a tela de acontecimentos da noite
func _on_Timer_timeout():
	popup_night.set_visible(false)
	
	#Começa o timer para trocar de tela
	top.start_timer(DAY_TIMER)
	OS.delay_msec(50)
	
	#Calcula se houve algum vencedor
	LobbyManager.check_winner()

#Troca pra votação
func _on_phase_ended():
	# warning-ignore:return_value_discarded
	get_tree().change_scene(VOTING_PATH)

#Mostra o fim do jogo
func _on_end_game(value):
	top.stop_timer()
	LobbyManager.set_game_running(false)
	popup_end.change_info(value)
	popup_night.set_visible(false)
	popup_end.set_visible(true)

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
