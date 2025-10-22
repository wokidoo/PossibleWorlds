class_name World
extends Resource

@export var propositions: Dictionary[StringName,PW.TriBool]
@export var confidence: Dictionary[StringName, float]

func set_truth(id:String, truth:PW.TriBool,confidence_score:float = 1.0) -> bool:
	assert(truth is PW.TriBool)
	id = id.to_snake_case()
	# Keep original in case set fails
	
	var cached_prop :PW.TriBool
	if propositions.has(id):
		cached_prop = propositions.get(id,null)
	var cached_conf :float
	if confidence.has(id):
		cached_conf = confidence.get(id)
	var prop_result := propositions.set(id,truth)
	var conf_result :int
	if truth == PW.TriBool.UNKNOWN:
		conf_result = confidence.set(id,0)
	else:
		conf_result = confidence.set(id,clampf(confidence_score,0.1,1.0))

	if prop_result and conf_result:
		emit_changed()
		return true
	else: # reset values in case either set function fails
		if cached_prop != null:	
			propositions.set(id,cached_prop)
		if cached_conf != null:
			confidence.set(id,cached_conf)
		return false

func get_truth(id:String) -> PW.TriBool:
	return propositions.get(id,PW.TriBool.UNKNOWN)

func set_confidence(id:String,conf:float) -> bool:
	id = id.to_snake_case()
	if not propositions.has(id):
		return false
	confidence.set(id,conf)
	emit_changed()
	return true

func get_confidence(id:String) -> float:
	return confidence.get(id)

func erase_truth(id:String) -> bool:
	var prop_result := propositions.erase(id)
	var conf_result := confidence.erase(id)
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

func tension(other:World) -> float:
	var tension_result:float = 0
	var intersectingKeys := propositions.keys().filter(func(k):
		return other.propositions.has(k)
	)
	for key in intersectingKeys:
		var thisTension: float = get_truth(key)*get_confidence(key)
		var otherTension: float = other.get_truth(key)*other.get_confidence(key)
		tension_result += absf(thisTension-otherTension)
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
