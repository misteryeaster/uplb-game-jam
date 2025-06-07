
extends Node3D

@export var showable_chunks: int = 5

@export var chunk_size: float = 100

var base_chunk = preload("res://gameplay/chunks/chunk.tscn")

@onready var player = get_parent().get_node("Player")

@onready var known_current_chunk: int = 0

func create_chunk(index: int):
	var new_chunk: Node3D = base_chunk.instantiate()
	
	new_chunk.position = Vector3.FORWARD * index * chunk_size
	
	new_chunk.name = str(index)
	
	add_child(new_chunk)
	
func update_chunks():
	var chunks_to_generate = []
	
	for i in range(showable_chunks):
		chunks_to_generate.append(known_current_chunk + i)
	
	for child in get_children():
		var index = int(child.name)
		
		if (index in chunks_to_generate):
			chunks_to_generate.erase(index)
			
			continue
			
		child.queue_free()
		
	for chunk in chunks_to_generate:
		create_chunk(chunk)
	
func get_current_chunk():
	return int(-player.global_position.z / chunk_size)
	
func _ready() -> void:
	update_chunks()
		
func _physics_process(delta: float) -> void:
	var current_chunk: int = get_current_chunk()
	
	if (current_chunk != known_current_chunk):
		known_current_chunk = current_chunk
		update_chunks()
		
	known_current_chunk = current_chunk
	
