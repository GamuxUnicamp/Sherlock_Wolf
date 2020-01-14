extends Control

const MAIN_PATH = "res://scenes/Main.tscn"
const MATCH_PATH = "res://scenes/MatchLobby.tscn"

onready var node_list = $PlayersList
const player_tag = preload("res://resources/instances/PlayerTag.tscn")

onready var node_list = $PlayersList/VBoxContainer
onready var timer = $Timer
onready var host_btns = $HostBtns
onready var client_btns = $ClientBtns

var player_list
var creating_match

func _ready():
	LobbyManager.connect("changed_lobby", self, "_on_changed_lobby")
	LobbyManager.connect("full_lobby", self, "_on_full_lobby")
	#Checando se é cliente ou servidor
	creating_match = LobbyManager.get_creating()
	if creating_match:
		timer.start()
		host_btns.set_visible(true)
	else:
		client_btns.set_visible(true)
	load_players()

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

#Limpa os nomes dos jogadores
func clear_nodes():
	for i in node_list.get_children():
		node_list.remove_child(i)

#Botão para sair
func _on_Quit_pressed():
	LobbyManager.disconnect_player()

func _on_Start_pressed():
	LobbyManager.start_game()

#Timer para chamar novos jogadores
func _on_Timer_timeout():
	LobbyManager.find_player()

#Chamar função de começar a partida
func _on_full_lobby():
	pass