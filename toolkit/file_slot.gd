extends Button
class_name FileSlot

var window: BaseWindow
var filename: String
@onready var label: Label = $Slot/Label
@onready var rename_field: LineEdit = $Slot/Label/Rename
@onready var button: Button = self
@onready var static_icon: TextureRect = $Slot/Icon
@onready var dynamic_icon: AspectRatioContainer = $Slot/DynamicIcon
@onready var grid: GridContainer = $Slot

var thread: Thread = null

var is_folder:= false
var icon_size:= 64:
	set(val):
		static_icon.custom_minimum_size = Vector2(val, val)
		dynamic_icon.custom_minimum_size = Vector2(val, val)
		icon_size = val
		update_layout.call_deferred()
	get:
		return int(static_icon.custom_minimum_size.x)

func link_window(with: BaseWindow):
	window = with

func set_to(new_name: String, path: String = ""):
	dynamic_icon.hide()
	if path != "":
		static_icon.texture = await Thumbnail.get_icon_for(path, self)
		
		var dynamic: String = Meta.get_folder_meta(path, "DynamicIcon", "ICON", "")
		if dynamic != "":
			window.create_component(dynamic, dynamic_icon, path)
			dynamic_icon.show()
			static_icon.hide()

	else: static_icon.texture = null
	filename = new_name
	if filename == "":
		filename = "<empty>"
	name = filename
	if "<empty>" in name:
		label.text = ""
	else:
		label.text = Meta.folder_title(path)
	
	if Filesystem.is_link(path):
		%LinkIndicator.show()
	update_layout.call_deferred()



func _ready() -> void:
	pressed.connect(_on_button_pressed)
	set_to("")

func update_layout():
	if label.text == "":
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		static_icon.texture = null
		for i in dynamic_icon.get_children():
			i.queue_free()
	else:
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		
	if icon_size < 40:
		grid.columns = 3
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	else:
		grid.columns = 1
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	await System.wait()
	var slot_size: Vector2 = Vector2(icon_size * 2.0 if grid.columns == 1 else 0.0, icon_size + label.size.y*2)
	label.custom_minimum_size.x = slot_size.x
	button.custom_minimum_size = slot_size
	button.custom_minimum_size = slot_size


func _on_button_pressed() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		System.open_context_menu(window.location+filename, self)
	else:
		var result: int
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			result = await window.navigate(window.location+filename, "Window", self)
		else:
			result = await window.navigate(window.location+filename, "Auto", self)
		match result:
			0:
				modulate = Color.WHITE
			1:
				unfade()

func rename() -> String:
	var original: String = label.text
	label.self_modulate.a = 0
	rename_field.text = original
	rename_field.placeholder_text = original
	rename_field.show()
	rename_field.grab_focus()
	
	await rename_field.text_submitted
	
	var new_name := rename_field.text
	if new_name == "":
		new_name = original
	rename_field.hide()
	
	label.text = new_name
	label.self_modulate.a = 1
	Filesystem.rename(get_item_location(), new_name)
	window.send("parse_folder")
	
	return new_name

func get_item_location() -> String:
	return window.location.path_join(filename)

func fade():
	window.set_tweened("modulate:a", 0, self)

func unfade():
	window.set_tweened("modulate:a", 1, self)

func _exit_tree():
	if thread != null and thread.is_started():
		thread.wait_to_finish()
