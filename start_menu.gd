extends CenterContainer

@export_placeholder("127.0.0.1") var server_ip : String
@export_placeholder("9999") var server_port : String


func _on_host_button_pressed():
	print("Hosting session!")
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(int(server_ip), int(server_port))
	get_tree() = peer


func _on_join_button_pressed():
	print("Joining session!")


func _on_quit_button_pressed():
	get_tree().quit()
	get_tree().network_peer = null
