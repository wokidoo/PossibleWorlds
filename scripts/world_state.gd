@tool
extends Resource
class_name WorldState

# Bump when you change structure; use to run migrations on load if needed.
@export var schema_version: int = 1

# Canonical world metadata
@export var world_name: String = "Actual"

# Canonical content
@export var propositions: Array[Proposition] = []      # canonical Proposition instances
@export var themes: Array[StringName] = []             # canonical themes
@export var characters: Array[Character] = []          # characters in the world

# Free-form payload for future state (indices, scores, tags, etc.)
@export var extras: Dictionary = {}
