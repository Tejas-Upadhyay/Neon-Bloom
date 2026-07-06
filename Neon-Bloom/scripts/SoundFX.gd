extends Node

var _audio_player: AudioStreamPlayer
var _streams := {}

func _ready():
	_audio_player = AudioStreamPlayer.new()
	_audio_player.name = "SoundFXPlayer"
	add_child(_audio_player)
	_generate_all()

func _generate_all():
	_streams["shoot"] = _noise_burst(0.06, 0.3, 1200.0, 800.0)
	_streams["hit"] = _noise_burst(0.05, 0.2, 300.0, 100.0)
	_streams["collect"] = _sine_chirp(0.12, 0.25, 400.0, 1200.0)
	_streams["enemy_die"] = _noise_burst(0.15, 0.4, 600.0, 80.0)
	_streams["player_hurt"] = _noise_burst(0.1, 0.35, 200.0, 60.0)
	_streams["wave_start"] = _sine_chirp(0.3, 0.4, 300.0, 900.0)
	_streams["game_over"] = _noise_burst(0.6, 0.5, 400.0, 30.0)
	_streams["dash"] = _noise_burst(0.08, 0.2, 800.0, 400.0)
	_streams["upgrade"] = _sine_chirp(0.2, 0.3, 600.0, 1400.0)

func play(sound_name: String, vol_db: float = -6.0):
	var stream = _streams.get(sound_name)
	if not stream:
		return
	_audio_player.stream = stream
	_audio_player.volume_db = vol_db
	_audio_player.play()

func _noise_burst(duration: float, noise_amt: float, freq_start: float, freq_end: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t = float(i) / rate
		var env = exp(-4.0 * t / duration)
		var freq = lerpf(freq_start, freq_end, t / duration)
		var noise = (randf() - 0.5) * noise_amt
		var s = (sin(2.0 * PI * freq * t) + noise) * env * 0.4
		var val = int(clamp(s * 32767, -32768, 32767))
		data.encode_s16(i * 2, val)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream

func _sine_chirp(duration: float, volume: float, freq_start: float, freq_end: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t = float(i) / rate
		var env = exp(-3.0 * t / duration)
		var freq = lerpf(freq_start, freq_end, t / duration)
		var s = sin(2.0 * PI * freq * t) * env * volume
		var val = int(clamp(s * 32767, -32768, 32767))
		data.encode_s16(i * 2, val)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream
