extends Node

signal voice_assigned(category: String, audio_path: String)
signal voice_removed(category: String)
signal all_voices_deleted

const VOICE_SAVE_PATH = "user://voice_assignments.cfg"
const VOICE_DIR = "user://voices/"

enum VoiceCategory {
	HERO_JUMP,
	HERO_DAMAGE,
	HERO_DEATH,
	ENEMY_HIT,
	ENEMY_DEATH,
	BOSS_ROAR,
	BOSS_DEATH,
	BACKGROUND_MUSIC,
	LEVEL_COMPLETE,
	GAME_OVER
}

var category_names: Dictionary = {
	VoiceCategory.HERO_JUMP: "hero_jump",
	VoiceCategory.HERO_DAMAGE: "hero_damage",
	VoiceCategory.HERO_DEATH: "hero_death",
	VoiceCategory.ENEMY_HIT: "enemy_hit",
	VoiceCategory.ENEMY_DEATH: "enemy_death",
	VoiceCategory.BOSS_ROAR: "boss_roar",
	VoiceCategory.BOSS_DEATH: "boss_death",
	VoiceCategory.BACKGROUND_MUSIC: "background_music",
	VoiceCategory.LEVEL_COMPLETE: "level_complete",
	VoiceCategory.GAME_OVER: "game_over"
}

var voice_assignments: Dictionary = {}
var _audio_streams: Dictionary = {}
var _android_plugin = null

var _bg_music_player: AudioStreamPlayer = null

func _ready():
	_ensure_voice_directory()
	_load_assignments()
	_try_init_android_plugin()
	_setup_bg_music_player()

func _setup_bg_music_player():
	_bg_music_player = AudioStreamPlayer.new()
	_bg_music_player.bus = "Master"
	_bg_music_player.volume_db = -6.0
	add_child(_bg_music_player)
	_bg_music_player.finished.connect(_on_bg_music_finished)

func _on_bg_music_finished():
	if _bg_music_player.stream:
		_bg_music_player.play()

func _try_init_android_plugin():
	if Engine.has_singleton("FaceRunPlugin"):
		_android_plugin = Engine.get_singleton("FaceRunPlugin")
		if _android_plugin and _android_plugin.has_signal("audio_picked"):
			_android_plugin.connect("audio_picked", _on_audio_picked)

func _ensure_voice_directory():
	if not DirAccess.dir_exists_absolute(VOICE_DIR):
		DirAccess.make_dir_recursive_absolute(VOICE_DIR)

func _load_assignments():
	var config = ConfigFile.new()
	var err = config.load(VOICE_SAVE_PATH)
	if err == OK:
		for cat in VoiceCategory.values():
			var name = category_names[cat]
			var path = config.get_value("voices", name, "")
			if path != "" and FileAccess.file_exists(path):
				voice_assignments[cat] = path

func _save_assignments():
	var config = ConfigFile.new()
	for cat in voice_assignments:
		var name = category_names[cat]
		config.set_value("voices", name, voice_assignments[cat])
	config.save(VOICE_SAVE_PATH)

func assign_voice(category: int, audio_path: String):
	voice_assignments[category] = audio_path
	if category in _audio_streams:
		_audio_streams.erase(category)
	_save_assignments()
	emit_signal("voice_assigned", category_names[category], audio_path)
	if category == VoiceCategory.BACKGROUND_MUSIC:
		_update_bg_music()

func remove_voice(category: int):
	if category in voice_assignments:
		var path = voice_assignments[category]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
		voice_assignments.erase(category)
		if category in _audio_streams:
			_audio_streams.erase(category)
		_save_assignments()
		emit_signal("voice_removed", category_names[category])
		if category == VoiceCategory.BACKGROUND_MUSIC:
			stop_bg_music()

func has_voice(category: int) -> bool:
	return category in voice_assignments

func get_voice_stream(category: int) -> AudioStream:
	if category in _audio_streams:
		return _audio_streams[category]
	if category in voice_assignments:
		var path = voice_assignments[category]
		if FileAccess.file_exists(path):
			var stream = _load_audio_stream(path)
			if stream:
				_audio_streams[category] = stream
				return stream
	return null

func _load_audio_stream(path: String) -> AudioStream:
	if path.ends_with(".wav"):
		return _parse_wav_file(path)
	elif path.ends_with(".mp3"):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var data = file.get_buffer(file.get_length())
			file.close()
			var stream = AudioStreamMP3.new()
			stream.data = data
			return stream
	elif path.ends_with(".ogg"):
		var stream = AudioStreamOggVorbis.load_from_file(path)
		return stream
	return null

func play_voice(category: int, player: AudioStreamPlayer = null):
	var stream = get_voice_stream(category)
	if stream and player:
		player.stream = stream
		player.play()
	elif stream:
		var temp_player = AudioStreamPlayer.new()
		temp_player.stream = stream
		add_child(temp_player)
		temp_player.play()
		temp_player.finished.connect(temp_player.queue_free)

func start_bg_music():
	if not SaveManager.is_music_enabled():
		return
	var stream = get_voice_stream(VoiceCategory.BACKGROUND_MUSIC)
	if stream:
		_bg_music_player.stream = stream
		_bg_music_player.play()

func stop_bg_music():
	if _bg_music_player:
		_bg_music_player.stop()

func _update_bg_music():
	if _bg_music_player and _bg_music_player.playing:
		_bg_music_player.stop()
	start_bg_music()

func delete_all_voices():
	for cat in voice_assignments.keys():
		var path = voice_assignments[cat]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	voice_assignments.clear()
	_audio_streams.clear()
	stop_bg_music()
	_save_assignments()
	emit_signal("all_voices_deleted")

func copy_audio_to_local(source_path: String, category: int) -> String:
	_ensure_voice_directory()
	var ext = source_path.get_extension()
	var filename = category_names[category] + "_voice." + ext
	var dest_path = VOICE_DIR + filename
	if FileAccess.file_exists(source_path):
		var src = FileAccess.open(source_path, FileAccess.READ)
		if src:
			var data = src.get_buffer(src.get_length())
			src.close()
			var dst = FileAccess.open(dest_path, FileAccess.WRITE)
			if dst:
				dst.store_buffer(data)
				dst.close()
				return dest_path
	return ""

func pick_audio_from_gallery():
	if _android_plugin and _android_plugin.has_method("pickAudioFromDevice"):
		_android_plugin.pickAudioFromDevice()
	else:
		print("Audio picker not available on this platform")

func _on_audio_picked(path: String):
	print("Audio picked: ", path)

func get_category_display_name(category: int) -> String:
	match category:
		VoiceCategory.HERO_JUMP: return "Hero Jump"
		VoiceCategory.HERO_DAMAGE: return "Hero Damage"
		VoiceCategory.HERO_DEATH: return "Hero Death"
		VoiceCategory.ENEMY_HIT: return "Enemy Hit"
		VoiceCategory.ENEMY_DEATH: return "Enemy Death"
		VoiceCategory.BOSS_ROAR: return "Boss Roar"
		VoiceCategory.BOSS_DEATH: return "Boss Death"
		VoiceCategory.BACKGROUND_MUSIC: return "Background Music"
		VoiceCategory.LEVEL_COMPLETE: return "Level Complete"
		VoiceCategory.GAME_OVER: return "Game Over"
		_: return "Unknown"

func get_voice_path_for_category(category: int) -> String:
	return voice_assignments.get(category, "")

func _parse_wav_file(path: String) -> AudioStream:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return null
	var file_size = file.get_length()
	if file_size < 44:
		file.close()
		return null

	# Read RIFF header
	var riff = file.get_buffer(4)
	if riff[0] != 0x52 or riff[1] != 0x49 or riff[2] != 0x46 or riff[3] != 0x46:
		file.close()
		return null
	file.get_32() # chunk size
	file.get_buffer(4) # WAVE

	# Parse chunks to find fmt and data
	var num_channels: int = 2
	var sample_rate: int = 44100
	var bits_per_sample: int = 16
	var audio_data: PackedByteArray = PackedByteArray()

	while file.get_position() < file_size - 8:
		var chunk_id = file.get_buffer(4)
		var chunk_size = file.get_32()
		var chunk_id_str = char(chunk_id[0]) + char(chunk_id[1]) + char(chunk_id[2]) + char(chunk_id[3])

		if chunk_id_str == "fmt ":
			var audio_format = file.get_16()
			num_channels = file.get_16()
			sample_rate = file.get_32()
			file.get_32() # byte rate
			file.get_16() # block align
			bits_per_sample = file.get_16()
			var remaining = chunk_size - 16
			if remaining > 0:
				file.get_buffer(remaining)
		elif chunk_id_str == "data":
			audio_data = file.get_buffer(chunk_size)
		else:
			if chunk_size > 0:
				file.get_buffer(chunk_size)

	file.close()

	if audio_data.size() == 0:
		return null

	var stream = AudioStreamWAV.new()
	stream.data = audio_data
	stream.mix_rate = sample_rate
	stream.stereo = num_channels >= 2

	match bits_per_sample:
		8:
			stream.format = AudioStreamWAV.FORMAT_8_BITS
		16:
			stream.format = AudioStreamWAV.FORMAT_16_BITS
		_:
			stream.format = AudioStreamWAV.FORMAT_16_BITS

	return stream
