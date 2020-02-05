extends Control

const player_tag = preload("res://resources/instances/PlayerName.tscn")

onready var popup = $PopUp
onready var name_label = $PopUp/NameLAbel
onready var description_label = $PopUp/InfoLabel
onready var node_list = $PopUp/ScrollContainer/VBoxContainer
onready var label_wolfs = $PopUp/LabelWolfs

func _on_OpenBtn_pressed():
	LobbyManager.set_info_showing(true)
	set_popup_visibility(true)

func _on_Close_pressed():
	LobbyManager.set_info_showing(false)
	set_popup_visibility(false)

func set_text():
	var info = LobbyManager.get_my_info()
	var classes = LobbyManager.get_classes()
	
	var c = info["class"]
	var c_name = classes[c]["name"]
	var c_description = classes[c]["skill"]
	var c_alignment = classes[c]["alignment"]
	name_label.set_text(c_name + " (" + c_alignment + ")")
	description_label.set_text(c_description)
	
	
	var player_list = LobbyManager.get_players()
	if c_alignment == "Lobisomens":
		clear_nodes()
		label_wolfs.set_visible(true)
		for i in player_list:
			if LobbyManager.get_class_alignment(player_list[i]["class"]) == "Lobisomens" and i != LobbyManager.get_my_id():
				var node = player_tag.instance()
				node.get_node("Label").set_text(player_list[i]["name"] + "\n" + "  - " + LobbyManager.get_class_name(player_list[i]["class"]))
				node.rect_min_size = Vector2(node_list.get_parent().get_size().x, node.get_size().y)
				node_list.add_child(node)

func set_popup_visibility(value):
	if value:
		set_text()
	
	popup.set_visible(value)

func clear_nodes():
	for i in node_list.get_children():
		node_list.remove_child(i)