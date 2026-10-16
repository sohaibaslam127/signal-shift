extends Node
## Sound effects, ambient music and haptics.
## All audio is synthesised at startup from simple waveforms, so the game ships no third-party audio
## and stays small. Respects the sound / music / haptics settings in SaveService.progress.

const SFX_RATE := 22050
const MUSIC_RATE := 11025
const SFX_VOICES := 4

var _sfx: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _music_player: AudioStreamPlayer
var _music_stream: AudioStreamWAV


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in SFX_VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -14.0
	add_child(_music_player)
	_build_sfx()
	SignalBus.settings_changed.connect(_apply_settings)
	_apply_settings.call_deferred()


func play(sound_name: StringName, pitch: float = 1.0) -> void:
	if not SaveService.progress.sound_enabled:
		return
	var stream: AudioStreamWAV = _sfx.get(sound_name)
	if stream == null:
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	player.pitch_scale = pitch
	player.play()


func haptic(duration_ms: int = 18) -> void:
	if SaveService.progress.haptics_enabled and OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms)


func _apply_settings() -> void:
	if SaveService.progress.music_enabled:
		if _music_stream == null:
			_music_stream = _build_music()
		if not _music_player.playing:
			_music_player.stream = _music_stream
			_music_player.play()
	elif _music_player.playing:
		_music_player.stop()


func _exit_tree() -> void:
	_music_player.stop()
	_music_player.stream = null


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_music_player.stream_paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_music_player.stream_paused = false


func _build_sfx() -> void:
	_sfx[&"tap"] = _tone([880.0], 0.05, 0.35)
	_sfx[&"rotate"] = _tone([660.0, 990.0], 0.07, 0.3)
	_sfx[&"locked"] = _tone([180.0], 0.09, 0.35)
	_sfx[&"connect"] = _sweep(520.0, 1040.0, 0.16, 0.3)
	_sfx[&"button"] = _tone([740.0], 0.04, 0.25)
	_sfx[&"undo"] = _sweep(700.0, 440.0, 0.09, 0.28)
	_sfx[&"fail"] = _sweep(330.0, 160.0, 0.35, 0.3)
	_sfx[&"win"] = _arpeggio([523.25, 659.25, 783.99, 1046.5], 0.09, 0.3)


## Short tone with an exponential decay. Multiple frequencies are mixed.
func _tone(freqs: Array, duration: float, volume: float) -> AudioStreamWAV:
	var frames := int(duration * SFX_RATE)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var t := float(i) / SFX_RATE
		var env := exp(-t * 6.0 / duration) * minf(1.0, t * 400.0)
		var sample := 0.0
		for f: float in freqs:
			sample += sin(TAU * f * t)
		sample = sample / freqs.size() * env * volume
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _wav(data, SFX_RATE)


func _sweep(from_hz: float, to_hz: float, duration: float, volume: float) -> AudioStreamWAV:
	var frames := int(duration * SFX_RATE)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var phase := 0.0
	for i in frames:
		var p := float(i) / frames
		var freq := lerpf(from_hz, to_hz, p)
		phase += TAU * freq / SFX_RATE
		var env := sin(PI * p) * (1.0 - p * 0.5)
		data.encode_s16(i * 2, int(clampf(sin(phase) * env * volume, -1.0, 1.0) * 32767.0))
	return _wav(data, SFX_RATE)


func _arpeggio(freqs: Array, note_length: float, volume: float) -> AudioStreamWAV:
	var note_frames := int(note_length * SFX_RATE)
	var tail := int(0.25 * SFX_RATE)
	var frames := note_frames * freqs.size() + tail
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var sample := 0.0
		for n in freqs.size():
			var start := n * note_frames
			if i < start:
				continue
			var local := float(i - start) / SFX_RATE
			sample += sin(TAU * float(freqs[n]) * local) * exp(-local * 7.0) * minf(1.0, local * 300.0)
		data.encode_s16(i * 2, int(clampf(sample * volume * 0.6, -1.0, 1.0) * 32767.0))
	return _wav(data, SFX_RATE)


## Ambient pad: four slow chords, each faded in and out so the loop point is silent and seamless.
func _build_music() -> AudioStreamWAV:
	var chords := [
		[220.0, 261.63, 329.63],
		[174.61, 220.0, 261.63],
		[130.81, 196.0, 261.63],
		[196.0, 246.94, 293.66],
	]
	var segment := 3.0
	var seg_frames := int(segment * MUSIC_RATE)
	var frames := seg_frames * chords.size()
	var data := PackedByteArray()
	data.resize(frames * 2)
	for c in chords.size():
		var chord: Array = chords[c]
		for i in seg_frames:
			var t := float(i) / MUSIC_RATE
			var p := float(i) / seg_frames
			var env := sin(PI * p)
			env *= env
			var sample := 0.0
			for f: float in chord:
				sample += sin(TAU * f * t) + 0.25 * sin(TAU * f * 2.0 * t)
			sample *= env * 0.12
			data.encode_s16((c * seg_frames + i) * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := _wav(data, MUSIC_RATE)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	return stream


func _wav(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream
