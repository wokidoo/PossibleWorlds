@tool
class_name Character
extends Resource

@export var name: String
@export var perceivedWorld: World
@export var idealWorld: World

func idealPerceivedDiff(matchMode:World.MatchMode = World.MatchMode.IGNORE_UNKOWNS) -> Array[StringName]:
	return perceivedWorld.diff(idealWorld,matchMode)

func idealDiff(other:Character,matchMode:World.MatchMode = World.MatchMode.IGNORE_UNKOWNS) -> Array[StringName]:
	return idealWorld.diff(other.idealWorld,matchMode)

func perceivedDiff(other:Character,matchMode:World.MatchMode = World.MatchMode.IGNORE_UNKOWNS) -> Array[StringName]:
	return perceivedWorld.diff(other.perceivedWorld,matchMode)

func setIdeal(id:String,truth:World.TriBool) ->bool:
	return idealWorld.setTruth(id,truth)

func setPerceived(id:String,truth:World.TriBool) ->bool:
	return perceivedWorld.setTruth(id,truth)

func getIdeal(id:String) ->World.TriBool:
	return idealWorld.getTruth(id)

func getPerceived(id:String) -> World.TriBool:
	return perceivedWorld.getTruth(id)
