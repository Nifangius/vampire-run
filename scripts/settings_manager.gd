## settings_manager.gd — AutoLoad синглтон настроек
## Управляет громкостью, разрешением, режимом окна. Сохраняет в user://settings.cfg

extends Node

const SAVE_PATH = "user://settings.cfg"

const RESOLUTIONS = [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

var master_volume  := 1.0
var music_volume   := 1.0
var sfx_volume     := 1.0
var windowed       := false
var resolution_idx := 1

func _ready():
	_setup_audio_buses()
	load_settings()
	apply_settings()

# ============================================================
# АУДИО ШИНЫ
# ============================================================
func _setup_audio_buses():
	if AudioServer.get_bus_index("Music") == -1:
		var idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_index("SFX") == -1:
		var idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")

# ============================================================
# ПРИМЕНЕНИЕ НАСТРОЕК
# ============================================================
func apply_settings():
	var master_db = linear_to_db(max(master_volume, 0.0001))
	var music_db  = linear_to_db(max(music_volume,  0.0001))
	var sfx_db    = linear_to_db(max(sfx_volume,    0.0001))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master_db)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),  music_db)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"),    sfx_db)

	var mode = DisplayServer.WINDOW_MODE_WINDOWED if windowed else DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(mode)
	if windowed:
		DisplayServer.window_set_size(RESOLUTIONS[resolution_idx])

# ============================================================
# СОХРАНЕНИЕ / ЗАГРУЗКА
# ============================================================
func save_settings():
	var cfg = ConfigFile.new()
	cfg.set_value("audio",   "master",         master_volume)
	cfg.set_value("audio",   "music",          music_volume)
	cfg.set_value("audio",   "sfx",            sfx_volume)
	cfg.set_value("display", "windowed",       windowed)
	cfg.set_value("display", "resolution_idx", resolution_idx)
	cfg.save(SAVE_PATH)

func load_settings():
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	master_volume  = cfg.get_value("audio",   "master",         1.0)
	music_volume   = cfg.get_value("audio",   "music",          1.0)
	sfx_volume     = cfg.get_value("audio",   "sfx",            1.0)
	windowed       = cfg.get_value("display", "windowed",       false)
	resolution_idx = cfg.get_value("display", "resolution_idx", 1)
