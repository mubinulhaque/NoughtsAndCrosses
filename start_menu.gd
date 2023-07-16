extends CenterContainer

@export_placeholder("127.0.0.1") var server_ip : String
@export_placeholder("9999") var server_port : String

@onready var ip_getter = $IPGetter


func _ready():
	ip_getter.request_completed.connect(_display_ip)


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
			
			var request_error = ip_getter.request("https://api.ipify.org")
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
					# Refer to
					# https://docs.godotengine.org/en/stable/classes
					# /class_enetmultiplayerpeer.html#class-enetmultiplayerpeer-method-create-server
					# to find out the source of the error
		ERR_ALREADY_IN_USE:
			print("This instance already has an open connection!")
			return
		ERR_CANT_CREATE:
			print("The server could not be created!")
			return
		# If the server encountered an unknown problem while being created
		_:
			print("Unknown error while starting the server: ", server_status)
	
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("The server was created but could not be connected to!")
		return
	
	# Let the MultiplayerAPI know that it is a server
	multiplayer.multiplayer_peer = peer
	start_game()


func _on_join_button_pressed():
	print("Joining session!")
	start_game()


func _on_quit_button_pressed():
	get_tree().quit()
	multiplayer.multiplayer_peer = null


func _display_ip(result: int, response_code: int, headers: PackedStringArray,
		body: PackedByteArray):
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
			# Refer to
			# https://docs.godotengine.org/en/stable/classes
			# /class_httprequest.html#class-httprequest-method-request
			# to find the source of the error


func start_game():
	print("The game has started!")
