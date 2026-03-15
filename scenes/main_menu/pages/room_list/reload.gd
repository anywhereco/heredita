extends Button

@onready var rooms: RoomHandler = %Rooms


func _pressed() -> void:
	rooms._load_rooms()
