class_name World
extends Resource

signal proposition_added(id:StringName)
signal proposition_removed(id:StringName)

@export var propositions: Dictionary[StringName,PW.TriBool]
@export var confidence: Dictionary[StringName, float]

func set_truth(id:String, truth:PW.TriBool,confidence_score:float = 1.0) -> bool:
	assert(truth is PW.TriBool)
	id = id.to_snake_case()
	# Keep original in case set fails
	if propositions.has(id):
		propositions.set(id,truth)
		if truth != PW.TriBool.UNKNOWN:
			confidence.set(id,clampf(confidence_score,0.1,1.0))
		else:
			confidence.set(id,0)
		emit_changed()
		return true
	else:
		propositions.set(id,truth)
		if truth != PW.TriBool.UNKNOWN:
			confidence.set(id,clampf(confidence_score,0.1,1.0))
		else:
			confidence.set(id,0)
		proposition_added.emit(id)
		emit_changed()
		return true

func get_truth(id:String) -> PW.TriBool:
	return propositions.get(id,PW.TriBool.UNKNOWN)

func set_confidence(id:String,conf:float) -> bool:
	id = id.to_snake_case()
	if not propositions.has(id):
		return false
	confidence.set(id,conf)
	if conf < 0.1:
		propositions.set(id,PW.TriBool.UNKNOWN)
	emit_changed()
	return true

func get_confidence(id:String) -> float:
	return confidence.get(id)

func erase_truth(id:String) -> bool:
	var prop_result := propositions.erase(id)
	var conf_result := confidence.erase(id)
	proposition_removed.emit(id)
	emit_changed()
	return prop_result and conf_result

func has_proposition(id:String) -> bool:
	return propositions.has(id)

func match_world(other:World) -> void:
	propositions.clear()
	confidence.clear()
	propositions.assign(other.propositions)
	confidence.assign(other.confidence)
	emit_changed()

func tension(id:StringName, other:World) -> float:
	var thisTension: float = get_truth(id)*get_confidence(id)
	var otherTension: float = other.get_truth(id)*other.get_confidence(id)
	return absf(thisTension-otherTension)
	
func total_tension(other:World) -> float:
	var tension_result:float = 0
	var intersectingKeys := propositions.keys().filter(func(k):
		return other.propositions.has(k)
	)
	for key in intersectingKeys:
		tension_result += tension(key,other)
	return tension_result

func diff(other:World) -> Array[StringName]:
	var _diff :Array[StringName]
	var intersectingKeys := propositions.keys().filter(func(k):
		return other.propositions.has(k)
	)
	for key in intersectingKeys:
		var thisTruth:PW.TriBool = get_truth(key)
		var otherTruth:PW.TriBool = other.get_truth(key)
		if thisTruth != otherTruth:
			if thisTruth == PW.TriBool.UNKNOWN or otherTruth == PW.TriBool.UNKNOWN:
				continue
			else:
				_diff.append(key)
	return _diff
