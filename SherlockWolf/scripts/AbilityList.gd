extends ScrollContainer

const player_tag = preload("res://resources/instances/PlayerBtn.tscn")

onready var node_list = $VBoxContainer

#Carrega todos os nomes dos jogadores
func load_players():
	clear_nodes()
	var player_id = LobbyManager.get_my_id()
	var showing_alive = LobbyManager.get_showing_alive()
	var player_list = LobbyManager.get_players()
	var player_ok
	
	for i in player_list:
		player_ok = true
		#Mostra jogadores vivos se selecionou mostrar os vivos
		if showing_alive and not player_list[i]["alive"]:
			player_ok = false
		
		#Mostra jogadores mortos se selecionou mostrar os mortos
		if not showing_alive and player_list[i]["alive"]:
			player_ok = false
		
		if player_ok:
			var node = player_tag.instance()
			node.set_name(str(i))
			node.get_node("Name").set_text(player_list[i]["name"])
			node.rect_min_size = Vector2(node_list.get_parent().get_size().x, node.get_size().y)
			
			#Se estiver na votação mostra o número de votos
			if LobbyManager.get_current_phase() == LobbyManager.VOTING:
				node.get_node("Vote").set_text(str(player_list[i]["votes"]))
			
			#Passa o filtro específico da classe para poder ser selecionado
			if not AbilitiesManager.display_names(i, player_list[i], player_id, player_list[player_id]):
				node.get_node("Button").set_disabled(true)
			
			#Se estiver morto, tira o botão completamente
			if (not player_list[i]["alive"]) or (not player_list[player_id]["alive"]):
				node.get_node("Button").set_visible(false)
			node_list.add_child(node)

#Limpa os nomes dos jogadores
func clear_nodes():
	for i in node_list.get_children():
		node_list.remove_child(i)
