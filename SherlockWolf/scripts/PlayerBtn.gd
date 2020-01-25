extends Control

#Encontra a cena atual e chama a função de lá
func _on_Button_pressed():
	var parent = get_parent().get_parent().get_parent()
	parent.select_player(int(self.get_name()))
