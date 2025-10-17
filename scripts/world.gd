@tool
class_name World
extends Resource

enum TriBool {FALSE=0,TRUE=1 ,UNKNOWN=2}
enum MatchMode {IGNORE_UNKOWNS, MATCH_UNKOWNS, DIFF_UNKOWNS}

@export var propositions: Dictionary[StringName,TriBool];

func setTruth(id:String, truth:TriBool) -> bool:
	return propositions.set(id,truth)

func getTruth(id:String) -> TriBool:
	return propositions.get(id,TriBool.UNKNOWN)

func eraseTruth(id:String) -> bool:
	return propositions.erase(id)

func hasProposition(id:String) -> bool:
	return propositions.has(id)

func matchWorld(other:World) -> void:
	propositions.clear()
	propositions.assign(other.propositions)

func diff(other:World, matchMode:MatchMode = MatchMode.IGNORE_UNKOWNS) -> Array[StringName]:
	var _diff :Array[StringName]
	var intersectingKeys := propositions.keys().filter(func(k):
		return other.propositions.has(k)
	)
	match matchMode:
		MatchMode.IGNORE_UNKOWNS:
			for key in intersectingKeys:
				var thisTruth:TriBool = getTruth(key)
				var otherTruth:TriBool = other.getTruth(key)
				if thisTruth != otherTruth:
					if thisTruth == TriBool.UNKNOWN or otherTruth == TriBool.UNKNOWN:
						continue
					else:
						_diff.append(key)
		MatchMode.MATCH_UNKOWNS:
			for key in intersectingKeys:
				var thisTruth:TriBool = getTruth(key)
				var otherTruth:TriBool = other.getTruth(key)
				if thisTruth != otherTruth:
					if thisTruth == TriBool.UNKNOWN or otherTruth == TriBool.UNKNOWN:
						continue
					else:
						_diff.append(key)
		MatchMode.DIFF_UNKOWNS:
			for key in intersectingKeys:
				var thisTruth:TriBool = getTruth(key)
				var otherTruth:TriBool = other.getTruth(key)
				if thisTruth != otherTruth:
					_diff.append(key)
	return _diff

func agree(other:World,matchMode:MatchMode = MatchMode.IGNORE_UNKOWNS):
	var _agree :Array[StringName]
	var intersectingKeys := propositions.keys().filter(func(k):
		return other.propositions.has(k)
	)
	match matchMode:
		MatchMode.IGNORE_UNKOWNS:
			for key in intersectingKeys:
				var thisTruth:TriBool = getTruth(key)
				var otherTruth:TriBool = other.getTruth(key)
				if thisTruth == otherTruth:
					if thisTruth == TriBool.UNKNOWN or otherTruth == TriBool.UNKNOWN:
						continue
					else:
						_agree.append(key)
		MatchMode.MATCH_UNKOWNS:
			for key in intersectingKeys:
				var thisTruth:TriBool = getTruth(key)
				var otherTruth:TriBool = other.getTruth(key)
				if thisTruth == otherTruth:
					_agree.append(key)
				elif thisTruth == TriBool.UNKNOWN or otherTruth == TriBool.UNKNOWN:
					_agree.append(key)
		MatchMode.DIFF_UNKOWNS:
			for key in intersectingKeys:
				var thisTruth:TriBool = getTruth(key)
				var otherTruth:TriBool = other.getTruth(key)
				if thisTruth == otherTruth:
					_agree.append(key)
	return _agree
