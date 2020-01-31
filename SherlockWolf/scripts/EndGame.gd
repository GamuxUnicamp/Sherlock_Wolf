extends Control

onready var match_info = $MatchInfo

#Mudar o texto de quem ganhou
func change_info(value):
	if value == "Lobisomens":
		match_info.set_text("Os Lobisomens ganharam!")
	else:
		match_info.set_text("A Cidade ganhou!")
	
	#Mostrar a lista dos jogadores que ganharam

func _on_Button_pressed():
	LobbyManager.disconnect_player()
