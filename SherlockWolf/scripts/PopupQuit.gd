extends Control

onready var parent = self.get_parent()

func _on_OkBtn_pressed():
	parent.OkBtn_pressed()

func _on_CancelBtn_pressed():
	LobbyManager.set_paused(false)
	self.set_visible(false)
