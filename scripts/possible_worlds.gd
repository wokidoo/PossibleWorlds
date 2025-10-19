class_name PW
extends Object

enum TriBool {FALSE=0,TRUE=1,UNKNOWN=2}
const TriBoolString = ["FALSE","TRUE","UNKNOWN"]

static func findCharacters(ws:WorldState,filter:Callable) -> Array[Character]:
	return ws.characters.filter(filter)
