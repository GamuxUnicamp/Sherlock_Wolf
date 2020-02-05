extends Control

const MAIN_PATH = "res://scenes/Main.tscn"
const MATCH_PATH = "res://scenes/MatchLobby.tscn"

const server_button = preload("res://resources/instances/ServerButton.tscn")

onready var node_list = $ServerList/VBoxContainer
onready var pop_up = $PopUp

var server_list = {}

func _ready():
	# warning-ignore:return_value_discarded
	LobbyManager.connect("match_found", self, "_on_match_found")
	LobbyManager.find_match()

#Preenchendo a tela com os servidores encontrados
func _on_match_found():
	clear_nodes()
	server_list = LobbyManager.get_servers()
	for i in server_list:
		var node = server_button.instance()
		var node_name = server_list[i]["ip"].format({".": "a"}, ".")
		node.get_node("Name").set_text("Partida de " + server_list[i]["name"])
		node.set_name(node_name)
		node.rect_min_size = Vector2(node_list.get_parent().get_size().x, node.get_size().y)
		node_list.add_child(node)

#Limpa todos os nodes de partidas
func clear_nodes():
	for i in node_list.get_children():
		node_list.remove_child(i)

#Quando apertar um botão pra entrar em um servidor
func join_match(server_ip):
	if LobbyManager.join_match(server_ip):
		# warning-ignore:return_value_discarded
		get_tree().change_scene(MATCH_PATH)
	else:
		pop_up.set_visible(true)

#Botão para sair
func _on_Back_pressed():
	LobbyManager.stop_searching()
	# warning-ignore:return_value_discarded
	get_tree().change_scene(MAIN_PATH)

#Botão do aviso
func _on_PopUpOk_pressed():
	pop_up.set_visible(false)
