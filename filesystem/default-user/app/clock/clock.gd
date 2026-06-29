extends Control

func _ready() -> void:
	$Timer.timeout.connect(update)
	update()

func update() -> void:
	var time := Time.get_time_dict_from_system()
	%HourText.text = str(time["hour"])
	%MinuteText.text = str(time["minute"])
	%HourHand.rotation = remap(time["hour"], 0, 24, 0, 2)
	%MinuteHand.rotation = remap(time["minute"], 0, 60, 0, 1)
