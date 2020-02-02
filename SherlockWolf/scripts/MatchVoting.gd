extends Control

#Tempo da votação em segundos
const VOTE_TIMER = 20
const NIGHT_PATH = "res://scenes/MatchNight.tscn"
const TRIAL_PATH = "res://scenes/MatchTrial.tscn"

onready var top = $Top
onready var node_list = $PlayersList
onready var popup_quit = $PopupQuit

######### Controle do Período #########
func _ready():
	# warning-ignore:return_value_discarded
	LobbyManager.connect("refresh_list", self, "_on_refresh_list")
	top.connect("phase_ended", self, "_on_phase_ended")
	top.connect("game_paused", self, "_on_game_paused")
	LobbyManager.set_current_phase(LobbyManager.VOTING)
	
	#Checando se o jogador tinha pausado
	if LobbyManager.get_paused():
		popup_quit.set_visible(true)
	
	#Coloca os jogadores na tela
	node_list.load_players()
	
	#Muda as informações do topo da tela
	top.set_day()
	top.set_curent_phase("Votação")
	top.set_next_phase("Noite")
	top.set_text_name(LobbyManager.get_my_info()["name"])
	
	#Começa o timer para trocar de tela
	top.start_timer(VOTE_TIMER)

#Quando o jogador selecionar o botão para exibir jogadores vivos ou eliminados
func _on_refresh_list():
	node_list.load_players()

#Troca pra noite
func _on_phase_ended():
	LobbyManager.reset_votes()
	# warning-ignore:return_value_discarded
	get_tree().change_scene(NIGHT_PATH)

######### Seleção de Votação #########
var selected_player = 0
func select_player(player_id):
	#Se o jogador for o servidor
	if LobbyManager.get_my_id() == 1:
		#Selecionou alguem e sem ninguem selecionado
		if selected_player == 0:
			selected_player = player_id
			vote_player(selected_player)
		#Selecionou a mesma pessoa
		elif selected_player == player_id:
			selected_player = 0
			unvote_player(player_id)
		#Selecionou alguem com outro selecionado
		else:
			unvote_player(selected_player)
			vote_player(player_id)
			selected_player = player_id
	#Se o jogador for um cliente
	else:
		#Selecionou alguem e sem ninguem selecionado
		if selected_player == 0:
			selected_player = player_id
			rpc_id(1, "vote_player", selected_player)
		#Selecionou a mesma pessoa
		elif selected_player == player_id:
			selected_player = 0
			rpc_id(1, "unvote_player", player_id)
		#Selecionou alguem com outro selecionado
		else:
			rpc_id(1, "unvote_player", selected_player)
			rpc_id(1, "vote_player", player_id)
			selected_player = player_id

#Adiciona o voto no jogador
remote func vote_player(player_id):
	#Se o jogador atingiu votos suficientes
	if LobbyManager.add_vote(player_id):
		rpc("judge_player", player_id)
		judge_player(player_id)

#Remover um voto do jogador
remote func unvote_player(player_id):
	LobbyManager.delete_vote(player_id)

#Quando o jogador receber votos suficientes
remote func judge_player(player_id):
	LobbyManager.reset_votes()
	#salva o id do jogador e vai pra tela de votação
	LobbyManager.set_trial_id(player_id)
	# warning-ignore:return_value_discarded
	get_tree().change_scene(TRIAL_PATH)

######### Botões #########
#Abrir menu de sair
func _on_game_paused():
	popup_quit.set_visible(true)

#Desconectar o jogador
func OkBtn_pressed():
	LobbyManager.disconnect_player()
