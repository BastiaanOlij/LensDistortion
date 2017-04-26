extends Spatial

# The settings below are for iPhone 7, our lcd_width is determined by your phone but for most phone HMDs you can use this info:
# https://support.google.com/cardboard/manufacturers/answer/6321873?hl=en
# Should really build a list of common devices, details for Rift, Gear VR and Vive are readily available 

# how far are our eyes apart (in CMs)?
export var iod = 6.5

# how wide is our LCD screen (in CMs)?
export var lcd_width = 10.5

# how far is our LCD from our lens (in CMs)?
export var lcd_lens = 4.0

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

# some handy links
var left_cam_pos = null
var left_viewport = null
var left_eye = null
var left_sprite = null

var right_cam_pos = null
var right_viewport = null
var right_eye = null
var right_sprite = null

var screen_divider = null

func get_iod():
	return iod
		
func get_right_viewport_offset():
	return right_sprite.get_offset().x
	
func update_cams():
	# note, aspect ratio of our screen is applied later, this is an approximation not adjusting for lens distortion
	var f1 = (iod / 2.0) / (2.0 * lcd_lens)
	var f2 = ((lcd_width - iod) / 2.0) / (2.0 * lcd_lens)
	var f3 = (lcd_width / 4.0) / (2.0 * lcd_lens)
	
	# upscale our FOV
	f3 *= upscale
	var add_width = ((f1 + f2) * (upscale - 1.0)) / 2.0
	f1 += add_width
	f2 += add_width
	
	# temporary workaround, as we're only applying our upscale to our X 
	# our aspect ratio of our viewport changes. Upscale f3 a second time
	# to compensate for that change.
	f3 *= upscale
	
	# setup our projection	
	left_eye.set_frustum(-f2, f1, f3, -f3, near, far)
	right_eye.set_frustum(-f1, f2, f3, -f3, near, far)

	# set our offset
	left_cam_pos.set_translation(Vector3(-iod / (2.0 * worldscale), 0.0, 0.0))
	right_cam_pos.set_translation(Vector3(iod / (2.0 * worldscale), 0.0, 0.0))

	# update our lens distortion
	left_sprite.get_material().set_shader_param("lcd_width", lcd_width)
	left_sprite.get_material().set_shader_param("iod", iod)
	left_sprite.get_material().set_shader_param("k1", k1)
	left_sprite.get_material().set_shader_param("k2", k2)
	left_sprite.get_material().set_shader_param("upscale", upscale)

	right_sprite.get_material().set_shader_param("lcd_width", lcd_width)
	right_sprite.get_material().set_shader_param("iod", iod)
	right_sprite.get_material().set_shader_param("k1", k1)
	right_sprite.get_material().set_shader_param("k2", k2)
	right_sprite.get_material().set_shader_param("upscale", upscale)
	
func set_camera(p_iod, p_lcd_width, p_lcd_lens, p_k1, p_k2, p_upscale):
	if ((iod == p_iod) && (lcd_width == p_lcd_width) && (lcd_lens == p_lcd_lens) && (upscale == p_upscale)):
		return
		
	iod = p_iod
	lcd_width = p_lcd_width
	lcd_lens = p_lcd_lens
	k1 = p_k1
	k2 = p_k2
	upscale = p_upscale

	update_cams()

func resize():
	# Called when the main window resizes, resizes our viewports accordingly
	var screen_size = OS.get_window_size()
	var target_size = Vector2(screen_size.x/2,screen_size.y)
		
	# set our render buffer sizes
	# note, we should upscale this using upscale however there is a bug in Godot 2.x
	# that prevents us from doing so on our vertical axis:
	# https://github.com/godotengine/godot/issues/8383
	# In Godot 3.x we can change this
	left_viewport.set_rect(Rect2(Vector2(0,0),Vector2(target_size.x * upscale, target_size.y))) # target_size * upscale
	right_viewport.set_rect(Rect2(Vector2(0,0),Vector2(target_size.x * upscale, target_size.y))) # target_size * upscale
	
	# and set our viewport scale
	left_sprite.get_material().set_shader_param("aspect_ratio", target_size.x/target_size.y)
	left_sprite.set_scale(Vector2(1.0 / upscale, 1.0)) # Vector2(1.0 / upscale)
	right_sprite.set_pos(Vector2(target_size.x,0))
	right_sprite.get_material().set_shader_param("aspect_ratio", target_size.x/target_size.y)
	right_sprite.set_scale(Vector2(1.0 / upscale, 1.0)) # Vector2(1.0 / upscale)
	
	# finally set our screen divider
	screen_divider.set_pos(Vector2(target_size.x, 0.0))
	screen_divider.set_scale(Vector2(1.0,target_size.y))

func _ready():
	# get our eyes for easy access
	left_cam_pos = get_node("left_camera_pos")
	left_viewport = get_node("Viewport_left")
	left_eye = get_node("Viewport_left/Camera_left")
	left_sprite = get_node("ViewportSprite_left")

	right_cam_pos = get_node("right_camera_pos")
	right_viewport = get_node("Viewport_right")
	right_eye = get_node("Viewport_right/Camera_right")
	right_sprite = get_node("ViewportSprite_right")
	
	screen_divider = get_node("ScreenDivider")
	
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