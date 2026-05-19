extends Node

const SAVE_PATH = "user://save_data.cfg"
const SETTINGS_PATH = "user://settings.cfg"

var save_data: ConfigFile
var settings: ConfigFile

func _ready():
	save_data = ConfigFile.new()
	settings = ConfigFile.new()
	load_save_data()
	load_settings()

func load_save_data():
	var err = save_data.load(SAVE_PATH)
	if err != OK:
		save_data = ConfigFile.new()
		save_data.set_value("progress", "highest_level", 1)
		save_data.set_value("progress", "total_score", 0)
		save_data.set_value("progress", "total_gems", 0)
		save_data.set_value("progress", "total_enemies", 0)
		save_save_data()

func save_save_data():
	save_data.save(SAVE_PATH)

func save_level_progress(level: int):
	var highest = save_data.get_value("progress", "highest_level", 1)
	if level >= highest:
		save_data.set_value("progress", "highest_level", level + 1)
	var total_score = save_data.get_value("progress", "total_score", 0)
	save_data.set_value("progress", "total_score", total_score + GameManager.score)
	var total_gems = save_data.get_value("progress", "total_gems", 0)
	save_data.set_value("progress", "total_gems", total_gems + GameManager.gems_collected)
	var total_enemies = save_data.get_value("progress", "total_enemies", 0)
	save_data.set_value("progress", "total_enemies", total_enemies + GameManager.enemies_defeated)
	save_save_data()

func get_highest_level() -> int:
	return save_data.get_value("progress", "highest_level", 1)

func get_total_score() -> int:
	return save_data.get_value("progress", "total_score", 0)

func reset_progress():
	save_data = ConfigFile.new()
	save_data.set_value("progress", "highest_level", 1)
	save_data.set_value("progress", "total_score", 0)
	save_data.set_value("progress", "total_gems", 0)
	save_data.set_value("progress", "total_enemies", 0)
	save_save_data()

# Settings
func load_settings():
	var err = settings.load(SETTINGS_PATH)
	if err != OK:
		settings = ConfigFile.new()
		settings.set_value("audio", "music_enabled", true)
		settings.set_value("audio", "sfx_enabled", true)
		settings.set_value("audio", "music_volume", 0.8)
		settings.set_value("audio", "sfx_volume", 1.0)
		settings.set_value("gameplay", "show_touch_controls", true)
		settings.set_value("gameplay", "vibration_enabled", true)
		save_settings()

func save_settings():
	settings.save(SETTINGS_PATH)

func get_setting(section: String, key: String, default_value = null):
	return settings.get_value(section, key, default_value)

func set_setting(section: String, key: String, value):
	settings.set_value(section, key, value)
	save_settings()

func is_music_enabled() -> bool:
	return settings.get_value("audio", "music_enabled", true)

func is_sfx_enabled() -> bool:
	return settings.get_value("audio", "sfx_enabled", true)

func get_music_volume() -> float:
	return settings.get_value("audio", "music_volume", 0.8)

func get_sfx_volume() -> float:
	return settings.get_value("audio", "sfx_volume", 1.0)
