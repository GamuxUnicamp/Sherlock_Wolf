extends Control

onready var match_info = $MatchInfo

#Mudar o texto de quem ganhou
func change_info(value):
	
	match value:
		"Lobisomens":
			match_info.set_text("Os Lobisomens ganharam!")
		"Cidade":
			match_info.set_text("A Cidade ganhou!")
		"Empate":
			match_info.set_text("Todos foram eliminados. Foi um empate!")
	
	#Mostrar a lista dos jogadores que ganharam

func _on_Button_pressed():
	LobbyManager.disconnect_player()
