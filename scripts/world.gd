class_name World
extends Resource


@export var propositions: Dictionary[StringName,PW.TriBool];

func setTruth(id:String, truth:PW.TriBool) -> bool:
	id = id.to_snake_case()
	var result := propositions.set(id,truth)
	if result:
		emit_changed()
	return result

func getTruth(id:String) -> PW.TriBool:
	return propositions.get(id,PW.TriBool.UNKNOWN)

func eraseTruth(id:String) -> bool:
	var result := propositions.erase(id)
	if result:
		emit_changed()
	return result

func hasProposition(id:String) -> bool:
	return propositions.has(id)

func matchWorld(other:World) -> void:
	propositions.clear()
	propositions.assign(other.propositions)
	emit_changed()

func diff(other:World) -> Array[StringName]:
	var _diff :Array[StringName]
	var intersectingKeys := propositions.keys().filter(func(k):
		return other.propositions.has(k)
	)
	for key in intersectingKeys:
		var thisTruth:PW.TriBool = getTruth(key)
		var otherTruth:PW.TriBool = other.getTruth(key)
		if thisTruth != otherTruth:
			if thisTruth == PW.TriBool.UNKNOWN or otherTruth == PW.TriBool.UNKNOWN:
				continue
			else:
				_diff.append(key)
	return _diff

func agree(other:World):
	var _agree :Array[StringName]
	var intersectingKeys := propositions.keys().filter(func(k):
		return other.propositions.has(k)
	)
	for key in intersectingKeys:
		var thisTruth:PW.TriBool = getTruth(key)
		var otherTruth:PW.TriBool = other.getTruth(key)
		if thisTruth == otherTruth:
			if thisTruth == PW.TriBool.UNKNOWN or otherTruth == PW.TriBool.UNKNOWN:
				continue
			else:
				_agree.append(key)
	return _agree
