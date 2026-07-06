extends Node

var player: AudioStreamPlayer
var player2: AudioStreamPlayer
var fade_timer := 0.0
var current_music := ""
var music_volume := -12.0

var music_generators := {
	"ambient": func(): return _generate_ambient(),
	"tense": func(): return _generate_tense(),
	"boss": func(): return _generate_boss(),
	"menu": func(): return _generate_menu(),
}

func _ready():
	player = AudioStreamPlayer.new()
	player.name = "MusicPrimary"
	player.volume_db = music_volume
	player.bus = "Music"
	add_child(player)

	player2 = AudioStreamPlayer.new()
	player2.name = "MusicSecondary"
	player2.volume_db = -80.0
	player2.bus = "Music"
	add_child(player2)

func _process(delta):
	if fade_timer > 0:
		fade_timer -= delta
		var t = clamp(fade_timer, 0.0, 1.0)
		var cross_fade = _get_fade_target()
		if cross_fade != "":
			player.volume_db = linear_to_db(db_to_linear(music_volume) * t)
			player2.volume_db = linear_to_db(db_to_linear(music_volume) * (1.0 - t))
			if fade_timer <= 0:
				player.stream = player2.stream
				player.volume_db = music_volume
				player2.volume_db = -80.0
				player.play()

func play_music(name: String, crossfade := 2.0):
	if name == current_music:
		return
	current_music = name
	var gen = music_generators.get(name)
	if not gen:
		return
	var stream = gen.call()
	player2.stream = stream
	player2.volume_db = -80.0
	player2.play()
	fade_timer = crossfade

func set_volume(vol_db: float):
	music_volume = vol_db
	player.volume_db = vol_db

func _get_fade_target() -> String:
	return current_music

func _generate_ambient() -> AudioStreamWAV:
	var rate := 44100
	var duration := 8.0
	var count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t = float(i) / rate
		var s = 0.0
		# Slow pad layer
		s += sin(2.0 * PI * 65.0 * t + sin(t * 0.3) * 2.0) * 0.08
		s += sin(2.0 * PI * 98.0 * t + sin(t * 0.2) * 1.5) * 0.06
		s += sin(2.0 * PI * 130.0 * t) * 0.04
		# Ambient drone
		s += sin(2.0 * PI * 180.0 * t + sin(t * 0.45) * 3.0) * 0.03
		# Subtle high shimmer
		s += (sin(2.0 * PI * 1200.0 * t) * 0.01 * sin(t * 2.0))
		# Noise for texture
		s += (randf() - 0.5) * 0.015
		var val = int(clamp(s * 32767, -32768, 32767))
		data.encode_s16(i * 2, val)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = count
	return stream

func _generate_tense() -> AudioStreamWAV:
	var rate := 44100
	var duration := 6.0
	var count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t = float(i) / rate
		var s = 0.0
		s += sin(2.0 * PI * 110.0 * t + sin(t * 0.7) * 3.0) * 0.07
		s += sin(2.0 * PI * 220.0 * t * 0.5) * 0.04
		s += (randf() - 0.5) * 0.03
		s += sin(2.0 * PI * 55.0 * t) * 0.06
		s += sin(2.0 * PI * 330.0 * t + sin(t * 1.2) * 2.0) * 0.03
		var pulser = sin(t * 0.25) * 0.5 + 0.5
		s += sin(2.0 * PI * 440.0 * t) * 0.02 * pulser
		var val = int(clamp(s * 32767, -32768, 32767))
		data.encode_s16(i * 2, val)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = count
	return stream

func _generate_boss() -> AudioStreamWAV:
	var rate := 44100
	var duration := 5.0
	var count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t = float(i) / rate
		var s = 0.0
		s += sin(2.0 * PI * 90.0 * t) * 0.1
		s += sin(2.0 * PI * 180.0 * t + sin(t * 1.5) * 4.0) * 0.06
		s += sin(2.0 * PI * 270.0 * t) * 0.04
		s += (randf() - 0.5) * 0.04
		var snare = sin(t * 8.0) * exp(-8.0 * fmod(t, 1.0)) * 0.08
		s += snare
		s += sin(2.0 * PI * 60.0 * t) * 0.1
		var val = int(clamp(s * 32767, -32768, 32767))
		data.encode_s16(i * 2, val)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = count
	return stream

func _generate_menu() -> AudioStreamWAV:
	var rate := 44100
	var duration := 6.0
	var count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t = float(i) / rate
		var s = 0.0
		s += sin(2.0 * PI * 130.0 * t + sin(t * 0.4) * 2.0) * 0.07
		s += sin(2.0 * PI * 196.0 * t + sin(t * 0.35) * 1.5) * 0.05
		s += sin(2.0 * PI * 260.0 * t) * 0.03
		s += sin(2.0 * PI * 520.0 * t + sin(t * 0.6) * 3.0) * 0.02
		s += sin(2.0 * PI * 1600.0 * t) * 0.01 * sin(t * 1.5)
		s += (randf() - 0.5) * 0.01
		var val = int(clamp(s * 32767, -32768, 32767))
		data.encode_s16(i * 2, val)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = count
	return stream