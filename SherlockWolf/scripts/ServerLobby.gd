extends Control

const MAIN_PATH = "res://scenes/Main.tscn"
const MATCH_PATH = "res://scenes/MatchLobby.tscn"

onready var node_list = $ServerList
onready var pop_up = $PopUp

var server_list = {}

func _ready():
	LobbyManager.connect("match_found", self, "_on_match_found")
	LobbyManager.find_match()

#Preenchendo a tela com os servidores encontrados
func _on_match_found():
	clear_nodes()
	server_list = LobbyManager.get_servers()
	var n = 1
	for i in server_list:
		var node = node_list.get_node(str(n))
		node.get_node("Name").set_text(server_list[i]["name"])
		node.get_node("Ip").set_text(server_list[i]["ip"])
		node.set_visible(true)
		n += 1
		if n > 5:
			break

#Limpa todos os nodes de partidas
func clear_nodes():
	for i in node_list.get_children():
		i.set_visible(false)

#Botões para entrar em uma partida
func _on_Ok1_pressed():
	if LobbyManager.join_match(node_list.get_node("1").get_node("Ip").get_text()):
		get_tree().change_scene(MATCH_PATH)
	else:
		pop_up.set_visible(true)

func _on_Ok2_pressed():
	if LobbyManager.join_match(node_list.get_node("2").get_node("Ip").get_text()):
		get_tree().change_scene(MATCH_PATH)
	else:
		pop_up.set_visible(true)

func _on_Ok3_pressed():
	if LobbyManager.join_match(node_list.get_node("3").get_node("Ip").get_text()):
		get_tree().change_scene(MATCH_PATH)
	else:
		pop_up.set_visible(true)

func _on_Ok4_pressed():
	if LobbyManager.join_match(node_list.get_node("4").get_node("Ip").get_text()):
		get_tree().change_scene(MATCH_PATH)
	else:
		pop_up.set_visible(true)

func _on_Ok5_pressed():
	if LobbyManager.join_match(node_list.get_node("5").get_node("Ip").get_text()):
		get_tree().change_scene(MATCH_PATH)
	else:
		pop_up.set_visible(true)

#Botão para sair
func _on_Back_pressed():
	LobbyManager.stop_searching()
	get_tree().change_scene(MAIN_PATH)

#Botão do aviso
func _on_PopUpOk_pressed():
	pop_up.set_visible(false)
