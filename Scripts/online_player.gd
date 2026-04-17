extends Node

var peer_id

func _ready() -> void:
	peer_id = int(name)

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _process(delta: float) -> void:
	if not is_multiplayer_authority(): return

@rpc("any_peer", "call_local", "reliable")
func playerDataToServer(data):
	pass
