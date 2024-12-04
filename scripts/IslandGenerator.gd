extends Node2D

@onready var texture_rect = $HUD/NoisePreviewTile/TextureRect
@onready var confirm_elevation_button = $HUD/NoisePreviewTile/ConfirmElevationButton
@onready var confirm_humidity_button = $HUD/NoisePreviewTile/ConfirmHumidityButton


@onready var sprite_2d = $Sprite2D
@onready var camera_2d: Camera2D = $Camera2D
var fixed_toggle_point = Vector2(0,0)


var rng
var current_noise
var current_size: Vector2
var elevation_noise: FastNoiseLite
var humidity_noise: FastNoiseLite

## Noise Settings
@onready var noise_type_option: OptionButton = $HUD/TabContainer/NoiseSettings/NoiseTypeBox/NoiseTypeOption
@onready var x_input = $HUD/TabContainer/NoiseSettings/SizeBox/XInput
@onready var y_input = $HUD/TabContainer/NoiseSettings/SizeBox/YInput
@onready var frequency_spinbox = $HUD/TabContainer/NoiseSettings/FrequencyBox/FrequencySpinbox
@onready var seed_input = $HUD/TabContainer/NoiseSettings/SeedBox/SeedInput
@onready var fractal_type_option: OptionButton = $HUD/TabContainer/NoiseSettings/FractalTypeBox/FractalTypeOption
@onready var fractal_octaves_spin_box = $HUD/TabContainer/NoiseSettings/FractalOctavesBox/FractalOctavesSpinBox
@onready var fractal_lacunarity_spin_box = $HUD/TabContainer/NoiseSettings/FractalLacunarityBox/FractalLacunaritySpinBox
@onready var fractal_gain_spin_box = $HUD/TabContainer/NoiseSettings/FractalGainBox/FractalGainSpinBox
@onready var fws_spin_box = $HUD/TabContainer/NoiseSettings/FractalWeightedStrBox/FWSSpinBox
@onready var fractal_ping_pong_spin_box = $HUD/TabContainer/NoiseSettings/FractalPingPongBox/FractalPingPongSpinBox
@onready var cellular_distance_option = $HUD/TabContainer/NoiseSettings/CellularDistanceBox/CellularDistanceOption
@onready var cellular_return_type_option = $HUD/TabContainer/NoiseSettings/CellularReturnTypeBox/CellularReturnTypeOption
@onready var cellular_jitter_spin_box = $HUD/TabContainer/NoiseSettings/CellularJitterBox/CellularJitterSpinBox

## Biome Settings
@onready var biome_tab = preload("res://scenes/UI/biome_tab.tscn")
@onready var biomes_container = $HUD/TabContainer/Biomes/ScrollContainer/BiomesContainer

func _ready():
	rng = RandomNumberGenerator.new()
	rng.seed = hash(Time.get_date_string_from_system())

func _process(delta):
	if Input.is_action_just_released("scrollup"):
		zoom_camera(1, Vector2(0.1, 0.1))
	if Input.is_action_just_released("scrolldown"):
		zoom_camera(-1, Vector2(0.1, 0.1))
		
	if Input.is_action_pressed("zoomin"):
		zoom_camera(1, Vector2(0.007, 0.007))
	if Input.is_action_pressed("zoomout"):
		zoom_camera(-1, Vector2(0.007, 0.007))
		
	# This happens once 'move_map' is pressed
	if Input.is_action_just_pressed('move_map'):
		var ref = get_viewport().get_mouse_position()
		fixed_toggle_point = ref
	# This happens while 'move_map' is pressed
	if Input.is_action_pressed('move_map'):
		slide_map_around()

func zoom_camera(direction, zoom_amount):
	if direction < 0:
		if camera_2d.zoom - zoom_amount > zoom_amount:
			camera_2d.zoom -= zoom_amount
	else:
		camera_2d.zoom += zoom_amount

func slide_map_around():
	var ref = get_viewport().get_mouse_position()
	camera_2d.global_position.x -= (ref.x - fixed_toggle_point.x) / 80
	camera_2d.global_position.y -= (ref.y - fixed_toggle_point.y) / 80
	
func generate_noise_map(x_size: int = 10,
						y_size: int = 10,
						seed: int = 0,
						noise_type: int = 0,
						offset: Vector3 = Vector3(0,0,0),
						frequency: float = 0.01,
						fractal_weighted_strength: float = 0.0,
						fractal_type: int = 1,
						fractal_ping_pong_strength: float = 2.0,
						fractal_octaves: int = 5,
						fractal_lacunarity: float = 2.0,
						fractal_gain: float = 0.5,
						domain_warp_type: int = 0,
						domain_warp_frequency: float = 0.05,
						domain_warp_fractal_type: int = 1,
						domain_warp_fractal_octaves = 5,
						domain_warp_fractal_lacunarity = 6.0,
						domain_warp_fractal_gain = 0.5,
						domain_warp_enabled: bool = false,
						domain_warp_amplitude: float = 30.0,
						cellular_return_type: int = 1,
						cellular_jitter: float = 1.0,
						cellular_distance_function: int = 0
	):
		
	var fastNoise = FastNoiseLite.new()
	fastNoise.seed = seed
	fastNoise.noise_type = noise_type
	fastNoise.offset = offset
	fastNoise.frequency = frequency
	fastNoise.fractal_weighted_strength = fractal_weighted_strength
	fastNoise.fractal_type = fractal_type
	fastNoise.fractal_ping_pong_strength = fractal_ping_pong_strength
	fastNoise.fractal_octaves = fractal_octaves
	fastNoise.fractal_lacunarity = fractal_lacunarity
	fastNoise.fractal_gain = fractal_gain
	fastNoise.domain_warp_type = domain_warp_type
	fastNoise.domain_warp_frequency = domain_warp_frequency
	fastNoise.domain_warp_fractal_type = domain_warp_fractal_type
	fastNoise.domain_warp_fractal_octaves = domain_warp_fractal_octaves
	fastNoise.domain_warp_fractal_lacunarity = domain_warp_fractal_lacunarity
	fastNoise.domain_warp_fractal_gain = domain_warp_fractal_gain
	fastNoise.domain_warp_enabled = domain_warp_enabled
	fastNoise.domain_warp_amplitude = domain_warp_amplitude
	fastNoise.cellular_return_type = cellular_return_type
	fastNoise.cellular_jitter = cellular_jitter
	fastNoise.cellular_distance_function = cellular_distance_function
	
	return fastNoise

func generate_island():

	var island_map: Image = Image.create(current_size.x, current_size.y, true, Image.FORMAT_RGBF)
	var biomes = get_biomes()
	biomes.sort_custom(sort_by_elevation_range)
			
	for i in current_size.x:
		for j in current_size.y:
			var elevation = elevation_noise.get_noise_2d(i, j)
			var humidity = humidity_noise.get_noise_2d(i, j)
		
			for biome in biomes: # TODO: Make this a binary search
				var elevation_range = biome.get_elevation_range()
				var humidity_range = biome.get_humidity_range()
				if elevation > elevation_range[1]:
					continue
				if elevation > elevation_range[0] and elevation < elevation_range[1]:
					if humidity > humidity_range[0] and humidity < humidity_range[1]:
						island_map.set_pixel(i, j, biome.get_color())
					else:
						continue
					break
				pass
				#island_map.set_pixel(i, j, Color.NAVY_BLUE)

	
	sprite_2d.texture = ImageTexture.create_from_image(island_map)
	
func get_biomes():
	var biome_tabs = []
	for biome_tab in biomes_container.get_children():
		biome_tabs.append(biome_tab)
	return biome_tabs

func sort_by_elevation_range(a, b):
	if a.get_elevation_range()[0] < b.get_elevation_range()[0]:
		return true
	return false
	
func _on_generate_button_pressed():
	var fastNoise = generate_noise_map(int(x_input.text),
						int(y_input.text),
						int(seed_input.text),
						noise_type_option.selected,
						Vector3(0,0,0),
						frequency_spinbox.value,
						fws_spin_box.value,
						fractal_type_option.selected,
						fractal_ping_pong_spin_box.value,
						fractal_octaves_spin_box.value,
						fractal_lacunarity_spin_box.value,
						fractal_gain_spin_box.value
					)
		
	current_noise = fastNoise
	current_size = Vector2(int(x_input.text), int(y_input.text))
	
	var texture: NoiseTexture2D = NoiseTexture2D.new()
	texture.height = int(y_input.text)
	texture.width = int(x_input.text)
	texture.noise = fastNoise
	await texture.changed
	var image = texture.get_image()
	var data = image.get_data()
	
	texture_rect.texture = texture
	texture_rect.scale = Vector2(300.0 / texture.width, 300.0 / texture.height)
	confirm_elevation_button.visible = true
	confirm_humidity_button.visible = true
	texture_rect.visible = true
	

func _on_confirm_elevation_button_pressed():
	elevation_noise = current_noise
	confirm_elevation_button.visible = false
	confirm_humidity_button.visible = false
	texture_rect.visible = false
	
	if elevation_noise and humidity_noise:
		generate_island()


func _on_confirm_humidity_button_pressed():
	humidity_noise = current_noise
	confirm_elevation_button.visible = false
	confirm_humidity_button.visible = false
	texture_rect.visible = false
	if elevation_noise and humidity_noise:
		generate_island()


func _on_add_biome_button_pressed():
	var new_tab = biome_tab.instantiate()
	biomes_container.add_child(new_tab)
	pass # Replace with function body.
