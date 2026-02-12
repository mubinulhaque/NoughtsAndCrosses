extends CenterContainer

@export_placeholder("127.0.0.1") var server_ip : String
@export_placeholder("9999") var server_port : String

@onready var _client_username_line_edit = $JoinServerOptions/UsernameLineEdit
@onready var _current_menu: Control
@onready var _host_menu_button: Button = $MainMenu/HostSessionButton
@onready var _host_options = $HostServerOptions
@onready var _ip_getter: HTTPRequest = $IPGetter
@onready var _join_options: Control = $JoinServerOptions
@onready var _main_menu: Control = $MainMenu
@onready var _opponent_ip_address_line_edit = $JoinServerOptions/IPAddressLineEdit
@onready var _opponent_port_line_edit = $JoinServerOptions/PortLineEdit
@onready var _server_username_line_edit = $HostServerOptions/UsernameLineEdit


func _ready():
	RenderingServer.set_default_clear_color(Color.BLACK)
	_host_menu_button.grab_focus()
	_current_menu = _main_menu
	_ip_getter.request_completed.connect(_display_ip)


func start_game():
	print("The game has started!")


func _change_menu(new_menu: Control, node_to_focus: Control):
	if _current_menu:
		_current_menu.visible = false
	new_menu.visible = true
	_current_menu = new_menu
	node_to_focus.grab_focus()


func _display_ip(
			result: int,
			_response_code: int,
			_headers: PackedStringArray,
			body: PackedByteArray,
	):
	match result:
		HTTPRequest.RESULT_SUCCESS:
			var ip = body.get_string_from_utf8()
			print("External IP address: ", ip)
		HTTPRequest.RESULT_CANT_CONNECT:
			print("Request to get external IP address failed while connecting")
		HTTPRequest.RESULT_CANT_RESOLVE:
			print("Request to get external IP address failed while resolving")
		HTTPRequest.RESULT_CONNECTION_ERROR:
			print("Request to get external IP address due to a connection error")
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			print("Request to get external IP address failed on TLS handshake")
		HTTPRequest.RESULT_TIMEOUT:
			print("Request to get external IP address timed out")
		_: # If the request failed for an unknown reason
			print("Request to get external IP address failed: ", result)
			# Refer to HTTPRequest.request() to find out the source of the error


func _on_back_button_pressed():
	_change_menu(_main_menu, _host_menu_button)


func _on_host_button_pressed():
	var peer = ENetMultiplayerPeer.new()
	# Create a server for 2 players only
	var server_status = peer.create_server(int(server_port), 2)
	
	match server_status:
		OK: # If the server was created successfully
			print("Server created at the following IP addresses:")
			for ip in IP.get_local_addresses():
				if (ip.begins_with("192.168") or ip.begins_with("172")
						or ip.begins_with("10.")):
					print("LAN IP address: ", ip)
			
			var request_error = _ip_getter.request("https://api.ipify.org")
			match request_error:
				ERR_UNCONFIGURED:
					print("Error while requesting external IP address: ")
					print("IPGetter node is not in the tree. ")
				ERR_BUSY:
					print("Error while requesting external IP address: ")
					print("Still processing previous request. ")
				ERR_INVALID_PARAMETER:
					print("Error while requesting external IP address: ")
					print("URL is in an invalid format. ")
				ERR_CANT_CONNECT:
					print("Error while requesting external IP address: ")
					print("Thread is not being used and cannot connect to client.")
				# If requesting the address encountered an unknown problem
				_:
					if request_error != OK:
						print("Unknown error while requesting external IP address;",
								request_error)
					# Refer to HTTPRequest.request() to find out
					# the source of the error
		ERR_ALREADY_IN_USE:
			print("This instance already has an open connection!")
			return
		ERR_CANT_CREATE:
			print("The server could not be created!")
			return
		# If the server encountered an unknown problem while being created
		_:
			print("Unknown error while starting the server: ", server_status)
			# Refer to ENetMultiplayerPeer.create_server() to find out
			# the source of the error
	
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("The server was created but could not be connected to!")
		return
	
	# Let the MultiplayerAPI know that it is a server
	multiplayer.multiplayer_peer = peer
	start_game()


func _on_host_session_button_pressed():
	_change_menu(_host_options, _server_username_line_edit)


func _on_join_button_pressed():
	var opponent_ip: String = "127.0.0.1"
	var opponent_port: String = "9999"
	
	if (
			not _opponent_ip_address_line_edit.text.is_empty()
			and _opponent_ip_address_line_edit.text.is_valid_ip_address()
	):
		opponent_ip = _opponent_ip_address_line_edit.text
	
	if (
			not _opponent_port_line_edit.text.is_empty()
			and _opponent_port_line_edit.text.is_valid_int()
	):
		opponent_port = _opponent_port_line_edit.text


func _on_join_session_button_pressed():
	_change_menu(_join_options, _client_username_line_edit)


func _on_quit_button_pressed():
	get_tree().quit()
	multiplayer.multiplayer_peer = null
