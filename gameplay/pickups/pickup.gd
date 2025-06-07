extends Area3D
class_name Pickup

@export var id: String

var water_particles = preload("res://effects/water_pickup_particles.tscn")
var sting_particles = preload("res://effects/sting_pickup_particles.tscn")

func on_pickup():
	spawn_particles()
	hide()
	await get_tree().create_timer(0.1).timeout
	queue_free()

func spawn_particles():
	var particles_scene
	
	match id:
		"water":
			particles_scene = water_particles
		"energy":
			particles_scene = sting_particles
	
	if particles_scene:
		print("Spawning particles for: ", id)
		var particles = particles_scene.instantiate()
		
		# Find the player - try multiple methods
		var player = find_player()
		
		if player:
			# Add particles to the world (player's parent) so they don't move with player
			var world = player.get_parent()
			world.add_child(particles)
			particles.global_position = player.global_position + Vector3(0, 1, 0)  # Slightly above player
			print("Particles spawned at player position: ", particles.global_position)
			
			# Force the particles to start emitting
			particles.emitting = true
			particles.restart()
		else:
			# Fallback to pickup position
			print("Player not found, spawning at pickup position")
			get_parent().add_child(particles)
			particles.global_position = global_position + Vector3(0, 1, 0)
			print("Particles spawned at pickup position: ", particles.global_position)
			
			# Force the particles to start emitting
			particles.emitting = true
			particles.restart()
	else:
		print("No particle scene found for: ", id)

func find_player():
	# Method 1: Try to find by group (add player to group first)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	
	# Method 2: Try direct path from main scene
	var main_scene = get_tree().current_scene
	var player = main_scene.get_node_or_null("World/Player")
	if player:
		return player
	
	# Method 3: Search for CharacterBody3D with player script
	return find_player_recursive(get_tree().current_scene)

func find_player_recursive(node: Node) -> Node:
	# Check if this node has the player script
	if node.get_script() and node.get_script().get_path().ends_with("player.gd"):
		return node
	
	# Check children
	for child in node.get_children():
		var result = find_player_recursive(child)
		if result:
			return result
	
	return null
