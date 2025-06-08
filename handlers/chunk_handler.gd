extends Node3D

# --- Exports ---
@export var showable_chunks: int = 5 # How many chunks ahead of the player to display
@export var chunk_size: float = 100 # The size of each chunk along the Z axis
@export var total_level_chunks: int = 35 # Total number of chunks in the level (including start and end)

# The path where your chunk scene files are located
const CHUNK_DIR_PATH = "res://gameplay/chunks/"
const START_CHUNK_PATH = "res://gameplay/chunks/chunkstart.tscn"
const END_CHUNK_PATH = "res://gameplay/chunks/chunkend.tscn"

# Array to hold the different chunk scenes loaded from the directory
# No longer exported, as it's populated automatically
var chunk_scenes: Array[PackedScene] = [] # Explicitly typed array for random middle chunks
var start_chunk_scene: PackedScene
var end_chunk_scene: PackedScene

# --- Onready Variables ---
# Using get_owner_or_null() and get_node_or_null() is safer
@onready var player: Node3D = get_parent().get_node_or_null("Player")

# --- State Variables ---
# @onready is appropriate here to get the initial value when the node enters the tree
@onready var known_current_chunk: int = get_current_chunk() # Initialize based on initial player position

# --- Core Functions ---

# Function to create a chunk at a specific index
func create_chunk(index: int):
	var scene_to_use: PackedScene
	
	# Determine which scene to use based on the chunk index
	if index == 0:
		# First chunk - use start chunk
		if start_chunk_scene == null:
			print("WARNING: Cannot create start chunk. chunkstart.tscn not found at ", START_CHUNK_PATH)
			return
		scene_to_use = start_chunk_scene
	elif index == total_level_chunks - 1:
		# Last chunk - use end chunk
		if end_chunk_scene == null:
			print("WARNING: Cannot create end chunk. chunkend.tscn not found at ", END_CHUNK_PATH)
			return
		scene_to_use = end_chunk_scene
	else:
		# Middle chunks - use random selection
		if chunk_scenes.is_empty():
			print("WARNING: Cannot create chunk ", index, ". No chunk scenes available in 'chunk_scenes' array! Check if any .tscn files are in ", CHUNK_DIR_PATH)
			return
		
		# Select a random scene from the array
		var random_index = randi_range(0, chunk_scenes.size() - 1)
		scene_to_use = chunk_scenes[random_index]
	
	# Instantiate the selected scene
	var new_chunk: Node3D = scene_to_use.instantiate()
	
	# Position the chunk based on its index
	# Assuming progression is along the negative Z axis, hence Vector3.FORWARD * index * chunk_size
	new_chunk.position = Vector3.FORWARD * float(index) * chunk_size # Ensure index is float for multiplication
	
	# Name the chunk by its index. This is crucial for update_chunks to track them.
	new_chunk.name = str(index)
	
	add_child(new_chunk)
	# print("Created chunk ", index, " using appropriate scene") # Optional debug print

# Function to update which chunks should be present
func update_chunks():
	# Determine which chunk indices should currently exist
	var chunks_to_keep = []
	# We want to keep chunks from the current one up to showable_chunks ahead
	for i in range(showable_chunks):
		var chunk_index = known_current_chunk + i
		# Only keep chunks that are within the level bounds
		if chunk_index >= 0 and chunk_index < total_level_chunks:
			chunks_to_keep.append(chunk_index)
		
	# print("Expected chunks to keep: ", chunks_to_keep) # Optional debug print
	
	var existing_chunk_indices = []
	
	# Iterate through existing children to see which ones we have and which to remove
	for child in get_children():
		# Check if the child's name is a valid integer index
		if child.name.is_valid_int():
			var index = int(child.name)
			existing_chunk_indices.append(index) # Keep track of existing indices

			# If an existing chunk's index is NOT in the list of chunks to keep, queue it for deletion
			if index not in chunks_to_keep:
				# print("Queueing chunk ", index, " for free.") # Optional debug print
				child.queue_free()
		# else:
			# print("Skipping non-chunk child:", child.name) # Optional debug print for other nodes like Player

	# Determine which chunks need to be created (those in chunks_to_keep but not existing)
	var chunks_to_create = []
	for index_to_check in chunks_to_keep:
		if index_to_check not in existing_chunk_indices:
			chunks_to_create.append(index_to_check)
			
	# print("Chunks to create: ", chunks_to_create) # Optional debug print

	# Create the missing chunks
	for chunk_index_to_create in chunks_to_create:
		create_chunk(chunk_index_to_create)

# Function to determine the player's current chunk index
func get_current_chunk():
	# Ensure player node is valid before trying to access its position
	if not is_instance_valid(player):
		# print("WARNING: Player node is not valid or not found!") # Already warned in _ready
		return known_current_chunk # Return the last known chunk if player is missing

	# The player is likely moving along the negative Z axis (-player.global_position.z)
	# Divide by chunk_size to get the index. Integer conversion truncates.
	# Example: player at z=0 is in chunk 0. player at z=-99 is in chunk 0. player at z=-100 is in chunk 1.
	# Ensure chunk_size is not zero to prevent division by zero error
	if chunk_size == 0:
		print("WARNING: chunk_size is 0! Cannot calculate current chunk.")
		return known_current_chunk

	var calculated_chunk = int(-player.global_position.z / chunk_size)
	# Clamp the chunk index to stay within level bounds
	return clamp(calculated_chunk, 0, total_level_chunks - 1)

# Function to check if player has reached the end of the level
func has_player_reached_end() -> bool:
	return get_current_chunk() >= total_level_chunks - 1

# --- Helper Function to Load Scenes from Directory ---

# This function scans the specified directory and loads all .tscn files as PackedScenes
# IMPORTANT: Added the return type hint "-> Array[PackedScene]"
func _load_chunk_scenes_from_directory(path: String) -> Array[PackedScene]:
	# Declare loaded_scenes with the correct type as well for clarity and consistency
	var loaded_scenes: Array[PackedScene] = []
	var dir = DirAccess.open(path) # Get a DirAccess object for the path

	if dir:
		dir.list_dir_begin() # Start listing directory contents
		var file_name = dir.get_next() # Get the first entry (file or directory name)

		while file_name != "": # Loop while there are entries
			# Check if the entry is a file (not a directory, hidden file, or special entry like '.' or '..')
			# Note: Godot 4's DirAccess filters out '.' and '..' automatically
			# We also want to skip hidden files (names starting with '.')
			if not dir.current_is_dir() and not file_name.begins_with("."):
				if file_name.ends_with(".tscn"): # Check if the file is a .tscn scene file
					# Skip the start and end chunk files as they're loaded separately
					if file_name == "chunkstart.tscn" or file_name == "chunkend.tscn":
						file_name = dir.get_next()
						continue
					
					var full_path = path.path_join(file_name) # Construct the full resource path (e.g., "res://gameplay/chunks/chunk1.tscn")
					var loaded_resource = load(full_path) # Load the resource

					# Check if the loaded resource is a valid PackedScene
					if loaded_resource and loaded_resource is PackedScene:
						loaded_scenes.append(loaded_resource)
						# print("Found and loaded chunk scene:", full_path) # Optional debug print
					else:
						# Optional: Print a warning if a .tscn file isn't a valid PackedScene
						print("Skipping invalid or non-PackedScene resource found in chunk directory:", full_path)

			file_name = dir.get_next() # Move to the next entry

		dir.list_dir_end() # End directory listing
	else:
		# Print an error if the directory could not be opened
		print("Error: Could not open directory:", path, " to load chunk scenes.")
		print("Please ensure the path '", path, "' is correct and the directory exists in your project.")

	return loaded_scenes # This now returns an Array[PackedScene]

# Function to load the start and end chunk scenes
func _load_special_chunks():
	# Load start chunk
	if ResourceLoader.exists(START_CHUNK_PATH):
		start_chunk_scene = load(START_CHUNK_PATH)
		if start_chunk_scene and start_chunk_scene is PackedScene:
			print("Loaded start chunk scene from: ", START_CHUNK_PATH)
		else:
			print("ERROR: Failed to load start chunk scene from: ", START_CHUNK_PATH)
	else:
		print("ERROR: Start chunk scene not found at: ", START_CHUNK_PATH)
	
	# Load end chunk
	if ResourceLoader.exists(END_CHUNK_PATH):
		end_chunk_scene = load(END_CHUNK_PATH)
		if end_chunk_scene and end_chunk_scene is PackedScene:
			print("Loaded end chunk scene from: ", END_CHUNK_PATH)
		else:
			print("ERROR: Failed to load end chunk scene from: ", END_CHUNK_PATH)
	else:
		print("ERROR: End chunk scene not found at: ", END_CHUNK_PATH)

# --- Godot Engine Callbacks ---

func _ready() -> void:
	# Seed the random number generator
	randomize()

	# Load the special start and end chunks
	_load_special_chunks()

	# Load chunk scenes from the specified directory before creating any chunks
	# The return value now correctly matches the type of chunk_scenes
	chunk_scenes = _load_chunk_scenes_from_directory(CHUNK_DIR_PATH)

	# Check if any middle chunk scenes were loaded
	if chunk_scenes.is_empty():
		print("WARNING: No middle chunk scenes loaded from", CHUNK_DIR_PATH, ". Only start and end chunks will be available.")

	# Validate that we have the essential chunks
	if start_chunk_scene == null:
		print("FATAL ERROR: Start chunk scene (chunkstart.tscn) not found!")
	if end_chunk_scene == null:
		print("FATAL ERROR: End chunk scene (chunkend.tscn) not found!")

	# Ensure the player node was found
	if not is_instance_valid(player):
		print("FATAL ERROR: Player node not found! Make sure a Node3D named 'Player' exists and is accessible from this script's location.")
		# This script won't work without the player node

	# Initialize the chunks based on the player's starting position
	# Only update chunks if player node is valid AND we have at least start/end scenes
	if is_instance_valid(player) and (start_chunk_scene != null or end_chunk_scene != null):
		update_chunks()

func _physics_process(_delta: float) -> void:
	# Only update chunks if player node is valid and we have scenes loaded
	if not is_instance_valid(player):
		return # Do nothing if player is missing

	# Determine the player's current chunk index
	var current_chunk: int = get_current_chunk()

	# Check if the player has moved into a new chunk
	if (current_chunk != known_current_chunk):
		# If they have, update the known current chunk and refresh the visible chunks
		known_current_chunk = current_chunk
		update_chunks()
		
	# Optional: Check if player has reached the end and emit a signal or call a function
	# if has_player_reached_end():
	#     # Handle end of level logic here
	#     pass
