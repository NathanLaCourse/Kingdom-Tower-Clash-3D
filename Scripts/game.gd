extends Node3D

@export var worldScene: PackedScene
@export var background: Node3D
@export var ui: Node2D
@export var main_menu: PanelContainer
@export var mainVBox: VBoxContainer
@export var address_entry: LineEdit
@export var lobbyVBox: VBoxContainer
@export var addressSwitch: CheckButton
@export var addressShow: LineEdit

var gameStarted: bool
var runtime: float
var onlineMode: bool
var address: String
const Player = preload("res://Scenes/online_player.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

var team: int

func _ready() -> void:
	ui.position = get_window().size / 2

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
	runtime += delta
	
	if not gameStarted:
		background.get_child(1).rotation.y += delta * 0.5
		background.get_child(1).rotation.x = (sin(runtime * PI/5) * 0.4) + deg_to_rad(-15)
		return

func _on_start_pressed() -> void:
	onlineMode = false
	team = 0
	startGame()

func _on_host_button_pressed() -> void:
	onlineMode = true
	mainVBox.visible = false
	lobbyVBox.visible = true
	team = 0
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	add_player(multiplayer.get_unique_id())
	
	upnp_setup()
	

func _on_join_button_pressed() -> void:
	onlineMode = true
	mainVBox.visible = false
	lobbyVBox.visible = true
	team = 1
	
	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer

func _on_multiplayer_button_pressed() -> void:
	startLobby.rpc()

func _on_show_address_switch_toggled(toggled_on: bool) -> void:
	if toggled_on:
		addressShow.text = address
	else:
		addressShow.text = ""

func add_player(peer_id):
	var newPlayer = Player.instantiate()
	newPlayer.name = str(peer_id)
	add_child(newPlayer)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func startGame():
	gameStarted = true
	background.queue_free()
	ui.visible = false
	var newWorld = worldScene.instantiate()
	newWorld.myTeam = team
	add_child(newWorld)

@rpc("authority", "call_local", "reliable")
func startLobby():
	startGame()

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")
	
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	address = upnp.query_external_address()
	print("Success! Join Address: %s" % address)
