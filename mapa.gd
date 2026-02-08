extends Node3D

var window_stream: Window
var viewport_stream: SubViewport
var cam_stream: Camera3D
var stream_ui: Control
@onready var main_cam = get_viewport().get_camera_3d()
@onready var box_nostream = $CSGBox3D

const LAYER_WORLD = 1
const LAYER_NOSTREAM = 2

var last_pos: Vector2i
var last_size: Vector2i
var is_changing: bool = false
var stream_window_minimized: bool = false  # NUEVO

func _ready():
	setup_layers()
	setup_main_window()
	create_stream_window()
	create_stream_ui()
	
	if window_stream:
		last_pos = window_stream.position
		last_size = window_stream.size

func _process(_delta):
	if !window_stream or !cam_stream: return
	
	cam_stream.global_transform = main_cam.global_transform
	
	stream_window_minimized = (window_stream.mode == Window.MODE_MINIMIZED)
	
	var current_pos = window_stream.position
	var current_size = window_stream.size
	
	if not stream_window_minimized:
		if current_pos != last_pos or current_size != last_size:
			is_changing = true
			last_pos = current_pos
			last_size = current_size
		else:
			is_changing = false
	
	if stream_window_minimized:
		show_stream_mode(false)
	elif is_changing:
		show_stream_mode(true)
	else:
		show_stream_mode(false)
		sync_main_window_transform()

func setup_layers():
	box_nostream.layers = LAYER_NOSTREAM
	
	for child in get_children():
		if child is VisualInstance3D and child != box_nostream:
			child.layers = LAYER_WORLD
	
	main_cam.cull_mask = (1 << (LAYER_WORLD - 1)) | (1 << (LAYER_NOSTREAM - 1))

func setup_main_window():
	var main_win = get_window()
	main_win.borderless = true
	main_win.transparent = true
	main_win.transparent_bg = true
	
	get_viewport().transparent_bg = false
	main_win.set_flag(Window.FLAG_EXCLUDE_FROM_CAPTURE, true)

func create_stream_window():
	viewport_stream = SubViewport.new()
	viewport_stream.size = Vector2i(800, 600)
	viewport_stream.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_stream.world_3d = get_viewport().world_3d
	viewport_stream.transparent_bg = false
	
	cam_stream = Camera3D.new()
	cam_stream.cull_mask = (1 << (LAYER_WORLD - 1))
	viewport_stream.add_child(cam_stream)
	add_child(viewport_stream)
	
	window_stream = Window.new()
	window_stream.title = "Juego - Stream View"
	window_stream.size = Vector2i(800, 600)
	window_stream.position = Vector2i(200, 200)
	window_stream.visible = false
	
	window_stream.set_flag(Window.FLAG_EXCLUDE_FROM_CAPTURE, false)
	window_stream.borderless = false
	
	var tex_rect = TextureRect.new()
	tex_rect.texture = viewport_stream.get_texture()
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	window_stream.add_child(tex_rect)
	
	add_child(window_stream)
	window_stream.show()
	
	window_stream.close_requested.connect(func(): get_tree().quit())
	window_stream.size_changed.connect(on_stream_resize)

func create_stream_ui():
	stream_ui = Panel.new()
	stream_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color.BLACK
	stream_ui.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = "AJUSTANDO VENTANA...\n\nHaz click en la ventana transparente\npara continuar jugando."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	stream_ui.add_child(label)
	
	stream_ui.visible = false
	window_stream.add_child(stream_ui)

func show_stream_mode(enable: bool):
	var main_win = get_window()
	
	if enable:
		stream_ui.visible = true
		stream_ui.move_to_front()
		if not stream_window_minimized:
			main_win.mode = Window.MODE_MINIMIZED
	else:
		stream_ui.visible = false
		main_win.mode = Window.MODE_WINDOWED

func sync_main_window_transform():
	var main_win = get_window()
	main_win.position = window_stream.position
	main_win.size = window_stream.size

func on_stream_resize():
	if viewport_stream:
		viewport_stream.size = window_stream.size
