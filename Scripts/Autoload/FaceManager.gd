extends Node

signal face_assigned(entity_type: String, texture_path: String)
signal face_removed(entity_type: String)
signal all_faces_deleted

const FACE_SAVE_PATH = "user://face_assignments.cfg"
const FACE_DIR = "user://faces/"

enum EntityType {
	HERO,
	ENEMY_1,
	ENEMY_2,
	BOSS,
	NPC,
	COLLECTIBLE
}

var entity_names: Dictionary = {
	EntityType.HERO: "hero",
	EntityType.ENEMY_1: "enemy_1",
	EntityType.ENEMY_2: "enemy_2",
	EntityType.BOSS: "boss",
	EntityType.NPC: "npc",
	EntityType.COLLECTIBLE: "collectible"
}

var face_assignments: Dictionary = {}
var face_textures: Dictionary = {}
var _android_plugin = null

func _ready():
	_ensure_face_directory()
	_load_assignments()
	_try_init_android_plugin()

func _try_init_android_plugin():
	if Engine.has_singleton("FaceRunPlugin"):
		_android_plugin = Engine.get_singleton("FaceRunPlugin")
		if _android_plugin:
			_android_plugin.connect("image_picked", _on_image_picked)
			_android_plugin.connect("faces_detected", _on_faces_detected)
			_android_plugin.connect("face_cropped", _on_face_cropped)
			print("FaceRunPlugin initialized successfully")
	else:
		print("FaceRunPlugin not available - running in editor or desktop mode")

func _ensure_face_directory():
	if not DirAccess.dir_exists_absolute(FACE_DIR):
		DirAccess.make_dir_recursive_absolute(FACE_DIR)

func _load_assignments():
	var config = ConfigFile.new()
	var err = config.load(FACE_SAVE_PATH)
	if err == OK:
		for entity_type in EntityType.values():
			var name = entity_names[entity_type]
			var path = config.get_value("faces", name, "")
			if path != "" and FileAccess.file_exists(path):
				face_assignments[entity_type] = path

func _save_assignments():
	var config = ConfigFile.new()
	for entity_type in face_assignments:
		var name = entity_names[entity_type]
		config.set_value("faces", name, face_assignments[entity_type])
	config.save(FACE_SAVE_PATH)

func assign_face(entity_type: int, texture_path: String):
	face_assignments[entity_type] = texture_path
	if entity_type in face_textures:
		face_textures.erase(entity_type)
	_save_assignments()
	emit_signal("face_assigned", entity_names[entity_type], texture_path)

func remove_face(entity_type: int):
	if entity_type in face_assignments:
		var path = face_assignments[entity_type]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
		face_assignments.erase(entity_type)
		if entity_type in face_textures:
			face_textures.erase(entity_type)
		_save_assignments()
		emit_signal("face_removed", entity_names[entity_type])

func get_face_texture(entity_type: int) -> Texture2D:
	if entity_type in face_textures:
		return face_textures[entity_type]
	if entity_type in face_assignments:
		var path = face_assignments[entity_type]
		if FileAccess.file_exists(path):
			var image = Image.load_from_file(path)
			if image:
				var texture = ImageTexture.create_from_image(image)
				face_textures[entity_type] = texture
				return texture
	return null

func has_face(entity_type: int) -> bool:
	return entity_type in face_assignments

func delete_all_faces():
	for entity_type in face_assignments.keys():
		var path = face_assignments[entity_type]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	face_assignments.clear()
	face_textures.clear()
	_save_assignments()
	emit_signal("all_faces_deleted")

func get_face_path_for_entity(entity_type: int) -> String:
	return face_assignments.get(entity_type, "")

func save_face_image(image: Image, entity_type: int) -> String:
	_ensure_face_directory()
	var filename = entity_names[entity_type] + "_face.png"
	var path = FACE_DIR + filename
	image.save_png(path)
	return path

# Android plugin bridge methods
func pick_image_from_gallery():
	if _android_plugin:
		_android_plugin.pickImageFromGallery()
	else:
		print("Gallery picker not available on this platform")

func detect_faces_from_path(image_path: String):
	if _android_plugin:
		_android_plugin.detectFacesFromImage(image_path)
	else:
		print("Face detection not available on this platform")

func crop_face(image_path: String, left: int, top: int, width: int, height: int):
	if _android_plugin:
		_android_plugin.cropFaceToPng(image_path, left, top, width, height)
	else:
		print("Face crop not available on this platform")

func _on_image_picked(path: String):
	print("Image picked: ", path)

func _on_faces_detected(faces_json: String):
	print("Faces detected: ", faces_json)

func _on_face_cropped(output_path: String):
	print("Face cropped to: ", output_path)

func get_entity_display_name(entity_type: int) -> String:
	match entity_type:
		EntityType.HERO: return "Hero"
		EntityType.ENEMY_1: return "Slime Bot"
		EntityType.ENEMY_2: return "Flying Bug"
		EntityType.BOSS: return "Boss Robot"
		EntityType.NPC: return "NPC"
		EntityType.COLLECTIBLE: return "Collectible"
		_: return "Unknown"
