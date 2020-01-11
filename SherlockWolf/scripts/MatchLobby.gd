extends Control

onready var node_list = $PlayersList
onready var timer = $Timer
onready var host_btns = $HostBtns
onready var client_btns = $ClientBtns

var player_list
var creating_match

func _ready():
	LobbyManager.connect("changed_lobby", self, "_on_changed_lobby")
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
	var n = 1
	for i in player_list:
		var node = node_list.get_node(str(n))
		node.set_text(player_list[i]["name"])
		node.set_visible(true)
		n += 1
		if n > 5:
			break

#Limpa os nomes dos jogadores
func clear_nodes():
	for i in node_list.get_children():
		i.set_visible(false)

#Botão para sair
func _on_Quit_pressed():
	LobbyManager.disconnect_player()

#Timer para chamar novos jogadores
func _on_Timer_timeout():
	LobbyManager.find_player()
