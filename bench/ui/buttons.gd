extends RefCounted
class_name UiButton

static func create_top_bar_button(text:String, method:Callable) ->Button:
    var b:= Button.new()
    b.text = text
    b.focus_mode = Control.FOCUS_NONE
    b.custom_minimum_size = Vector2i(50,40)
    b.button_down.connect(method)
    return b