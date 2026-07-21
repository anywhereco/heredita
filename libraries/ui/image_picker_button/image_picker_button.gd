class_name ImagePickerButton
extends Button

const _CONTAINER = preload("uid://b1070265sjc22")
const DEFAULT_IMAGE = preload("uid://dtur4inp5a2k4")

var error_tween: Tween

var NO_SVG_NO_MAP_FILTER := PackedStringArray(
	["*.png,*.jpg,*.jpeg,*.webp,*.bmp;Image Files;image/png,image/jpeg,image/webp,image/bmp"]
)
var SVG_NO_MAP_FILTER := PackedStringArray(
	[
		"*.png,*.jpg,*.jpeg,*.svg,*.webp,*.bmp;Image Files;image/png,image/jpeg,image/svg+xml,image/webp,image/bmp"
	]
)
var NO_SVG_MAP_FILTER := PackedStringArray(
	[
		"*.png,*.jpg,*.jpeg,*.webp,*.bmp,*.map;Image and Map Files;image/png,image/jpeg,image/webp,image/bmp,application/heredita-map"
	]
)
var SVG_MAP_FILTER := PackedStringArray(
	[
		"*.png,*.jpg,*.jpeg,*.svg,*.webp,*.bmp,*.map;Image and Map Files;image/png,image/jpeg,image/svg+xml,image/webp,image/bmp,application/heredita-map"
	]
)

var image := ReactiveImage.new(null)

## Potential extra data along with the image.
var extra_data: Variant = null

@onready var content: MarginContainer = _CONTAINER.instantiate()
@onready var web_file_dialog := HTML5FileDialog.new()
@onready var file_dialog: FileDialog = FileDialog.new()
@onready var error: Label = content.find_child("Error")

## If SVGs should be allowed or not.
@export var allow_svgs := false
## If maps [.map] should be allowed or not.
@export var allow_maps := false
## If a preview image should be shown. Does nothing if a custom image rect is set.
@export var show_preview := true
## The texture rect to draw previews to.
@export var image_rect: TextureRect
## If the label should be frozen.
@export var freeze_label := true
## If the label should be overwritten if the image is changed elsewhere. Respects [code]freeze_label[/code].
@export var override_label := false
## The label to draw to.
@export var name_label: Label
## The format of the label. %s is the filename.
@export var name_format: String = "%s"
## The amount of pixels to cap an image to, or -1 to not cap it.
@export var max_pixel_count: int = -1

var is_web := OS.has_feature("web")

var prev_content_size: Vector2

enum PickedImageError { OK, UNKNOWN, SVG_NOT_ACCEPTED, MAP_NOT_ACCEPTED, NOT_VALID_FILE_FORMAT, IMAGE_TOO_LARGE }


#region Private methods
func _map_set(map: ReactiveImage) -> void:
	if not freeze_label and override_label:
		name_label.text = tr(name_format) % map.value.resource_name
	image_rect.texture = ImageTexture.create_from_image(map.value)


func _new_image(fname: String) -> void:
	if not content.visible:
		content.show()
	image_rect.texture = ImageTexture.create_from_image(image.value)
	if not freeze_label:
		name_label.text = tr(name_format) % fname


func _ready() -> void:
	if image_rect == null:
		if not show_preview:
			image_rect = content.find_child("Image")
	else:
		content.find_child("Image").hide()

	if name_label == null:
		name_label = content.find_child("Filename")

	image.value_changed.connect(_map_set)
	add_child(content)
	prev_content_size = content.size

	web_file_dialog.file_mode = HTML5FileDialog.FileMode.OPEN_FILE
	web_file_dialog.filters = PackedStringArray(["image/*"])
	web_file_dialog.file_selected.connect(_on_file_selected_html5)
	add_child(web_file_dialog, false, INTERNAL_MODE_BACK)

	file_dialog.use_native_dialog = true
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_selected.connect(_on_file_selected)
	add_child(file_dialog, false, INTERNAL_MODE_BACK)

	content.show()
	content.find_child("Filename").text = text
	text = ""

	if not show_preview:
		image_rect.hide()


func _process(_delta: float) -> void:
	if not content:
		return
	_state_drawer()
	if content.size == prev_content_size:
		return
	prev_content_size = content.size
	custom_minimum_size = prev_content_size


func _pressed() -> void:
	if is_web:
		web_file_dialog.show()
	else:
		if allow_svgs:
			if allow_maps:
				file_dialog.filters = SVG_MAP_FILTER
			else:
				file_dialog.filters = SVG_NO_MAP_FILTER
		else:
			if allow_maps:
				file_dialog.filters = NO_SVG_MAP_FILTER
			else:
				file_dialog.filters = NO_SVG_NO_MAP_FILTER
		file_dialog.popup_centered(file_dialog.min_size)


func _get_friendly_pixel_size() -> String:
	if max_pixel_count == -1:
		return "unlimited"
	var logv := log(max_pixel_count) / log(2)
	var logv_int := roundi(logv)
	var powerness := absf(fmod(logv, 1.0) - 0.5) # 0.5 = very near to power of 2, 0 = very far from power of 2
	if powerness > 0.499:
		@warning_ignore("integer_division")
		var width := int(pow(2, logv_int / 2))
		var height := width
		if logv_int % 2 == 1:
			width *= 2
		return "an %dx%d image" % [width, height]
	return "%d pixels" % max_pixel_count


func _err(code: PickedImageError) -> void:
	if code == 0:
		return
	var msg := "File not accepted."
	match code:
		PickedImageError.SVG_NOT_ACCEPTED:
			msg = "SVGs aren't allowed here."
		PickedImageError.MAP_NOT_ACCEPTED:
			msg = "Maps aren't allowed here."
		PickedImageError.NOT_VALID_FILE_FORMAT:
			msg = "Invalid file format."
		PickedImageError.IMAGE_TOO_LARGE:
			msg = "This image is too large! The maximum size is %s." % _get_friendly_pixel_size()
	error.text = msg
	if error_tween:
		error_tween.kill()
	error_tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_QUART).set_ease(
		Tween.EASE_IN
	)
	error.show()
	error.modulate = Color(1, 1, 1, 1)
	error_tween.tween_property(error, "modulate", Color(1, 1, 1, 0), 1)
	error_tween.tween_callback(error.hide)


func _on_file_selected_html5(file: HTML5FileHandle) -> void:
	var res := await _file_handle_to_image(file)
	if res.is_err():
		_err(res.err_code() as int)
		return
	image.value = res.val()
	_new_image(file.name)

func _on_file_selected(path: String) -> void:
	if path.rsplit(".", false, 1)[1] == "svg":
		_err(PickedImageError.SVG_NOT_ACCEPTED)
		return
	var img: Image = Image.load_from_file(path)
	img.convert(Image.FORMAT_RGBA8)
	if img == null:
		_err(PickedImageError.NOT_VALID_FILE_FORMAT)
		return
	image.value = img
	_new_image(path.get_file())


## also converts to rgba8
func _file_handle_to_image(file: HTML5FileHandle) -> Result:
	var fmt := file.name.rsplit(".", false, 1)[1]
	var buf := await file.as_buffer()
	var buf_stream := StreamPeerBuffer.new()
	buf_stream.data_array = buf
	var res := Vector2i.ZERO
	var _image := Image.new()
	
	if fmt in ["png", "bmp", "jpg", "jpeg", "webp"]:
		res = ImageHeaderReader.get_reader(fmt).read_resolution(buf_stream)
		if res.x * res.y > max_pixel_count and max_pixel_count != -1:
			return Result.err(PickedImageError.IMAGE_TOO_LARGE)
	
	match fmt:
		"png":
			_image.load_png_from_buffer(buf)
		"bmp":
			_image.load_bmp_from_buffer(buf)
		"jpg", "jpeg":
			_image.load_jpg_from_buffer(buf)
		"webp":
			_image.load_webp_from_buffer(buf)
		"svg":
			if allow_svgs:
				_image.load_svg_from_buffer(buf)
			else:
				return Result.err(PickedImageError.SVG_NOT_ACCEPTED)
		"map":
			if allow_maps: #only get the image from the map here
				var result := MapData.read_from_buffer(buf)
				if result.is_ok():
					_image = result.val().image
			else:
				return Result.err(PickedImageError.MAP_NOT_ACCEPTED)
	if _image.is_empty():
		return Result.err(PickedImageError.NOT_VALID_FILE_FORMAT)
	_image.convert(Image.FORMAT_RGBA8)
	return Result.ok(_image)


func _state_drawer() -> void:
	var state := get_draw_mode()
	var modulus := Color(1, 1, 1, 1)
	match state:
		DrawMode.DRAW_NORMAL:
			modulus = get_theme_color("font_color")
		DrawMode.DRAW_PRESSED:
			modulus = get_theme_color("font_pressed_color")
		DrawMode.DRAW_HOVER:
			modulus = get_theme_color("font_hover_color")
		DrawMode.DRAW_DISABLED:
			modulus = get_theme_color("font_disabled_color")
		DrawMode.DRAW_HOVER_PRESSED:
			modulus = get_theme_color("font_hover_pressed_color")
		_:
			assert(
				false,
				"all draw modes should have been accounted for, but drawmode %d was not!" % state
			)
	content.modulate = modulus


#endregion
#region Public methods


func reset() -> void:
	extra_data = null
	image.value = null
	image_rect.texture = DEFAULT_IMAGE

#endregion
