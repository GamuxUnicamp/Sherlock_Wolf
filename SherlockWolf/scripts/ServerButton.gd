extends Control

#Chama a função para começar a partida passando o nome do servidor
func _on_Ok_pressed():
	var server_ip = self.get_name().format({"a": "."}, "a")
	var parent_node = get_parent().get_parent().get_parent()
	parent_node.join_match(server_ip)
