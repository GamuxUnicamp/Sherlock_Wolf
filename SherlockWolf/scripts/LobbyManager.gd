extends Node

const SERVER_KEY = "sherlockwolfpartida"
const MAIN_PATH = "res://scenes/Main.tscn"
const SERVER_PATH = "res://scenes/ServerLobby.tscn"
const CLASS_SELECTION_PATH = "res://scenes/ClassSelection.tscn"

const BROADCAST_IP = "255.255.255.255"
const SERVER_PORT = 31451
const MAX_PLAYERS = 16

signal changed_lobby
signal server_down
signal match_found
signal full_lobby

#Lista de informações de outros jogadores e minhas informações
var player_list = {}
var my_info = {"name": "John Doe", "class": ""}
var creating_match = false
var searching_match = false

#Informações de servidores
var socketUDP = PacketPeerUDP.new()
var server_list = {}
var quant_servers = 0

# Distribuição de classes
var classes = {}
var choice_sets = []
var choice_masks = []

var PRNG = RandomNumberGenerator.new()

func populate_class_maps():
	# Classes da Cidade
	classes["leader"] = {"skill": "", "alignment": "town"}
	classes["detective"] = {"skill": "", "alignment": "town"}
	classes["observer"] = {"skill": "", "alignment": "town"}
	classes["messenger"] = {"skill": "", "alignment": "town"}
	classes["hunter"] = {"skill": "", "alignment": "town"}
	classes["captain"] = {"skill": "", "alignment": "town"}
	classes["alchemist"] = {"skill": "", "alignment": "town"}
	classes["guard"] = {"skill": "", "alignment": "town"}
	
	# Classes dos Lobisomens
	classes["werewolf"] = {"skill": "", "alignment": "werewolves"}
	classes["sorcerer"] = {"skill": "", "alignment": "werewolves"}
	classes["elder"] = {"skill": "", "alignment": "werewolves"}
	classes["mimic"] = {"skill": "", "alignment": "werewolves"}
	classes["elder"] = {"skill": "", "alignment": "werewolves"}
	classes["cultist"] = {"skill": "", "alignment": "werewolves"}
	
	# Classes Neutras
	classes["fugitive"] = {"skill": "", "alignment": "neutral"}
	classes["outsider"] = {"skill": "", "alignment": "neutral"}
	classes["avenger"] = {"skill": "", "alignment": "neutral"}
	classes["stalker"] = {"skill": "", "alignment": "neutral"}
	classes["suicidal"] = {"skill": "", "alignment": "neutral"}
	
	choice_sets.append(["leader", "detective", "observer", "messenger"])
	choice_sets.append(["leader", "detective", "hunter"])
	choice_sets.append(["detective", "observer", "messenger"])
	choice_sets.append(["captain", "hunter"])
	choice_sets.append(["alchemist", "guard"])
	choice_sets.append(["leader", "detective", "observer", "messenger", "hunter", "captain", "alchemist", "guard"])
	choice_sets.append(["werewolf"])
	choice_sets.append(["sorcerer", "elder", "mimic"])
	choice_sets.append(["cultist"])
	choice_sets.append(["fugitive", "outsider", "avenger", "stalker", "suicidal"])
		
	var choices_for_5_players  = "1001101100"
	var choices_for_6_players  = "0111101100"
	var choices_for_7_players  = "0111101101"
	var choices_for_8_players  = "0111111101"
	var choices_for_9_players  = "0111111111"
	var choices_for_10_players = "0121111111"
	var choices_for_11_players = "0121121111"
	var choices_for_12_players = "0121121211"
	var choices_for_13_players = "0121221211"
	var choices_for_14_players = "0121221212"
	var choices_for_15_players = "0121221222"
	var choices_for_16_players = "0121231222"
	
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

######### Controle #########
func _ready():
	#Conectando todas as chamadas de internet
	get_tree().connect("network_peer_connected",self,"_player_connected")
	get_tree().connect("network_peer_disconnected",self,"_player_disconnected")
	get_tree().connect("server_disconnected",self,"_server_disconnected")
	get_tree().connect("connected_to_server",self,"_connected_ok")
	get_tree().connect("connection_failed",self,"_connected_fail")
	
	populate_class_maps()

#Quando um jogador conectar, manda minhas informações para ele (servidor e cliente)
func _player_connected(id):
	#Manda minhas informações apenas para o jogador que conectou
	rpc_id(id, "register_player", my_info)

#Deleta o jogador que desconectar
func _player_disconnected(id):
	player_list.erase(id)
	emit_signal("changed_lobby")

#Servidor desconectou
func _server_disconnected():
	player_list = {}
	get_tree().change_scene(MAIN_PATH)
	emit_signal("server_down")

#Conectado com sucesso (cliente)
func _connected_ok():
	#salva minhas informações na minha posição
	player_list[get_tree().get_network_unique_id()] = my_info
	#Manda minhas informações para todos os outros jogadores
	rpc("register_player", my_info)

#Não consegui conectar no servidor (cliente)
func _connected_fail():
	return

#Função pode ser chamada por método rpc para registrar jogadores
remote func register_player(info):
	#Pega o id de quem enviou a chamada e guarda sua informação
	var id = get_tree().get_rpc_sender_id()
	player_list[id] = info
	emit_signal("changed_lobby")
	
	#Se a partida estiver cheia, avisa o servidor para começar
	if player_list.size() == 16:
		emit_signal("full_lobby")
	

func get_classes_for_current_match():
	var choice_mask_index = 0
	
	if player_list.size() <= 5:
		choice_mask_index = 0
	if player_list.size() > 5:
		choice_mask_index = player_list.size() - 5
	
	var class_list = []
	
	var choice_mask = choice_masks[choice_mask_index]
	#print(choice_mask)
	
	var choice_set_index = 0
	for character in choice_mask:
		var int_value = character.to_int()
		var choice_set = choice_sets[choice_set_index]
		
		# Choose (int_value) classes from (choice_set) randomly.
		
		#print(int_value)
		#print(choice_set)
		
		var random_number = 0
		for choice in range(int_value):
			random_number = PRNG.randi_range(0, len(choice_set)-1)
			var chosen_class = choice_set[random_number]
			class_list.append(chosen_class)
			#print(chosen_class)
			
		choice_set_index = choice_set_index + 1 # update choice set index for next iteration
	
	class_list.shuffle()
	
	return class_list

func class_distribution():
	var class_list = get_classes_for_current_match()
	
	var class_list_index = 0
	for i in player_list:
		player_list[i]["class"] = class_list[class_list_index]
		class_list_index = class_list_index + 1

func start_game():
	class_distribution() # atualiza lista de jogadores com as classes que lhes forem atribuídas	
	#print(player_list)
	rpc("change_all_screens")
	get_tree().change_scene(CLASS_SELECTION_PATH) # para trocar a tela do servidor
	
remote func change_all_screens():
	get_tree().change_scene(CLASS_SELECTION_PATH) # para trocar a tela dos outros

#Função para se desconectar da partida
func disconnect_player():
	player_list = {}
	clear_servers()
	get_tree().set_network_peer(null)
	if creating_match:
		socketUDP.close()
		creating_match = false
		get_tree().change_scene(MAIN_PATH)
	else:
		get_tree().change_scene(SERVER_PATH)

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

#Getter para se está criando partida
func get_creating():
	return creating_match

func get_classes():
	return classes

func get_choice_masks():
	return choice_masks
	
func get_choice_sets():
	return choice_sets