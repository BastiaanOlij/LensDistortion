extends Spatial

# The settings below are for iPhone 7, our lcd_width is determined by your phone but for most phone HMDs you can use this info:
# https://support.google.com/cardboard/manufacturers/answer/6321873?hl=en
# Should really build a list of common devices, details for Rift, Gear VR and Vive are readily available 

# how far are our eyes apart (in CMs)?
export var eyes_distance = 6.5

# how wide is our LCD screen (in CMs)?
export var lcd_width = 10.5

# how far is our LCD from our face (in CMs)?
export var lcd_dist = 8.0

# distortion constants, these are for DK1/DK2 rift
export var k1 = 0.3358
export var k2 = 0.5534

# near and far plane
export var near = 0.1
export var far = 200.0

# upscale our FOV, we should be able to calculate this from our k1 and k2 constants 
export var upscale = 1.0

# world scale, 1.0 means 1 unit is 1 cm, 100.0 means 1 unit is 1 meter
export var worldscale = 100.0

# on mobile we use a 565 texture unstead of 888
var use_565 = false

# some handy links
var left_cam_pos = null
var left_viewport = null
var left_eye = null
var left_lens_map = null
var left_gen_lens = null
var left_sprite = null

var right_cam_pos = null
var right_viewport = null
var right_eye = null
var right_lens_map = null
var right_gen_lens = null
var right_sprite = null

var screen_divider = null

func get_eye_distance():
	return eyes_distance
		
func get_right_viewport_offset():
	return right_sprite.get_offset().x
	
func update_cams():
	# note, aspect ratio of our screen is applied later, this is an approximation not adjusting for lens distortion
	var left = -((lcd_width - eyes_distance) / 2.0) / lcd_dist
	var right = (eyes_distance / 2.0) / lcd_dist
	var top = (lcd_width / 4.0) / lcd_dist
	
	# upscale our FOV
	top *= upscale
	var add_width = ((right - left) * (upscale - 1.0)) / 2.0
	left -= add_width
	right += add_width
	
	# setup our projection	
	left_eye.set_frustum(left, right, top, -top, near, far)
	right_eye.set_frustum(-right, -left, top, -top, near, far)

	# set our offset
	left_cam_pos.set_translation(Vector3(-eyes_distance / (2.0 * worldscale), 0.0, 0.0))
	right_cam_pos.set_translation(Vector3(eyes_distance / (2.0 * worldscale), 0.0, 0.0))
	
	# update our lens distortion
	left_gen_lens.get_material().set_shader_param("screen_width_cm", lcd_width)
	left_gen_lens.get_material().set_shader_param("ipd", eyes_distance)
	left_gen_lens.get_material().set_shader_param("k1", k1)
	left_gen_lens.get_material().set_shader_param("k2", k2)
	left_gen_lens.get_material().set_shader_param("use_565", use_565)
	left_lens_map.set_render_target_update_mode(Viewport.RENDER_TARGET_UPDATE_ONCE)

	right_gen_lens.get_material().set_shader_param("screen_width_cm", lcd_width)
	right_gen_lens.get_material().set_shader_param("ipd", eyes_distance)
	right_gen_lens.get_material().set_shader_param("k1", k1)
	right_gen_lens.get_material().set_shader_param("k2", k2)
	right_gen_lens.get_material().set_shader_param("use_565", use_565)
	right_lens_map.set_render_target_update_mode(Viewport.RENDER_TARGET_UPDATE_ONCE)	
	
func set_camera(p_eye_distance, p_lcd_width, p_lcd_dist, p_k1, p_k2):
	if ((eyes_distance == p_eye_distance) && (lcd_width == p_lcd_width) && (lcd_dist == p_lcd_dist)):
		return
		
	eyes_distance = p_eye_distance
	lcd_width = p_lcd_width
	lcd_dist = p_lcd_dist
	k1 = p_k1
	k2 = p_k2

	update_cams()

func resize():
	# Called when the main window resizes, resizes our viewports accordingly
	var screen_size = OS.get_window_size()
	var target_size = Vector2(screen_size.x/2,screen_size.y)
	var aspect = target_size.x / target_size.y
	
	# set our lensmap size
	left_gen_lens.get_material().set_shader_param("target_size", target_size)
	left_gen_lens.set_scale(target_size)
	left_lens_map.set_rect(Rect2(Vector2(0,0),target_size))
	left_lens_map.set_render_target_update_mode(Viewport.RENDER_TARGET_UPDATE_ONCE)
	var lens_texture = left_lens_map.get_render_target_texture()
	left_sprite.get_material().set_shader_param("target_size", target_size)
	left_sprite.get_material().set_shader_param("offsetmap", lens_texture)
	left_sprite.get_material().set_shader_param("upscale", upscale)
	left_sprite.get_material().set_shader_param("use_565", use_565)

	right_gen_lens.get_material().set_shader_param("target_size", target_size)
	right_gen_lens.set_scale(target_size)
	right_lens_map.set_rect(Rect2(Vector2(0,0),target_size))
	right_lens_map.set_render_target_update_mode(Viewport.RENDER_TARGET_UPDATE_ONCE)
	lens_texture = right_lens_map.get_render_target_texture()
	right_sprite.set_pos(Vector2(target_size.x,0))
	right_sprite.get_material().set_shader_param("target_size", target_size)
	right_sprite.get_material().set_shader_param("offsetmap", lens_texture)
	right_sprite.get_material().set_shader_param("upscale", upscale)
	right_sprite.get_material().set_shader_param("use_565", use_565)
	
	# set our render buffer sizes
	# note, we should upscale this using upscale however there is a bug in Godot 2.x
	# that prevents us from doing so:
	# https://github.com/godotengine/godot/issues/8383
	# In Godot 3.x we can change this
	left_viewport.set_rect(Rect2(Vector2(0,0),target_size)) # target_size * upscale
	right_viewport.set_rect(Rect2(Vector2(0,0),target_size)) # target_size * upscale
	
	# and set our viewport scale
	left_sprite.set_scale(Vector2(1.0, 1.0))
	right_sprite.set_scale(Vector2(1.0, 1.0))
	
	# finally set our screen divider
	screen_divider.set_pos(Vector2(target_size.x, 0.0))
	screen_divider.set_scale(Vector2(1.0,target_size.y))

func _ready():
	# get our eyes for easy access
	left_cam_pos = get_node("left_camera_pos")
	left_viewport = get_node("Viewport_left")
	left_eye = get_node("Viewport_left/Camera_left")
	left_lens_map = get_node("Viewport_left_lensmap")
	left_gen_lens = get_node("Viewport_left_lensmap/Generate_left_lens")
	left_sprite = get_node("ViewportSprite_left")

	right_cam_pos = get_node("right_camera_pos")
	right_viewport = get_node("Viewport_right")
	right_eye = get_node("Viewport_right/Camera_right")
	right_lens_map = get_node("Viewport_right_lensmap")
	right_gen_lens = get_node("Viewport_right_lensmap/Generate_right_lens")
	right_sprite = get_node("ViewportSprite_right")
	
	screen_divider = get_node("ScreenDivider")
	
	# check OS
	if (OS.get_name() == 'Android'):
		use_565 = true
	elif (OS.get_name() == 'iOS'):
		use_565 = true
	else:
		use_565 = false

	# update our buffer sizes
	resize()
	
	# make sure our cameras are setup properly
	update_cams()

	# Make sure we learn about resizing the window, this should be fixed but when testing
	# it is fairly handy
	var root = get_node("/root")
	root.connect("size_changed",self,"resize")

	# make sure we get process updates
	set_process(true)

func _process(delta):
	left_eye.set_global_transform(left_cam_pos.get_global_transform())
	right_eye.set_global_transform(right_cam_pos.get_global_transform())