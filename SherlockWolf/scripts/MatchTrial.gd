extends Control

#Tempo do dia em segundos
const TRIAL_TIMER = 5#20
const VOTING_TIMER = 5#15
const COOLDOWN = 5
const NIGHT_PATH = "res://scenes/MatchNight.tscn"

onready var top = $Top
onready var popup_quit = $PopupQuit
onready var trial_warning = $Trial/Warning

onready var defense_node = $Trial/Defense
onready var defense_player = $Trial/Defense/Player
onready var defense_others = $Trial/Defense/Others

onready var voting_node = $Trial/Voting
onready var voting_player = $Trial/Voting/Player
onready var voting_others = $Trial/Voting/Others

onready var result_node = $Trial/Result

onready var btn_guilty = $Trial/Voting/Others/GuiltyBtn
onready var btn_innocnet = $Trial/Voting/Others/InnocentBtn
onready var btn_abstain = $Trial/Voting/Others/AbstainBtn

var trial_ended = false
var on_cooldown = false

######### Controle do Período #########
func _ready():
# warning-ignore:return_value_discarded
	LobbyManager.connect("trial_ended", self, "_on_trial_ended")
	top.connect("phase_ended", self, "_on_phase_ended")
	top.connect("game_paused", self, "_on_game_paused")
	LobbyManager.set_current_phase(LobbyManager.TRIAL)
	
	#Checando se o jogador tinha pausado
	if LobbyManager.get_paused():
		popup_quit.set_visible(true)
	
	#Atualiza quem é o jogador selecionado
	var player_list = LobbyManager.get_players()
	var player_id = LobbyManager.get_trial_id()
	LobbyManager.reset_trial()
	
	#Atualizando o texto exibido
	var text = player_list[player_id]["name"] + " está em julgamento!"
	trial_warning.set_text(text)
	
	#Atualizando as informações da tela, se o jogador pode votar ou não
	if LobbyManager.get_my_id() == player_id:
		defense_player.set_visible(true)
		voting_player.set_visible(true)
		defense_others.set_visible(false)
		voting_others.set_visible(false)
	else:
		defense_player.set_visible(false)
		voting_player.set_visible(false)
		defense_others.set_visible(true)
		voting_others.set_visible(true)
	
	#Atualizando se o jogador está morto, não pode votar
	if not player_list[LobbyManager.get_my_id()]["alive"]:
		defense_player.set_visible(false)
		defense_others.set_visible(true)
		voting_player.set_visible(true)
		voting_others.set_visible(false)
	
	#Muda as informações do topo da tela
	LobbyManager.next_day()
	top.set_day()
	top.set_curent_phase("Julgamento")
	top.set_next_phase("Noite")
	
	#Começa o timer para trocar de tela
	top.start_timer(TRIAL_TIMER)

#Quando acabar o tempo de defesa, inicia a segunda votação
func _on_phase_ended():
	#A defesa do jogador acabou
	if not trial_ended and not on_cooldown:
		top.start_timer(VOTING_TIMER)
		trial_ended = true
		
		defense_node.set_visible(false)
		voting_node.set_visible(true)
	#A votação acabou
	elif trial_ended and not on_cooldown:
		disable_buttons()
		LobbyManager.get_sentence()
		top.start_timer(COOLDOWN)
		on_cooldown = true
	#O tempo para resolução acabou
	else:
		# warning-ignore:return_value_discarded
		get_tree().change_scene(NIGHT_PATH)

######### Seleção de Voto #########
var vote = 0 #(-1) = guilty; 0 = abstained; 1 = innocent
func _on_GuiltyBtn_pressed():
	#Se tiver votado inocente, remove o voto
	_on_AbstainBtn_pressed()
	
	#Vota culpado
	vote = (-1)
	LobbyManager.trial_guilty(1)
	
	#Apaga o botão
	display_buttons()
	btn_guilty.set_disabled(true)

func _on_InnocentBtn_pressed():
	#Se tiver votado culpado, remove o voto
	_on_AbstainBtn_pressed()
	
	#Vota inocente
	vote = 1
	LobbyManager.trial_innocent(1)
	
	#Apaga o botão
	display_buttons()
	btn_innocnet.set_disabled(true)

func _on_AbstainBtn_pressed():
	#Se tiver votado culpado, remove o voto
	if vote == (-1):
		LobbyManager.trial_guilty(-1)
	
	#Se tiver votado inocente, remove o voto
	if vote == 1:
		LobbyManager.trial_innocent(-1)
	
	#Apaga o botão
	display_buttons()
	btn_abstain.set_disabled(true)
	vote = 0

#Recebendo a atualização do final do julgamento
func _on_trial_ended(sentence):
	#Atualizar a tela
	var text
	if sentence == (-1):
		text = "Culpado"
	else:
		text = "Inocente"
	result_node.get_node("LabelResult").set_text(text)
	voting_node.set_visible(false)
	result_node.set_visible(true)

######### Botões #########
#Abrir menu de sair
func _on_game_paused():
	popup_quit.set_visible(true)

#Desconectar o jogador
func OkBtn_pressed():
	LobbyManager.disconnect_player()

#Controla os botões da votação
func display_buttons():
	btn_abstain.set_disabled(false)
	btn_guilty.set_disabled(false)
	btn_innocnet.set_disabled(false)

func disable_buttons():
	btn_abstain.set_disabled(true)
	btn_guilty.set_disabled(true)
	btn_innocnet.set_disabled(true)
