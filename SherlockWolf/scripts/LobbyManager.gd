extends Node

const SERVER_KEY = "sherlockwolfpartida"
const MAIN_PATH = "res://scenes/Main.tscn"
const SERVER_PATH = "res://scenes/ServerLobby.tscn"
const MATCH_PATH = "res://scenes/MatchPreparation.tscn"

const BROADCAST_IP = "255.255.255.255"
const SERVER_PORT = 31451
const MAX_PLAYERS = 16

signal changed_lobby
signal server_down
signal match_found
signal full_lobby
signal refresh_list
signal night_ended
signal end_game

#Lista de informações de outros jogadores e minhas informações
var player_list = {}
var my_info = {"name": "", "class": "", "alive" : true, "votes": 0, "revealed": false, "actions": 3, "healed": false, "guarded": false, "roleblock": false, "guard": 0}
var night_info = ""
var skill_info = ""
var creating_match = false
var searching_match = false
var showing_alive = true
var game_running = false
var is_night = false
var dead_count = 0

#Informações de servidores
var socketUDP = PacketPeerUDP.new()
var server_list = {}
var quant_servers = 0
var current_day = 0
var paused = false
var skills_queue = {"1": {}, "2": {}, "3": {}, "4": {}, "5": {}}

enum {NIGHT, DAY, VOTING, TRIAL}
var current_phase

#Distribuição de classes
var classes = {}
var choice_sets = []
var choice_masks = []
var PRNG = RandomNumberGenerator.new()

######### Servidor #########
func create_host():
	#Criando um host
	var peer = NetworkedMultiplayerENet.new()
	var error = peer.create_server(SERVER_PORT, MAX_PLAYERS)
	if (error != OK):
		print("Failed to host on port " + str(SERVER_PORT))
		return false
	
	get_tree().set_network_peer(peer)
	creating_match = true
	player_list[1] = my_info
	return true

#Função em que o servidor manda uma chave para todos conectados na rede
func find_player():
	socketUDP.set_dest_address(BROADCAST_IP, SERVER_PORT)
	var message = SERVER_KEY + "." + my_info["name"]
	socketUDP.put_packet(message.to_ascii())

######### Cliente #########
func find_match():
	#Permite que o cliente escute mensagens na rede
	socketUDP.listen(SERVER_PORT, "0.0.0.0")
	searching_match = true

# warning-ignore:unused_argument
func _process(delta):
	if searching_match:
		#Se tiver alguma mensagem, ler
		if socketUDP.get_available_packet_count() > 0:
			var array_bytes = socketUDP.get_packet()
			var message = array_bytes.get_string_from_ascii()
			var key = message.split(".")[0]
			#Se a mensagem for a chve do servidor, coloca na lista de servidores
			if key == SERVER_KEY and not server_registered():
				quant_servers += 1
				server_list[quant_servers] = {"ip": socketUDP.get_packet_ip(), "name": message.split(".")[1]}
				emit_signal("match_found")

#Checando se o servidor já está na lista
func server_registered():
	for i in server_list:
		if server_list[i]["ip"] == socketUDP.get_packet_ip():
			return true
	
	return false

#Para de escutar mensagens
func stop_searching():
	searching_match = false
	socketUDP.close()
	clear_servers()

func join_match(server_ip):
	#Criando um cliente
	var peer = NetworkedMultiplayerENet.new()
	#Tenta entrar no servidor
	var error = peer.create_client(server_ip, SERVER_PORT)
	if (error != OK):
		print("Failed to connect to a host on port " + str(SERVER_PORT))
		return false
	
	get_tree().set_network_peer(peer)
	#Limpa a lista de servidores e para de procurar
	stop_searching()
	return true

######### Distribuição de Classes #########
func start_game():
	class_distribution()
	rpc("update_list", player_list)
	rpc("enter_game")
	game_running = true
	# warning-ignore:return_value_discarded
	get_tree().change_scene(MATCH_PATH)

#Atualiza lista de jogadores com as classes que lhes forem atribuídas
func class_distribution():
	var class_list = get_classes_for_current_match()
	var class_list_index = 0
	for i in player_list:
		player_list[i]["class"] = class_list[class_list_index]
		class_list_index = class_list_index + 1

func get_classes_for_current_match():
	var choice_mask_index = 0
	var class_list = []
	
	if player_list.size() <= 5:
		choice_mask_index = 0
	if player_list.size() > 5:
		choice_mask_index = player_list.size() - 5
	
	var choice_mask = choice_masks[choice_mask_index]
	
	var choice_set_index = 0
	for character in choice_mask:
		var int_value = character.to_int()
		var choice_set = choice_sets[choice_set_index]
		
		var random_number
		# warning-ignore:unused_variable
		for choice in range(int_value):
			random_number = PRNG.randi_range(0, len(choice_set)-1)
			var chosen_class = choice_set[random_number]
			class_list.append(chosen_class)
			PRNG.randomize()
		
		#Update choice set index for next iteration
		choice_set_index = choice_set_index + 1 
	
	randomize()
	class_list.shuffle()
	return class_list

remote func enter_game():
	game_running = true
	# warning-ignore:return_value_discarded
	get_tree().change_scene(MATCH_PATH)

######### Votação #########
func add_vote(player_id):
	#Adiciona o voto e atualiza a lista para os outros jogadores
	player_list[player_id]["votes"] += 1
	rpc("update_list", player_list)
	emit_signal("refresh_list")
	
	#Testa se o número de votos é metade dos jogadores
	if ceil(get_alive_players()/2) == player_list[player_id]["votes"]:
		return true
	else:
		return false

func delete_vote(player_id):
	#Deleta o voto e atualiza a lista par os outros jogadores
	player_list[player_id]["votes"] -= 1
	rpc("update_list", player_list)
	emit_signal("refresh_list")

func reset_votes():
	for i in player_list:
		player_list[i]["votes"] = 0

func get_votes():
	return player_list[get_tree().get_network_unique_id()]["votes"]

######### Julgamento #########
var guilty_count = 0
var innocent_count = 0
var trial_id = 0

signal trial_ended

#Guarda o id do jogador em julgamento
func set_trial_id(value):
	trial_id = value

func get_trial_id():
	return trial_id

#Reseta a contagem de votos
func reset_trial():
	guilty_count = 0
	innocent_count = 0

#Altera a quantidade de votos de culpado
func trial_guilty(value):
	#Se for o servidor, altera o valor
	if get_tree().get_network_unique_id() == 1:
		guilty_confirm(value)
	#Se for cliente, manda pro servidor
	else:
		rpc_id(1, "guilty_confirm", value)

remote func guilty_confirm(value):
	guilty_count += value

#Altera a quantidade de votos de inocente
func trial_innocent(value):
	#Se for o servidor, altera o valor
	if get_tree().get_network_unique_id() == 1:
		innocent_confirm(value)
	#Se for cliente, manda pro servidor
	else:
		rpc_id(1, "innocent_confirm", value)

remote func innocent_confirm(value):
	innocent_count += value

#Atualiza todos do resultado do julgamento
func get_sentence():
	#Só permite acesso dessa função para o servidor
	if get_tree().get_network_unique_id() != 1:
		return
	
	var sentence = calculate_sentence()
	#Caso o jogador tenha sido eliminado, atualiza todos os outros
	if sentence == (-1):
		player_list[trial_id]["alive"] = false
		rpc("update_list", player_list)
	
	#Confirma que o julgamento acabou
	rpc("confirm_trial", sentence)
	confirm_trial(sentence)

remote func confirm_trial(sentence):
	emit_signal("trial_ended", sentence)

#Calcula o resultado do julgamento
# (-1) = Culpado; 1 = Inocente; 0 = Empate
func calculate_sentence():
	if guilty_count > innocent_count:
		return (-1)
	elif innocent_count > guilty_count:
		return 1
	else:
		return 0

######### Processamento de Habilidades #########
#Limpa a fila de skills
func clear_skill_queue():
	skills_queue = {"1": {}, "2": {}, "3": {}, "4": {}, "5": {}}

#Manda o servidor adicionar a skill na lista
func request_skill_queue(priority, player_id, info):
	
	#Não manda se não for de noite
	if not is_night:
		return
	
	#Cliente manda pro servidor, servidor executa
	if get_tree().get_network_unique_id() == 1:
		add_skill_queue(priority, player_id, info)
	else:
		rpc_id(1, "add_skill_queue", priority, player_id, info)

#Adiciona o uso da skill
remote func add_skill_queue(priority, player_id, info):
	skills_queue[priority][player_id] = info

#Resolve as skills
func solve_skills():
	#Muda para não aceitar mais pedidos de skills
	is_night = false
	
	#Apenas o servidor é permitido executar essa função
	if not get_tree().get_network_unique_id() == 1:
		return
	
	#Começa pelas de maior prioridade
	for i in range(5, 0, -1):
		for j in skills_queue[str(i)].keys():
			#Processando a skill
			var target_id = skills_queue[str(i)][j]["target_id"]
			var target_info = skills_queue[str(i)][j]["target_info"]
			var player_info = skills_queue[str(i)][j]["player_info"]
			AbilitiesManager.confirm_ability(target_id, target_info, j, player_info)
	
	#Salva oq aconteceu para as pessoas
	if dead_count == 0:
		set_night_info("Nenhum jogador foi eliminado durante essa noite.")
	
	rpc("update_list", player_list)
	
	#Manda todo mundo pra próxima tela
	rpc("night_ended", dead_count)
	night_ended(dead_count)

#Atualiza a contagem de mortos e muda a tela
remote func night_ended(value):
	dead_count = value
	emit_signal("night_ended")

#Chama a função para atualizar a informação do jogador correto
func set_night_info(value):
	for i in player_list:
		if i == 1:
			confirm_night_info(value)
		else:
			rpc_id(i, "confirm_night_info", value)

#Grava os acontecimentos da noite
remote func confirm_night_info(value):
	night_info += value + "\n"

#Getter para os acontecimentos da noite
func get_night_info():
	return night_info

#Reseta o texto
func reset_night_info():
	night_info = ""

#Chama a função para atualizar a informação do jogador correto
func set_skill_info(player_id, value):
	if player_id == 1:
		confirm_skill_info(value)
	else:
		rpc_id(player_id, "confirm_skill_info", value)

#Setter para o resultado da skill
remote func confirm_skill_info(value):
	skill_info += value + "\n"

#Getter para os acontecimentos da skill durante a noite
func get_skill_info():
	return skill_info

#Reseta o texto
func reset_skill_info():
	skill_info = ""

#Altera o número de ações disponíveis
func set_actions(player_id, value):
	player_list[player_id]["actions"] = value

#Getter e setter para se um jogador foi revelado
func get_revealed(player_id):
	return player_list[player_id]["revealed"]

func set_revealed(player_id, value):
	player_list[player_id]["revealed"] = value

#Getter e setter para guarda
func get_guarded(player_id):
	return player_list[player_id]["guarded"]

func get_guard(player_id):
	return player_list[player_id]["guard"]

func set_guarded(player_id, value, guard_id):
	player_list[player_id]["guarded"] = value
	player_list[player_id]["guard"] = guard_id

#Limpar a guarda de todos os jogadores
func clear_guard():
	for i in player_list:
		set_guarded(i, false, 0)

#Getter e setter para se foi curado durante a noite
func get_healed(player_id):
	return player_list[player_id]["healed"]

func set_healed(player_id, value):
	player_list[player_id]["healed"] = value

#Limpar a cura de todos
func clear_heal():
	for i in player_list:
		player_list[i]["healed"] = false

#Getter e setter para roleblock
func get_roleblocked(player_id):
	return player_list[player_id]["roleblock"]

func set_roleblocked(player_id, value):
	player_list[player_id]["roleblock"] = value

#Limpar a cura de todos
func clear_roleblock():
	for i in player_list:
		player_list[i]["roleblock"] = false

######### Fim da Partida #########
#Checa se alguem venceu a partida
func check_winner():
	#Apenas o servidor usa essa função
	if not get_tree().get_network_unique_id() == 1:
		return
	
	var town_alive = 0
	var evil_alive = 0
	
	for i in player_list:
		var player_class = player_list[i]["class"]
		if classes[player_class]["alignment"] == "Cidade" and player_list[i]["alive"]:
			town_alive += 1
		elif classes[player_class]["alignment"] == "Lobisomens" and player_list[i]["alive"]:
			evil_alive += 1
	
	if town_alive == 0 and evil_alive > 0:
		rpc("evil_win")
		evil_win()
	elif town_alive > 0 and evil_alive == 0:
		rpc("town_win")
		town_win()
	elif town_alive == 0 and evil_alive == 0:
		rpc("end_draw")
		end_draw()

remote func evil_win():
	emit_signal("end_game", "Lobisomens")

remote func town_win():
	emit_signal("end_game", "Cidade")

remote func end_draw():
	emit_signal("end_game", "Empate")

######### Controle da Partida #########
func _ready():
	#Conectando todas as chamadas de internet
	# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_connected",self,"_player_connected")
	# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_disconnected",self,"_player_disconnected")
	# warning-ignore:return_value_discarded
	get_tree().connect("server_disconnected",self,"_server_disconnected")
	# warning-ignore:return_value_discarded
	get_tree().connect("connected_to_server",self,"_connected_ok")
	# warning-ignore:return_value_discarded
	get_tree().connect("connection_failed",self,"_connected_fail")
	
	populate_class_maps()

#Quando um jogador conectar, manda minhas informações para ele (servidor e cliente)
func _player_connected(id):
	#Manda minhas informações apenas para o jogador que conectou
	rpc_id(id, "register_player", my_info)

#Deleta o jogador que desconectar
func _player_disconnected(id):
	#Se não estiver na partida
	if not game_running:
		player_list.erase(id)
		emit_signal("changed_lobby")

#Servidor desconectou (Executado no Cliente)
func _server_disconnected():
	print("servidor desconectou")

#Conectado com sucesso (cliente)
func _connected_ok():
	#salva minhas informações na minha posição
	player_list[get_tree().get_network_unique_id()] = my_info
	#Manda minhas informações para todos os outros jogadores
	rpc("register_player", my_info)

#Não consegui conectar no servidor (cliente)
func _connected_fail():
	# warning-ignore:return_value_discarded
	get_tree().change_scene(MAIN_PATH)
	emit_signal("server_down")

#Função pode ser chamada por método rpc para registrar jogadores
remote func register_player(info):
	#Pega o id de quem enviou a chamada e guarda sua informação
	var id = get_tree().get_rpc_sender_id()
	player_list[id] = info
	emit_signal("changed_lobby")
	
	#Se a partida estiver cheia, avisa o servidor para começar
	if player_list.size() == 16:
		emit_signal("full_lobby")

#Função para se desconectar da partida
func disconnect_player():
	#Se for o servidor, avisa todos q a partida acabou/caiu
	if get_tree().get_network_unique_id() == 1 and game_running:
		rpc("server_off")
	
	#Se estiver em uma partida rodando, elimina o jogador
	if game_running:
		set_player_dead(get_tree().get_network_unique_id())
	
	#Espera ele atualizar o servidor e o deleta
	OS.delay_msec(200)
	reset_variables()
	get_tree().set_network_peer(null)
	if creating_match:
		socketUDP.close()
		creating_match = false
		# warning-ignore:return_value_discarded
		get_tree().change_scene(MAIN_PATH)
	else:
		# warning-ignore:return_value_discarded
		get_tree().change_scene(SERVER_PATH)

#Atualiza a lista de jogadores do servidor com o que mandou a chamada eliminando
#remote func player_eliminated(id):
#	player_list[id]["alive"] = false
#
#	#Passa a lista de jogadores atualizada para todos os clientes
#	rpc("update_list", player_list)
#	emit_signal("refresh_list")

remote func server_off():
	#Reseta as informções do jogador
	reset_variables()
	get_tree().set_network_peer(null)
	# warning-ignore:return_value_discarded
	get_tree().change_scene(MAIN_PATH)
	OS.delay_msec(200)
	emit_signal("server_down")

#Getter e setter para a fase atual
func get_current_phase():
	return current_phase

func set_current_phase(value):
	current_phase = value

######### Funções Auxiliares #########
#Getter para a lista de servidores
func get_servers():
	return server_list

#Limpar quantidade e lista de servers
func clear_servers():
	server_list = {}
	quant_servers = 0

#Setter para o nome
func set_name(p_name):
	my_info["name"] = p_name

#Geter para a lista de jogadores
func get_players():
	return player_list

#Getter para a quantidade de jogadores no servidor
func get_players_quant():
	return player_list.size()

#Getter parra as minhas informações
func get_my_info():
	return get_player_info(get_tree().get_network_unique_id())

func get_my_id():
	return get_tree().get_network_unique_id()

#Getter para as informações de um jogador
func get_player_info(id):
	return player_list[id]

#Getter para o nome do jogador
func get_player_name(player_id):
	return player_list[player_id]["name"]

#Getter para se está criando partida
func get_creating():
	return creating_match

#Getters para as variaveis relacionadas com a distribuição de classes
func get_classes():
	return classes

func get_choice_masks():
	return choice_masks
	
func get_choice_sets():
	return choice_sets

#Getter e setter para se está mostrando jogadores vivos ou eliminados
func set_showing_alive(value):
	showing_alive = value
	emit_signal("refresh_list")

func get_showing_alive():
	return showing_alive

#Atualiza para o jogador atual ser eliminado
remote func set_player_dead(player_id):
	dead_count += 1
	
	#Se for o servidor, atualiza o resto dos jogadores
	if get_tree().get_network_unique_id() == 1:
		player_list[player_id]["alive"] = false
		if player_list[player_id]["class"] == "werewolf":
			transform_new_werewolf()
		
		rpc("update_list", player_list)
	#Se for um jogador, avisa o servidor
	else:
		rpc_id(1, "set_player_dead", player_id)

#Avança para o próximo dia e getter para o dia atual
func next_day():
	current_day += 1

func get_current_day():
	return current_day

#Getter e setter para se o jogador pausou
func get_paused():
	return paused

func set_paused(value):
	paused = value

#Limpa todas as variaveis
func reset_variables():
	player_list = {}
	my_info["class"] = ""
	my_info["alive"] = true
	my_info["votes"] = 0
	searching_match = false
	showing_alive = true
	game_running = false
	current_day = 0
	paused = false
	clear_servers()

#Função para atualizar as classes dos clientes
remote func update_list(new_info):
	for i in player_list:
		for j in new_info:
			if i == j:
				player_list[i] = new_info[j]
	
	emit_signal("refresh_list")

#Getter para quantidade de pessoas vivas
func get_alive_players():
	var quant = 0
	for i in player_list:
		if player_list[i]["alive"]:
			quant += 1
	
	return float(quant)

#Setter para se está de noite
func set_night(value):
	is_night = value

#Getter e Setter para o número de mortos em uma noite
func get_dead_count():
	return dead_count

func set_dead_count(value):
	dead_count = value

#Setter para o estado do jogo
func set_game_running(value):
	game_running = value

#Transforma alguem do mal em lobisomem
func transform_new_werewolf():
	var player_class
	var player_alingment
	var evil_players = {}
	var cultist_players = {}
	
	#Separa todos os cultistas em uma lista e o resto dos do mal em outra
	for i in player_list:
		player_class = player_list[i]["class"]
		player_alingment = LobbyManager.get_class_alignment(player_class)
		
		if player_list[i]["alive"] and player_alingment == "Lobisomens":
			if player_list[i]["class"] == "cultist":
				cultist_players[i] = player_list[i]
			else:
				evil_players[i] = player_list[i]
	
	#Pega um dos cultistas e transforma em lobisomem
	for i in cultist_players:
		player_list[i]["class"] = "werewolf"
		return
	
	#Se não tiver cultista, pega um dos outros do mal e transforma
	# warning-ignore:unreachable_code
	for i in evil_players:
		player_list[i]["class"] = "werewolf"
		return

#Reseta as informações do jogador
func clear_info():
	#Lista de informações de outros jogadores e minhas informações
	my_info["alive"] = true
	my_info["votes"] = 0
	my_info["revealed"] = false
	my_info["actions"] = 3
	my_info["healed"] = false
	my_info["guarded"] = false
	my_info["roleblock"] = false
	my_info["guard"] = 0
	night_info = ""
	skill_info = ""

######### Criar todas as classes do jogo e suas distribuições #########
func populate_class_maps():
	# Classes da Cidade
	classes["leader"] = {"alignment": "Cidade", "name": "Líder", "skill": "Durante a noite pode se selecionar para revelar que é o Líder da Cidade."}
	classes["detective"] = {"alignment": "Cidade", "name": "Detetive", "skill": "Selecione alguém para ver seu alinhamento!"}
	classes["observer"] = {"alignment": "Cidade", "name": "Aldeão", "skill": "Ajude a Cidade a eliminar todos os lobisomens!"}
	classes["messenger"] = {"alignment": "Cidade", "name": "Mensageiro", "skill": ""}
	classes["hunter"] = {"alignment": "Cidade", "name": "Caçador", "skill": "Escolha algúem para eliminar. Mas cuidado, você só possui três balas e não pode eliminar na primeira noite!"}
	classes["captain"] = {"alignment": "Cidade", "name": "Capitão", "skill": "Você pode impedir alguém de utilizar a habilidade durante a noite."}
	classes["alchemist"] = {"alignment": "Cidade", "name": "Alquimista", "skill": "Escolha alguém e impeça que ele seja eliminado."}
	classes["guard"] = {"alignment": "Cidade", "name": "Guarda", "skill": "Escolha um jogador para proteger. Se ele for atacado, você será eliminado em seu lugar mas eliminará quem atacou!"}
	
	# Classes dos Lobisomens
	classes["werewolf"] = {"alignment": "Lobisomens", "name": "Lobisomem", "skill": "Escolha alguém da Cidade e o elimine!"}
	classes["sorcerer"] = {"alignment": "Lobisomens", "name": "Feiticeiro", "skill": ""}
	classes["elder"] = {"alignment": "Lobisomens", "name": "Ancião", "skill": ""}
	classes["mimic"] = {"alignment": "Lobisomens", "name": "Mímico", "skill": ""}
	classes["cultist"] = {"alignment": "Lobisomens", "name": "Cultista", "skill": "Ajude os lobisomens a eliminar a Cidade inteira!"}
	
	# Classes Neutras
	classes["fugitive"] = {"alignment": "Neutro", "name": "Fugitivo", "skill": ""}
	classes["outsider"] = {"alignment": "Neutro", "name": "Forasteiro", "skill": ""}
	classes["avenger"] = {"alignment": "Neutro", "name": "Vingador", "skill": ""}
	classes["stalker"] = {"alignment": "Neutro", "name": "Suicida", "skill": ""}
	classes["suicidal"] = {"alignment": "Neutro", "name": "Stalker", "skill": ""}
	
	#Apenas esses possuem habilidades
	choice_sets.append(["leader", "detective", "alchemist", "captain"])
	choice_sets.append(["hunter", "guard"])
	#Utilizando pra nenhuma habilidade
	choice_sets.append(["observer"])
	#Apenas um do mal com habilidade
	choice_sets.append(["werewolf"])
	choice_sets.append(["cultist"])
	
	var choices_for_5_players  = "21011"#"00110"
	var choices_for_6_players  = "21111"
	var choices_for_7_players  = "21112"
	var choices_for_8_players  = "31112"
	var choices_for_9_players  = "31113"
	var choices_for_10_players = "32113"
	var choices_for_11_players = "32114"
	var choices_for_12_players = "32214"
	var choices_for_13_players = "32215"
	var choices_for_14_players = "42215"
	var choices_for_15_players = "42216"
	var choices_for_16_players = "43216"
	
	choice_masks.append(choices_for_5_players) #0 + 5 = 5
	choice_masks.append(choices_for_6_players) #1
	choice_masks.append(choices_for_7_players) #2
	choice_masks.append(choices_for_8_players) #3
	choice_masks.append(choices_for_9_players) #4
	choice_masks.append(choices_for_10_players) #5
	choice_masks.append(choices_for_11_players) #6
	choice_masks.append(choices_for_12_players) #7
	choice_masks.append(choices_for_13_players) #8
	choice_masks.append(choices_for_14_players) #9
	choice_masks.append(choices_for_15_players) #10
	choice_masks.append(choices_for_16_players) #11 + 5 = 16
	PRNG.randomize()

func get_class_alignment(player_class):
	return classes[player_class]["alignment"]