extends Node

######### Exibir botão nos jogadores da lista #########
func display_names(target_id, target_info, player_id, player_info):
	var player_class = player_info["class"]
	var player_alingment = LobbyManager.get_class_alignment(player_class)
	match player_alingment:
		"Cidade":
			match player_class:
				"leader":
					#Pode selecionar apenas ele mesmo e se não tiver revelado
					if not player_info["revealed"]:
						return only_self(target_id, player_id)
					else:
						return false
				
				"detective":
					#Pode selecionar todos menos ele mesmo
					return all_but_self(target_id, player_id)
				
				"observer":
					#Pode selecionar todos
					return true
				
				"messenger":
					#Pode selecionar todos menos ele mesmo
					return all_but_self(target_id, player_id)
				
				"hunter":
					#Pode selecionar todos menos ele mesmo (nunca interage no primeiro dia)
					var actions = player_info["actions"]
					if LobbyManager.get_current_day() != 0 and actions > 0:
						return all_but_self(target_id, player_id)
					else:
						return false
				
				"captain":
					#Pode selecionar todos menos ele mesmo
					return all_but_self(target_id, player_id)
				
				"alchemist":
					#Pode selecionar todos
					return true
				
				"guard":
					#Pode selecionar todos menos ele mesmo
					return all_but_self(target_id, player_id)
		
		"Lobisomens":
			match player_class:
				"werewolf":
					#Apenas mostra os jogadores da cidade e neutros
					return town_only(target_info)
				
				"sorcerer":
					#Apenas mostra os jogadores da cidade, neutros e o lobisomem
					return sorcerer_display(target_info)
				
				"elder":
					#Apenas mostra os jogadores dos lobisomens
					return evil_only(target_info)
				
				"mimic":
					#Decidir
					return false
				
				"cultist":
					#Apenas mostra os jogadores da cidade e neutros
					return town_only(target_info)
		
		"Neutro":
			match player_class:
				"fugitive":
					#Pode selecionar todos menos ele mesmo
					return all_but_self(target_id, player_id)
				
				"outsider":
					#Pode selecionar qualquer jogador eliminado
					return outsider_display(target_info)
				
				"avenger", "stalker", "suicidal":
					#Não possui habilidade durante a noite
					return false

#Apenas o próprio jogador é selecionável
func only_self(target_id, player_id):
	if target_id == player_id:
		return true
	else:
		return false

#Apenas o próprio jogador não é selecionável
func all_but_self(target_id, player_id):
	if target_id == player_id:
		return false
	else:
		return true

#Apenas os da Cidade e Neutros são selecionáveis
func town_only(target_info):
	var target_class = target_info["class"]
	var target_alingment = LobbyManager.get_class_alignment(target_class)
	if target_alingment == "Cidade" or target_alingment == "Neutro":
		return true
	else:
		return false

#Apenas os Lobisomens são selecionáveis
func evil_only(target_info):
	var target_class = target_info["class"]
	var target_alingment = LobbyManager.get_class_alignment(target_class)
	if target_alingment == "Lobisomens":
		return true
	else:
		return false

#Apenas da cidade, neutros e o lobisomem são selecionáveis
func sorcerer_display(target_info):
	var target_class = target_info["class"]
	var target_alingment = LobbyManager.get_class_alignment(target_class)
	if target_alingment == "Cidade" or target_alingment == "Neutro":
		return true
	elif target_alingment == "Lobisomens" and target_class == "werewolf":
		return true
	else:
		return false

#Apenas jogadores já eliminados
func outsider_display(target_info):
	if not target_info["alive"]:
		return true
	else:
		return false

######### Mandar pedido para o servidor quando o jogador clica o botão #########
func request_ability(target_id, target_info, player_id, player_info):
	var info = {"target_id": target_id, "target_info": target_info, "player_info": player_info}
	var player_class = player_info["class"]
	var player_alingment = LobbyManager.get_class_alignment(player_class)
	match player_alingment:
		"Cidade":
			match player_class:
				"leader", "detective", "observer", "messenger":
					LobbyManager.request_skill_queue("1", player_id, info)
				
				"hunter":
					LobbyManager.request_skill_queue("3", player_id, info)
				
				"captain":
					LobbyManager.request_skill_queue("5", player_id, info)
				
				"alchemist", "guard":
					LobbyManager.request_skill_queue("4", player_id, info)
		
		"Lobisomens":
			match player_class:
				"werewolf":
					LobbyManager.request_skill_queue("3", player_id, info)
				
				"sorcerer":
					LobbyManager.request_skill_queue("4", player_id, info)
				
				"elder":
					LobbyManager.request_skill_queue("2", player_id, info)
				
				"mimic", "cultist":
					LobbyManager.request_skill_queue("1", player_id, info)
		
		"Neutro":
			match player_class:
				"fugitive":
					LobbyManager.request_skill_queue("4", player_id, info)
				
				"outsider", "avenger", "stalker", "suicidal":
					LobbyManager.request_skill_queue("1", player_id, info)

######### Executar habilidade #########
func confirm_ability(target_id, target_info, player_id, player_info):
	var player_class = player_info["class"]
	var player_alingment = LobbyManager.get_class_alignment(player_class)
	
	#Se o jogador foi preso durante essa noite, não executa skill
	if LobbyManager.get_roleblocked(player_id):
		LobbyManager.set_night_info("Você foi preso e não conseguiu executar sua habilidade.")
		return
	
	match player_alingment:
		"Cidade":
			match player_class:
				"leader":
					if not LobbyManager.get_revealed(player_id):
						leader_confirm(player_id, player_info)
				
				"detective":
					detective_confirm(target_info, player_id)
				
				"observer":
					observer_confirm()
				
				"messenger":
					messenger_confirm()
				
				"hunter":
					hunter_confirm(target_id, target_info, player_id, player_info)
				
				"captain":
					LobbyManager.set_roleblocked(target_id, true)
				
				"alchemist":
					LobbyManager.set_healed(target_id, true)
				
				"guard":
					LobbyManager.set_guarded(target_id, true, player_id)
		
		"Lobisomens":
			match player_class:
				"werewolf":
					werewolf_confirm(target_id, target_info, player_id)
				
				_:
					return
		
		"Neutro":
			match player_class:
				"stalker":
					return
				
				_:
					return

func leader_confirm(player_id, player_info):
	LobbyManager.set_revealed(player_id, true)
	LobbyManager.set_night_info(player_info["name"] + " revelou que é o Líder da Cidade.")
	LobbyManager.set_skill_info(player_id, "Você revelou que é o Líder da Cidade.")

func detective_confirm(target_info, player_id):
	var target_name = target_info["name"]
	var target_class = target_info["class"]
	var target_alingment = LobbyManager.get_class_alignment(target_class)
	var text = ""
	
	match target_alingment:
		"Cidade":
			text = target_name + " é da Cidade."
		
		"Lobisomens":
			if target_class == "werewolf":
				text = target_name + " é da Cidade."
			else:
				text = target_name + " é dos Lobisomens."
		
		"Neutro":
			text = target_name + " é neutro."
		
	LobbyManager.set_skill_info(player_id, text)

func observer_confirm():
	pass

func messenger_confirm():
	pass

func hunter_confirm(target_id, target_info, player_id, player_info):
	var target_class = target_info["class"]
	var target_alingment = LobbyManager.get_class_alignment(target_class)
	var actions = player_info["actions"]
	var text = ""
	
	#Tira uma ação do jogador
	LobbyManager.set_actions(player_id, actions - 1)
	
	#Caso o alvo tenha um guarda
	if LobbyManager.get_guarded(target_id):
		var guard_id = LobbyManager.get_guard(target_id)
		
		#Checa se o guarda foi curado
		if LobbyManager.get_healed(guard_id):
			text = "Seu alvo foi protegido e você não conseguiu eliminar o Guarda. Tiros restantes: " + str(actions)
			LobbyManager.set_skill_info(guard_id, "Você protegeu seu alvo mas foi curado.")
		else:
			text = "Seu alvo foi protegido e você eliminou um Guarda."
			LobbyManager.set_player_dead(guard_id)
			LobbyManager.set_night_info(LobbyManager.get_player_name(guard_id) + " foi eliminado.")
			LobbyManager.set_skill_info(guard_id, "Você protegeu seu alvo e foi eliminado.")
			LobbyManager.set_actions(player_id, 0)
			text += "\nVocê acertou um jogador da Cidade, não poderá mais atirar."
		
		#Checa se o caçador foi curado
		if LobbyManager.get_healed(player_id):
			text += "\nVocê foi curado e sobreviveu um ataque."
		else:
			text += "\nVocê foi eliminado."
			LobbyManager.set_player_dead(player_id)
			LobbyManager.set_night_info(LobbyManager.get_player_name(player_id) + " foi eliminado.")
	
	#Caso o alvo tenha sido curado
	elif LobbyManager.get_healed(target_id):
		text = "Não foi possível eliminar " + target_info["name"] + ". Tiros restantes: " + str(actions)
		LobbyManager.set_skill_info(target_id, "Você foi curado e sobreviveu um ataque.")
	else:
		text = "Você eliminou " + target_info["name"] + "."
		LobbyManager.set_player_dead(target_id)
		LobbyManager.set_night_info(target_info["name"] + " foi eliminado.")
		LobbyManager.set_skill_info(target_id, "Você foi eliminado.")
		
		if target_alingment == "Cidade":
			LobbyManager.set_actions(player_id, 0)
			text += "\nVocê acertou um jogador da Cidade, não poderá mais atirar."
		else:
			text += " Tiros restantes: " + str(actions)
	
	LobbyManager.set_skill_info(player_id, text)

func werewolf_confirm(target_id, target_info, player_id):
	var text = ""
	
	#Caso o alvo tenha um guarda
	if LobbyManager.get_guarded(target_id):
		var guard_id = LobbyManager.get_guard(target_id)
		
		#Checa se o guarda foi curado
		if LobbyManager.get_healed(guard_id):
			text = "Seu alvo foi protegido e você não conseguiu eliminar o Guarda."
			LobbyManager.set_skill_info(guard_id, "Você protegeu seu alvo mas foi curado.")
		else:
			text = "Seu alvo foi protegido e você eliminou um Guarda."
			LobbyManager.set_player_dead(guard_id)
			LobbyManager.set_night_info(LobbyManager.get_player_name(guard_id) + " foi eliminado.")
			LobbyManager.set_skill_info(guard_id, "Você protegeu seu alvo e foi eliminado.")
		
		#Checa se o lobiomem foi curado
		if LobbyManager.get_healed(player_id):
			text += "\nVocê foi curado e sobreviveu um ataque."
		else:
			text += "\nVocê foi eliminado."
			LobbyManager.set_player_dead(player_id)
			LobbyManager.set_night_info(LobbyManager.get_player_name(player_id) + " foi eliminado.")
	
	#Caso o alvo tenha sido curado
	elif LobbyManager.get_healed(target_id):
		text = "Não foi possível eliminar " + target_info["name"] + "."
		LobbyManager.set_skill_info(target_id, "Você foi curado e sobreviveu um ataque.")
	else:
		text = "Eliminou " + target_info["name"] + " com sucesso."
		LobbyManager.set_player_dead(target_id)
		LobbyManager.set_night_info(target_info["name"] + " foi eliminado.")
		LobbyManager.set_skill_info(target_id, "Você foi eliminado.")
	
	LobbyManager.set_skill_info(player_id, text)