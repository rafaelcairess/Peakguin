extends AudioStreamPlayer

const NORMAL_VOLUME_DB: float = 0.0
const SILENT_VOLUME_DB: float = -60.0

var fade_tween: Tween


func _ready() -> void:
	bus = &"Music"
	volume_db = NORMAL_VOLUME_DB


func play_music(new_music: AudioStream, fade_duration: float = 1.0) -> void:
	if new_music == null:
		return

	if stream == new_music and playing:
		return

	cancel_fade()
	fade_duration = maxf(fade_duration, 0.0)

	if fade_duration == 0.0:
		start_music(new_music)
		volume_db = NORMAL_VOLUME_DB
		return

	if not playing or stream == null:
		stream = new_music
		volume_db = SILENT_VOLUME_DB
		play()

		fade_tween = create_tween()
		fade_tween.tween_property(
			self,
			"volume_db",
			NORMAL_VOLUME_DB,
			fade_duration
		)
		return

	var half_duration := fade_duration * 0.5
	fade_tween = create_tween()
	fade_tween.tween_property(
		self,
		"volume_db",
		SILENT_VOLUME_DB,
		half_duration
	)
	fade_tween.tween_callback(start_music.bind(new_music))
	fade_tween.tween_property(
		self,
		"volume_db",
		NORMAL_VOLUME_DB,
		half_duration
	)


func stop_music(fade_duration: float = 0.5) -> void:
	cancel_fade()
	fade_duration = maxf(fade_duration, 0.0)

	if not playing or fade_duration == 0.0:
		finish_stop()
		return

	fade_tween = create_tween()
	fade_tween.tween_property(
		self,
		"volume_db",
		SILENT_VOLUME_DB,
		fade_duration
	)
	fade_tween.tween_callback(finish_stop)


func start_music(new_music: AudioStream) -> void:
	stream = new_music
	play()


func finish_stop() -> void:
	stop()
	stream = null
	volume_db = NORMAL_VOLUME_DB


func cancel_fade() -> void:
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()

	fade_tween = null
