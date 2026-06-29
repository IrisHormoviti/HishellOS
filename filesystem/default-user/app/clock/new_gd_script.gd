extends Control

func _physics_process(_delta: float) -> void:
	var time := Time.get_date_dict_from_system()
	$Hour.rotation = remap(time["hour"], 0, 24, 0, 2)
	$Minute.rotation = remap(time["minute"], 0, 60, 0, 1)
