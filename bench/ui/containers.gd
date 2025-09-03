extends RefCounted
class_name UiContainer

static func create_vbox_container(name:String) -> VBoxContainer:
    var container := VBoxContainer.new()
    container.name = name
    return container

static func create_item_list(name:String) ->ItemList:
    var container := ItemList.new()
    container.name = name
    return container