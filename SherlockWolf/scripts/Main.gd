extends Control

const SERVER_LOBBY = "res://scenes/ServerLobby.tscn"
const MATCH_LOBBY = "res://scenes/MatchLobby.tscn"

onready var popup_error = $PopUpError
onready var popup_error2 = $PopUpError2

onready var popup_join = $PopUpJoin
onready var name_join = $PopUpJoin/BG/Name

onready var popup_host = $PopUpHost
onready var name_host = $PopUpHost/BG/Name

func _ready():
	# warning-ignore:return_value_discarded
	LobbyManager.connect("server_down", self, "_on_server_down")

#Botão de procurar partida
func _on_Join_pressed():
	popup_join.set_visible(true)

#Ok na tela de procurar partida
func _on_BtnOkJoin_pressed():
	#Testa se o nome tem 3 letras ou mais
	var p_name = name_join.get_text()
	if p_name.length() < 3:
		return
	
	LobbyManager.set_name(p_name)
	# warning-ignore:return_value_discarded
	get_tree().change_scene(SERVER_LOBBY)

#Cancelar na tela de procurar partida
func _on_BtnCancelJoin_pressed():
	popup_join.set_visible(false)

#Botão de criar partida
func _on_Host_pressed():
	popup_host.set_visible(true)

#Ok na tela de criar partida
func _on_BtnOkHost_pressed():
	#Testa se o nome tem 3 letras ou mais
	var p_name = name_host.get_text()
	if p_name.length() < 3:
		return
	
	if LobbyManager.create_host():
		LobbyManager.set_name(p_name)
		# warning-ignore:return_value_discarded
		get_tree().change_scene(MATCH_LOBBY)
	else:
		popup_error.set_visible(true)

#Cancelar na tela de criar partida
func _on_BtnCancelHost_pressed():
	popup_host.set_visible(false)

#Botão do aviso de erro do servidor
func _on_BtnError_pressed():
	popup_error.set_visible(false)

#Pegando o sinal do servidor ter fechado
func _on_server_down():
	popup_error2.set_visible(true)

#Fechando a mensagem de erro
func _on_BtnError2_pressed():
	popup_error2.set_visible(false)
