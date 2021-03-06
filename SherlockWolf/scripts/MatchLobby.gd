extends Control

const MAIN_PATH = "res://scenes/Main.tscn"
const MATCH_PATH = "res://scenes/MatchLobby.tscn"

const player_tag = preload("res://resources/instances/PlayerTag.tscn")

onready var node_list = $PlayersList/VBoxContainer
onready var timer = $Timer
onready var client_btns = $ClientBtns
onready var host_btns = $HostBtns
onready var start_btn = $HostBtns/Start
onready var label_min = $HostBtns/LabelMin

var player_list
var creating_match

func _ready():
	# warning-ignore:return_value_discarded
	LobbyManager.connect("changed_lobby", self, "_on_changed_lobby")
	# warning-ignore:return_value_discarded
	LobbyManager.connect("full_lobby", self, "_on_full_lobby")
	#Checando se é cliente ou servidor
	creating_match = LobbyManager.get_creating()
	if creating_match:
		timer.start()
		host_btns.set_visible(true)
	else:
		client_btns.set_visible(true)
	load_players()
	
	LobbyManager.clear_info()

func _on_changed_lobby():
	load_players()

#Carrega todos os nomes dos jogadores conectados
func load_players():
	clear_nodes()
	player_list = LobbyManager.get_players()
	for i in player_list:
		var node = player_tag.instance()
		node.get_node("Name").set_text(player_list[i]["name"])
		node.rect_min_size = Vector2(node_list.get_parent().get_size().x, node.get_size().y)
		node_list.add_child(node)
	
	if LobbyManager.get_players_quant() < 5:
		label_min.set_visible(true)
		start_btn.set_disabled(true)
	else:
		label_min.set_visible(false)
		start_btn.set_disabled(false)

#Limpa os nomes dos jogadores
func clear_nodes():
	for i in node_list.get_children():
		node_list.remove_child(i)

#Botão para sair
func _on_Quit_pressed():
	LobbyManager.disconnect_player()

#Botão para começar o jogo
func _on_Start_pressed():
	LobbyManager.start_game()

#Timer para chamar novos jogadores
func _on_Timer_timeout():
	LobbyManager.find_player()

#Chamar função de começar a partida se a sala estiver cheia
func _on_full_lobby():
	LobbyManager.start_game()