extends Node

const PORT = 7000
const MAX_CLIENTS = 2
const EXPECTED_PLAYERS = 2

var connected_players: Dictionary = {} # peer_id -> data
signal lobby_filled
signal connected 

func _ready() -> void:
	# Connect ALL network signals in _ready()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)

func host_game(expected_players: int) -> void:
	_reset_network_state()
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CLIENTS)
	if error != OK:
		print("Failed to start server: ", error)
		return
		
	multiplayer.multiplayer_peer = peer
	print("Server listening on port ", PORT)
	
	# Register host itself (peer_id = 1)
	connected_players[1] = {"ready": false}
	print("waiting on players")
	if connected_players.size() < expected_players:
		await lobby_filled
	print("Lobby filled! Starting match setup...")
	connected.emit()

func join_game(ip_address: String) -> void:
	_reset_network_state()
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip_address, PORT)
	if error != OK:
		print("Failed to initiate connection: ", error)
		return
		
	multiplayer.multiplayer_peer = peer
	await connected
	print("Connecting to ", ip_address, "...")

func _on_peer_connected(id: int) -> void:
	print("Peer connected signal fired for ID: ", id , " moo: ", multiplayer.get_unique_id())
	
	if multiplayer.is_server():
		connected_players[id] = {"ready": true}
		if connected_players.size() == EXPECTED_PLAYERS:
			
			lobby_filled.emit()

func _on_connected_to_server() -> void:
	print("Successfully connected to host!")
	connected.emit()
	

func _on_connection_failed() -> void:
	print("Failed to connect to host.")
	_reset_network_state()

func _on_peer_disconnected(id: int) -> void:
	print("Player disconnected: ", id)
	connected_players.erase(id)

func _on_server_disconnected() -> void:
	print("Disconnected from server.")
	_reset_network_state()

func _reset_network_state() -> void:
	connected_players.clear()
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		
signal barrier_released(barrier_id: String)

# Server-only dictionary: barrier_id -> Array[int] (peer IDs that reached the barrier)
var _barrier_acks: Dictionary = {}

## Call this from any host or client script to halt execution until ALL peers reach it.
func reach_barrier(barrier_id: String) -> void:
	var my_id = multiplayer.get_unique_id()
	if multiplayer.is_server():
		_register_barrier_ack(barrier_id, my_id)
	else:
		var err = rpc_id(1, "_server_receive_ack", barrier_id)
		print(err)
	
	# Non-blocking pause: yields until the matching barrier_id signal fires
	while true:
		var released_id = await barrier_released
		if released_id == barrier_id:
			break

@rpc("any_peer", "call_remote", "reliable")
func _server_receive_ack(barrier_id: String) -> void:
	if not multiplayer.is_server(): return
	var sender_id = multiplayer.get_remote_sender_id()
	_register_barrier_ack(barrier_id, sender_id)

func _register_barrier_ack(barrier_id: String, peer_id: int) -> void:
	if not _barrier_acks.has(barrier_id):
		_barrier_acks[barrier_id] = []
		
	if not _barrier_acks[barrier_id].has(peer_id):
		_barrier_acks[barrier_id].append(peer_id)
	# Check if all connected peers have arrived at this barrier
	if _barrier_acks[barrier_id].size() >= connected_players.size():
		_barrier_acks.erase(barrier_id) # Clean up state
		rpc("_broadcast_release_barrier", barrier_id)

@rpc("authority", "call_local", "reliable")
func _broadcast_release_barrier(barrier_id: String) -> void:
	barrier_released.emit(barrier_id)
	
static var _next_request_id: int = 0
static func get_next_request_id() -> int:
	var ret_id = _next_request_id
	_next_request_id += 1
	return ret_id
	
