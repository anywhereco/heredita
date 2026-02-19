class_name MapData

var image: Image

const PACKAGE_VERSION = 0

func package() -> Dictionary[String, Variant]:
	return {"image": image.get_data(),
			"image_size": image.get_size()}
	
func serialize() -> PackedByteArray:
	var serialized_map: PackedByteArray = var_to_bytes(package())
	serialized_map.insert(0,PACKAGE_VERSION)
	return serialized_map
	
static func deserialize(serialized: PackedByteArray) -> MapData:
	var md := MapData.new()
	var package_version := serialized[0]
	var s_data := serialized.duplicate()
	s_data.remove_at(0)
	if package_version >= 0:
		var map_data: Dictionary[String, Variant] = bytes_to_var(s_data)
		var image_size: Vector2 = map_data["image_size"]
		md.image = Image.create_from_data(image_size.x,image_size.y,false,Image.FORMAT_RGBA8,map_data["image"])
		print(map_data["image"].count(0))
		#md.image.save_png("TEST_MAP_IMG.png")
	return md
