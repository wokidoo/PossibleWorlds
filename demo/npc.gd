class_name NPC
extends CharacterBody2D

const SCENE:= preload("uid://dejf2o5ypraa3")
@onready var area_2d: Area2D = %Area2D
@onready var polygon_2d: Polygon2D = %Polygon2D
var info_box: Control

@export var character: Character

signal hovered_over(c:Character)
signal not_hovered_over(c:Character)
signal clicked_on(c:Character)

var target_pos:Vector2
var randomize_timer: Timer
var conversation_partner: NPC = null:
	set(value):
		conversation_partner = value
		if conversation_partner == null:
			polygon_2d.color = Color.LIGHT_SEA_GREEN
		else:
			polygon_2d.color = Color.GOLDENROD

func is_conversing()->bool:
	return conversation_partner != null

static func create_npc()->NPC:
	var npc:NPC = SCENE.instantiate()
	return npc

func _ready() -> void:
	randomize_timer = Timer.new()
	add_child(randomize_timer)
	randomize_timer.timeout.connect(randomize_location)
	randomize_timer.start(randf_range(2,5))
	randomize_location()
	area_2d.area_entered.connect(_on_area_entered)
	area_2d.area_exited.connect(_on_area_exited)
	area_2d.character = character
	

func _physics_process(delta: float) -> void:
	if not is_conversing():
		_move_around(delta)
	
func randomize_location():
	target_pos = Vector2(randf_range(-250,250),randf_range(-250,250))
	randomize_timer.start(randf_range(2,5))
	
func _move_around(delta:float):
	velocity = (target_pos-position)* 10*delta 
	move_and_slide()

func _on_area_entered(area:Area2D):
	var other:NPC = area.get_parent()
	if not other is NPC:
		return
	var c:= Conversation.create_conversation(self,other)
	get_tree().root.add_child(c)
	c.try_start_conversation()
	
func _on_area_exited(area:Area2D):
	var other:NPC = area.get_parent()
	if not other is NPC:
		return

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		set_physics_process(false)
	elif what == NOTIFICATION_UNPAUSED:
		set_physics_process(true)

class Conversation extends Node2D:
	@export var npc_a:NPC
	@export var npc_b:NPC
	
	var perceived_label: Label
	var ideal_label: Label
	var container: VBoxContainer
	var panel: PanelContainer
	var timer:Timer
	
	static func create_conversation(n_a:NPC, n_b:NPC) ->Conversation:
		var conversation := Conversation.new()
		conversation.npc_a = n_a
		conversation.npc_b = n_b
		return conversation
	
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		perceived_label = Label.new()
		ideal_label = Label.new()
		container = VBoxContainer.new()
		panel = PanelContainer.new()
		panel.add_theme_color_override("bg_color",Color.BLACK)
		container.add_child(perceived_label)
		container.add_child(ideal_label)
		panel.add_child(container)
		add_child(panel)
 
	func try_start_conversation():
		if npc_a.is_conversing() or npc_b.is_conversing():
			queue_free()
			return
		npc_a.conversation_partner = npc_b
		npc_b.conversation_partner = npc_a
		var line := Line2D.new()
		add_child(line)
		line.add_point(npc_a.position)
		line.add_point(npc_b.position)
		line.width = 3
		line.default_color = Color.RED
		print_rich("[b]%s[/b] and [b]%s[/b] started a conversation..." % [npc_a.character.name,npc_b.character.name])
		call_thread_safe("_have_conversation")
		return true
	
	func _have_conversation():
		npc_a.character.changed.connect(func():
			perceived_label.text = "Perceived Tension: (%.2f)" % npc_a.character.perceived_tension(npc_b.character)
			ideal_label.text = "Ideal Tension: (%.2f)" % npc_a.character.ideal_tension(npc_b.character)
		)
		npc_b.character.changed.connect(func():
			perceived_label.text = "Perceived Tension: (%.2f)" % npc_a.character.perceived_tension(npc_b.character)
			ideal_label.text = "Ideal Tension: (%.2f)" % npc_a.character.ideal_tension(npc_b.character)
		)
		perceived_label.text = "Perceived Tension: (%.2f)" % npc_a.character.perceived_tension(npc_b.character)
		ideal_label.text = "Ideal Tension: (%.2f)" % npc_a.character.ideal_tension(npc_b.character)
		panel.global_position = npc_a.global_position
		timer = Timer.new()
		timer.timeout.connect(end_conversation)
		add_child(timer)
		timer.start(3)
		
	func end_conversation():
		var npc_a_dir:Vector2 = (npc_a.target_pos - npc_a.position).normalized()
		npc_b.target_pos = (-1)*npc_a_dir * (npc_b.target_pos-npc_b.position).length()
		npc_a.randomize_timer.start(3)
		npc_b.randomize_timer.start(3)
		
		npc_a.conversation_partner = null
		npc_b.conversation_partner = null
		print_rich("[b]%s[/b] and [b]%s[/b] ended their conversation..." % [npc_a.character.name,npc_b.character.name])
		queue_free()
		
	func _exit_tree() -> void:
		container.queue_free()
		
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PAUSED:
			timer.paused = true
		elif what == NOTIFICATION_UNPAUSED:
			timer.paused = false
			
