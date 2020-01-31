extends Node

######### Exibir botão nos jogadores da lista #########
func display_names(target_id, target_info, player_id, player_info):
	var player_class = player_info["class"]
	var player_alingment = LobbyManager.get_class_alignment(player_class)
	match player_alingment:
		"Cidade":
			match player_class:
				"leader":
					print("Líder")
				
				_:
					return false
		
		"Lobisomens":
			match player_class:
				"werewolf":
					return werewolf_display(target_info)
				
				_:
					return false
		
		"Neutro":
			match player_class:
				"stalker":
					print("Stalker")
				
				_:
					return false

func werewolf_display(target_info):
	var target_class = target_info["class"]
	var target_alingment = LobbyManager.get_class_alignment(target_class)
	if target_alingment == "Lobisomens":
		return false
	else:
		return true

######### Mandar pedido para o servidor quando o jogador clica o botão #########
func request_ability(target_id, target_info, player_id, player_info):
	var info = {"target_id": target_id, "target_info": target_info, "player_info": player_info}
	var player_class = player_info["class"]
	var player_alingment = LobbyManager.get_class_alignment(player_class)
	match player_alingment:
		"Cidade":
			match player_class:
				"leader":
					print("Líder")
				
				_:
					return
		
		"Lobisomens":
			match player_class:
				"werewolf":
					LobbyManager.request_skill_queue("3", player_id, info)
				
				_:
					return
		
		"Neutro":
			match player_class:
				"stalker":
					print("Stalker")
				
				_:
					return

######### Executar habilidade #########
func confirm_ability(target_id, target_info, player_id, player_info):
	var player_class = player_info["class"]
	var player_alingment = LobbyManager.get_class_alignment(player_class)
	match player_alingment:
		"Cidade":
			match player_class:
				"leader":
					print("Líder")
				
				_:
					return
		
		"Lobisomens":
			match player_class:
				"werewolf":
					werewolf_confirm(target_id, player_id)
				
				_:
					return
		
		"Neutro":
			match player_class:
				"stalker":
					print("Stalker")
				
				_:
					return

func werewolf_confirm(target_id, player_id):
	LobbyManager.set_skill_info(player_id, "Matou com sucesso")
	LobbyManager.set_player_dead(target_id)